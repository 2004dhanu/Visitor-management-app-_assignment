<?php

declare(strict_types=1);

if (PHP_SAPI === 'cli-server') {
    $requested = parse_url((string) ($_SERVER['REQUEST_URI'] ?? '/'), PHP_URL_PATH);
    $candidate = realpath(__DIR__ . '/' . ltrim((string) $requested, '/'));
    if ($candidate !== false
        && is_file($candidate)
        && strpos($candidate, realpath(__DIR__) ?: __DIR__) === 0
        && basename($candidate) !== 'config.php') {
        return false;
    }
}

require __DIR__ . '/db.php';
require __DIR__ . '/visitors.php';
require __DIR__ . '/mailer.php';
require __DIR__ . '/pass.php';

function send(int $status, $payload = null): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    if ($payload !== null) {
        echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }
    exit;
}

function fail(int $status, string $message): void
{
    send($status, ['message' => $message]);
}

function send_html(int $status, string $html): void
{
    http_response_code($status);
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-store, max-age=0');
    header('X-Robots-Tag: noindex, nofollow');
    header('Referrer-Policy: no-referrer');
    echo $html;
    exit;
}

function request_path(): string
{
    $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
    $uri = is_string($uri) ? $uri : '/';

    $script = str_replace('\\', '/', (string) ($_SERVER['SCRIPT_NAME'] ?? ''));

    if ($script !== '' && strpos($uri, $script) === 0) {
        $uri = substr($uri, strlen($script));
    } else {
        $base = rtrim(str_replace('\\', '/', dirname($script)), '/');
        if ($base !== '' && $base !== '.' && strpos($uri, $base) === 0) {
            $uri = substr($uri, strlen($base));
        }
    }

    return '/' . trim((string) $uri, '/');
}

function public_base_url(array $config): string
{
    $configured = trim((string) ($config['public_base_url'] ?? ''));
    if ($configured !== '') {
        return rtrim($configured, '/');
    }

    $https = (string) ($_SERVER['HTTPS'] ?? '');
    $forwarded = strtolower((string) ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? ''));
    $scheme = ($https !== '' && $https !== 'off') || $forwarded === 'https' ? 'https' : 'http';

    $host = (string) ($_SERVER['HTTP_HOST'] ?? 'localhost');
    $dir = rtrim(str_replace('\\', '/', dirname((string) ($_SERVER['SCRIPT_NAME'] ?? ''))), '/');
    $dir = $dir === '.' ? '' : $dir;

    return $scheme . '://' . $host . $dir;
}

function assets_base_url(): string
{
    $dir = rtrim(str_replace('\\', '/', dirname((string) ($_SERVER['SCRIPT_NAME'] ?? ''))), '/');

    return ($dir === '.' ? '' : $dir) . '/assets';
}

function json_body(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }

    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        fail(400, 'Request body must be a JSON object.');
    }

    return $decoded;
}

$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

$configPath = __DIR__ . '/config.php';
if (!is_file($configPath)) {
    fail(
        500,
        'Server not configured: config.php is missing. Copy config.example.php '
        . 'to config.php and fill in your database credentials.'
    );
}

$config = require $configPath;
$debug = (bool) ($config['debug'] ?? false);

date_default_timezone_set((string) ($config['timezone'] ?? 'UTC'));

$segments = array_values(array_filter(explode('/', request_path()), static function ($part) {
    return $part !== '';
}));

$baseUrl = public_base_url($config);

try {
    $pdo = db_connect($config);
} catch (Throwable $error) {
    if (($segments[0] ?? '') === 'pass') {
        send_html(503, render_pass_not_found($config));
    }
    fail(
        503,
        $debug
            ? 'Could not connect to the database: ' . $error->getMessage()
            : 'The service is temporarily unavailable. Please try again shortly.'
    );
}

if (($segments[0] ?? '') === 'pass') {
    if ($method !== 'GET' && $method !== 'HEAD') {
        send_html(405, render_pass_not_found($config));
    }

    $token = (string) ($segments[1] ?? '');

    try {
        $row = visitor_find_by_token($pdo, $token);
    } catch (Throwable $error) {
        send_html(503, render_pass_not_found($config));
    }

    if ($row === null) {
        send_html(404, render_pass_not_found($config));
    }

    send_html(200, render_pass_page($config, $row, assets_base_url()));
}

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Api-Key');

if ($method === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$expectedKey = (string) ($config['api_key'] ?? '');
if ($expectedKey !== '') {
    $providedKey = (string) ($_SERVER['HTTP_X_API_KEY'] ?? '');
    if (!hash_equals($expectedKey, $providedKey)) {
        fail(401, 'Invalid or missing API key.');
    }
}

if (($segments[0] ?? '') !== 'v1') {
    fail(404, 'Unknown endpoint. Routes are served under /v1.');
}

$resource = $segments[1] ?? '';
$id = $segments[2] ?? null;
$action = $segments[3] ?? null;

if (count($segments) > 4) {
    fail(404, 'Unknown endpoint.');
}

try {
    if ($resource === 'health' && $id === null) {
        if ($method !== 'GET') {
            fail(405, 'Only GET is supported for this endpoint.');
        }
        $count = (int) $pdo->query('SELECT COUNT(*) FROM visitors')->fetchColumn();
        send(200, [
            'status' => 'ok',
            'driver' => $config['driver'] ?? 'mysql',
            'visitors' => $count,
            'base_url' => $baseUrl,
            'mail_enabled' => (bool) ($config['mail_enabled'] ?? true),
            'mail_transport' => smtp_is_configured($config) ? 'smtp' : 'mail()',
            'time' => iso_now(),
        ]);
    }

    if ($resource === 'mail-check' && $id === null) {
        if ($method !== 'GET') {
            fail(405, 'Only GET is supported for this endpoint.');
        }

        if (!smtp_is_configured($config)) {
            send(200, [
                'transport' => 'mail()',
                'ok' => false,
                'message' => 'No SMTP credentials configured; mail() would be used.',
            ]);
        }

        $check = smtp_dispatch($config, null);

        send($check['ok'] ? 200 : 502, [
            'transport' => 'smtp',
            'host' => $config['smtp_host'],
            'port' => (int) ($config['smtp_port'] ?? 465),
            'ok' => $check['ok'],
            'message' => $check['ok']
                ? 'Connected and authenticated. No message was sent.'
                : $check['error'],
            'log' => $debug ? $check['log'] : null,
        ]);
    }

    if ($resource !== 'visitors') {
        fail(404, 'Unknown endpoint.');
    }

    if ($id === null) {
        if ($method === 'GET') {
            $rows = visitors_all($pdo);
            send(200, array_map(static function (array $row) use ($baseUrl) {
                return visitor_to_json($row, $baseUrl);
            }, $rows));
        }

        if ($method === 'POST') {
            $input = json_body();
            $errors = validate_visitor($input);
            if ($errors !== []) {
                fail(422, implode(' ', $errors));
            }

            $row = visitor_insert($pdo, $input);
            $payload = visitor_to_json($row, $baseUrl);

            $mail = ['sent' => false, 'reason' => 'No pass link was generated.'];
            if ($payload['pass_url'] !== null) {
                $mail = send_pass_email($config, $payload, (string) $payload['pass_url']);
            }

            $payload['pass_email_sent'] = $mail['sent'];
            $payload['pass_email_message'] = $mail['reason'];

            send(201, $payload);
        }

        fail(405, 'Only GET and POST are supported for /v1/visitors.');
    }

    $existing = visitor_find($pdo, $id);
    if ($existing === null) {
        fail(404, 'No visitor was found with that ID.');
    }

    if ($action === 'send-pass') {
        if ($method !== 'POST') {
            fail(405, 'Use POST to re-send a pass email.');
        }

        $existing = visitor_ensure_token($pdo, $existing);
        $payload = visitor_to_json($existing, $baseUrl);

        if ($payload['pass_url'] === null) {
            fail(500, 'A pass link could not be generated for this visitor.');
        }

        $mail = send_pass_email($config, $payload, (string) $payload['pass_url']);

        send($mail['sent'] ? 200 : 422, [
            'message' => $mail['reason'],
            'sent' => $mail['sent'],
            'pass_url' => $payload['pass_url'],
        ]);
    }

    if ($action !== null) {
        fail(404, 'Unknown endpoint.');
    }

    if ($method === 'GET') {
        send(200, visitor_to_json($existing, $baseUrl));
    }

    if ($method === 'DELETE') {
        visitor_delete($pdo, $id);
        send(200, ['message' => 'Visitor deleted.', 'id' => (string) $id]);
    }

    if ($method === 'PUT' || $method === 'PATCH') {
        $input = json_body();

        if ($method === 'PUT') {
            $errors = validate_visitor($input);
            if ($errors !== []) {
                fail(422, implode(' ', $errors));
            }
        } elseif (array_key_exists('status', $input)) {
            $candidate = nullable_string($input['status']);
            if ($candidate !== null && !in_array($candidate, VISITOR_STATUSES, true)) {
                fail(422, 'Status must be one of: ' . implode(', ', VISITOR_STATUSES) . '.');
            }
        }

        $requested = nullable_string($input['status'] ?? null);
        $current = (string) $existing['status'];

        $isMove = $requested !== null && $requested !== $current;
        $mustBeLegalTransition = $requested !== null && ($method === 'PATCH' || $isMove);

        if ($mustBeLegalTransition
            && !in_array($requested, allowed_transitions($current), true)) {
            fail(409, status_conflict_message($existing, $requested));
        }

        if ($isMove) {
            if ($requested === STATUS_CHECKED_IN
                && nullable_string($input['check_in_time'] ?? null) === null) {
                $input['check_in_time'] = iso_now();
            }
            if ($requested === STATUS_CHECKED_OUT
                && nullable_string($input['check_out_time'] ?? null) === null) {
                $input['check_out_time'] = iso_now();
            }
        }

        $updated = $method === 'PUT'
            ? visitor_replace($pdo, $id, $input, $existing)
            : visitor_patch($pdo, $id, $input);

        send(200, visitor_to_json($updated, $baseUrl));
    }

    fail(405, 'That method is not supported for a single visitor.');
} catch (PDOException $error) {
    fail(
        500,
        $debug
            ? 'Database error: ' . $error->getMessage()
            : 'The server could not complete that request.'
    );
} catch (Throwable $error) {
    fail(
        500,
        $debug
            ? 'Unexpected error: ' . $error->getMessage()
            : 'The server could not complete that request.'
    );
}

function status_conflict_message(array $visitor, string $requested): string
{
    $name = trim((string) ($visitor['name'] ?? 'This visitor'));
    $current = (string) $visitor['status'];

    if ($requested === STATUS_CHECKED_IN) {
        return $current === STATUS_CHECKED_OUT
            ? "$name has already completed this visit and cannot check in again."
            : "$name is already checked in.";
    }

    if ($requested === STATUS_CHECKED_OUT) {
        return $current === STATUS_CHECKED_OUT
            ? "$name has already checked out."
            : "$name has not checked in yet.";
    }

    return "$name cannot move from $current to $requested.";
}

<?php

declare(strict_types=1);

function smtp_is_configured(array $config): bool
{
    return trim((string) ($config['smtp_host'] ?? '')) !== ''
        && trim((string) ($config['smtp_username'] ?? '')) !== ''
        && trim((string) ($config['smtp_password'] ?? '')) !== '';
}

function smtp_dispatch(array $config, ?array $envelope): array
{
    $host = trim((string) $config['smtp_host']);
    $port = (int) ($config['smtp_port'] ?? 465);
    $secure = strtolower(trim((string) ($config['smtp_secure'] ?? 'ssl')));
    $username = (string) $config['smtp_username'];
    $password = (string) $config['smtp_password'];
    $timeout = (int) ($config['smtp_timeout'] ?? 20);

    $log = [];

    $endpoint = ($secure === 'ssl' ? 'ssl://' : '') . $host . ':' . $port;

    $context = stream_context_create([
        'ssl' => [
            'verify_peer' => true,
            'verify_peer_name' => true,
            'SNI_enabled' => true,
        ],
    ]);

    $socket = @stream_socket_client(
        $endpoint,
        $errorCode,
        $errorMessage,
        $timeout,
        STREAM_CLIENT_CONNECT,
        $context
    );

    if (!$socket) {
        return smtp_result(false, sprintf(
            'Could not connect to %s: %s',
            $endpoint,
            $errorMessage !== '' ? $errorMessage : 'connection refused'
        ), $log);
    }

    stream_set_timeout($socket, $timeout);

    try {
        [$code, $text] = smtp_read($socket);
        $log[] = "< $text";
        if ($code !== 220) {
            return smtp_result(false, "The mail server refused the connection: $text", $log, $socket);
        }

        $greeting = smtp_hostname();

        [$code, $text] = smtp_command($socket, "EHLO $greeting", $log);
        if ($code !== 250) {
            return smtp_result(false, "EHLO was rejected: $text", $log, $socket);
        }

        if ($secure === 'tls') {
            [$code, $text] = smtp_command($socket, 'STARTTLS', $log);
            if ($code !== 220) {
                return smtp_result(false, "STARTTLS was refused: $text", $log, $socket);
            }

            $crypto = @stream_socket_enable_crypto(
                $socket,
                true,
                STREAM_CRYPTO_METHOD_TLS_CLIENT
            );
            if ($crypto !== true) {
                return smtp_result(false, 'The TLS handshake failed.', $log, $socket);
            }
            $log[] = '--- TLS established ---';

            [$code, $text] = smtp_command($socket, "EHLO $greeting", $log);
            if ($code !== 250) {
                return smtp_result(false, "EHLO after STARTTLS was rejected: $text", $log, $socket);
            }
        }

        [$code, $text] = smtp_command($socket, 'AUTH LOGIN', $log, true);
        if ($code !== 334) {
            return smtp_result(false, "The server would not start authentication: $text", $log, $socket);
        }

        [$code, $text] = smtp_command($socket, base64_encode($username), $log, true);
        if ($code !== 334) {
            return smtp_result(false, "The username was rejected: $text", $log, $socket);
        }

        [$code, $text] = smtp_command($socket, base64_encode($password), $log, true);
        if ($code !== 235) {
            return smtp_result(
                false,
                'Authentication failed. Check the mailbox address and password.',
                $log,
                $socket
            );
        }
        $log[] = '--- authenticated ---';

        if ($envelope === null) {
            smtp_command($socket, 'QUIT', $log);
            return smtp_result(true, '', $log, $socket);
        }

        [$code, $text] = smtp_command($socket, 'MAIL FROM:<' . $envelope['from'] . '>', $log);
        if ($code !== 250) {
            return smtp_result(false, "The sender address was rejected: $text", $log, $socket);
        }

        [$code, $text] = smtp_command($socket, 'RCPT TO:<' . $envelope['to'] . '>', $log);
        if ($code !== 250 && $code !== 251) {
            return smtp_result(false, "The recipient was rejected: $text", $log, $socket);
        }

        [$code, $text] = smtp_command($socket, 'DATA', $log);
        if ($code !== 354) {
            return smtp_result(false, "The server would not accept the message: $text", $log, $socket);
        }

        $message = $envelope['headers'] . "\r\n" . $envelope['body'];
        fwrite($socket, smtp_dot_stuff($message) . "\r\n.\r\n");

        [$code, $text] = smtp_read($socket);
        $log[] = "< $text";
        if ($code !== 250) {
            return smtp_result(false, "The message was not accepted: $text", $log, $socket);
        }

        smtp_command($socket, 'QUIT', $log);

        return smtp_result(true, '', $log, $socket);
    } catch (Throwable $error) {
        return smtp_result(false, 'Unexpected mail error: ' . $error->getMessage(), $log, $socket);
    }
}

function smtp_read($socket): array
{
    $response = '';

    while (($line = fgets($socket, 515)) !== false) {
        $response .= $line;
        if (strlen($line) < 4) {
            break;
        }
        if ($line[3] === ' ') {
            break;
        }
    }

    if ($response === '') {
        return [0, 'no response (the connection timed out or was closed)'];
    }

    return [(int) substr($response, 0, 3), trim($response)];
}

function smtp_command($socket, string $command, array &$log, bool $sensitive = false): array
{
    $log[] = '> ' . ($sensitive ? '[redacted]' : $command);
    fwrite($socket, $command . "\r\n");

    [$code, $text] = smtp_read($socket);
    $log[] = "< $text";

    return [$code, $text];
}

function smtp_dot_stuff(string $message): string
{
    $normalised = preg_replace('/\r\n|\r|\n/', "\r\n", $message) ?? $message;

    return preg_replace('/^\./m', '..', $normalised) ?? $normalised;
}

function smtp_hostname(): string
{
    $host = (string) ($_SERVER['SERVER_NAME'] ?? '');
    if ($host === '') {
        $host = (string) ($_SERVER['HTTP_HOST'] ?? '');
    }
    $host = preg_replace('/:\d+$/', '', $host) ?? $host;

    return $host !== '' ? $host : 'localhost';
}

function smtp_result(bool $ok, string $error, array $log, $socket = null): array
{
    if (is_resource($socket)) {
        @fclose($socket);
    }

    return ['ok' => $ok, 'error' => $error, 'log' => $log];
}

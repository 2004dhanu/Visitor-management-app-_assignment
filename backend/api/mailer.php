<?php

declare(strict_types=1);

require_once __DIR__ . '/smtp.php';

function send_pass_email(array $config, array $visitor, string $passUrl): array
{
    if (!($config['mail_enabled'] ?? true)) {
        return ['sent' => false, 'reason' => 'Email sending is disabled in config.'];
    }

    $to = trim((string) ($visitor['email'] ?? ''));
    if ($to === '') {
        return ['sent' => false, 'reason' => 'Visitor has no email address.'];
    }
    if (filter_var($to, FILTER_VALIDATE_EMAIL) === false) {
        return ['sent' => false, 'reason' => 'Visitor email address is not valid.'];
    }

    $from = trim((string) ($config['mail_from'] ?? ''));
    if ($from === '' || filter_var($from, FILTER_VALIDATE_EMAIL) === false) {
        return ['sent' => false, 'reason' => 'mail_from is not configured correctly.'];
    }

    $org = (string) ($config['organisation_name'] ?? 'Visitor Management');
    $fromName = (string) ($config['mail_from_name'] ?? $org);

    $subject = sprintf('Your visitor pass for %s', $org);
    $boundary = 'vmsb' . bin2hex(random_bytes(10));
    $body = build_pass_email_body($boundary, $org, $visitor, $passUrl);

    $headers = [
        'Date: ' . date('r'),
        'Message-ID: ' . mail_message_id($from),
        'MIME-Version: 1.0',
        sprintf('From: %s <%s>', mail_encode_name($fromName), $from),
        sprintf('Content-Type: multipart/alternative; boundary="%s"', $boundary),
        'X-Mailer: Visitor Management API',
    ];

    $replyTo = trim((string) ($config['mail_reply_to'] ?? ''));
    if ($replyTo !== '' && filter_var($replyTo, FILTER_VALIDATE_EMAIL) !== false) {
        $headers[] = 'Reply-To: ' . $replyTo;
    }

    if (smtp_is_configured($config)) {
        return send_via_smtp($config, $to, $from, $subject, $headers, $body);
    }

    return send_via_mail($to, $from, $subject, $headers, $body);
}

function send_via_smtp(
    array $config,
    string $to,
    string $from,
    string $subject,
    array $headers,
    string $body
): array {
    array_unshift(
        $headers,
        'To: ' . $to,
        'Subject: ' . mail_encode_subject($subject)
    );

    $result = smtp_dispatch($config, [
        'to' => $to,
        'from' => $from,
        'headers' => implode("\r\n", $headers),
        'body' => $body,
    ]);

    if ($result['ok']) {
        return ['sent' => true, 'reason' => 'Pass link emailed to ' . $to . '.'];
    }

    return ['sent' => false, 'reason' => $result['error']];
}

function send_via_mail(
    string $to,
    string $from,
    string $subject,
    array $headers,
    string $body
): array {
    if (!function_exists('mail')) {
        return ['sent' => false, 'reason' => 'mail() is unavailable on this host.'];
    }

    $block = implode("\r\n", $headers);

    $sent = @mail($to, $subject, $body, $block, '-f' . $from);
    if (!$sent) {
        $sent = @mail($to, $subject, $body, $block);
    }

    return $sent
        ? ['sent' => true, 'reason' => 'Pass link emailed to ' . $to . '.']
        : ['sent' => false, 'reason' => 'The mail server rejected the message.'];
}

function mail_encode_name(string $name): string
{
    if (preg_match('/^[\x20-\x7E]*$/', $name) === 1) {
        return '"' . str_replace(['"', '\\'], '', $name) . '"';
    }

    return '=?UTF-8?B?' . base64_encode($name) . '?=';
}

function mail_encode_subject(string $subject): string
{
    if (preg_match('/^[\x20-\x7E]*$/', $subject) === 1) {
        return $subject;
    }

    return '=?UTF-8?B?' . base64_encode($subject) . '?=';
}

function mail_message_id(string $from): string
{
    $domain = substr(strrchr($from, '@') ?: '@localhost', 1);

    return sprintf('<%s.%s@%s>', bin2hex(random_bytes(8)), time(), $domain);
}

function build_pass_email_body(
    string $boundary,
    string $org,
    array $visitor,
    string $passUrl
): string {
    $name = (string) ($visitor['name'] ?? 'Visitor');
    $project = (string) ($visitor['project'] ?? '');
    $purpose = (string) ($visitor['purpose'] ?? '');

    $text = <<<TEXT
Hello {$name},

Your visitor pass for {$org} is ready.

Open this link to view your pass:
{$passUrl}

Visit details
  Project: {$project}
  Purpose: {$purpose}

Please have the pass open on your phone when you arrive. Security will scan
the QR code to check you in, and again when you leave.

This link is personal to you. Please do not forward it.

-- {$org}
TEXT;

    $e = static function (string $value): string {
        return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
    };

    $html = '<!doctype html><html><head><meta charset="utf-8">'
        . '<meta name="viewport" content="width=device-width,initial-scale=1">'
        . '</head><body style="margin:0;padding:24px;background:#f4f6f8;'
        . 'font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;'
        . 'color:#1a1c1e;">'
        . '<div style="max-width:520px;margin:0 auto;background:#ffffff;'
        . 'border-radius:14px;padding:28px;">'
        . '<p style="margin:0 0 4px;font-size:13px;letter-spacing:.06em;'
        . 'text-transform:uppercase;color:#5f6368;">' . $e($org) . '</p>'
        . '<h1 style="margin:0 0 16px;font-size:22px;">Your visitor pass is ready</h1>'
        . '<p style="margin:0 0 20px;font-size:15px;line-height:1.6;">Hello '
        . $e($name) . ', tap the button below to open your pass. Have it on '
        . 'screen when you arrive &mdash; security will scan the QR code to '
        . 'check you in, and again when you leave.</p>'
        . '<p style="margin:0 0 24px;"><a href="' . $e($passUrl) . '" '
        . 'style="display:inline-block;background:#1565c0;color:#ffffff;'
        . 'text-decoration:none;padding:14px 24px;border-radius:10px;'
        . 'font-weight:600;font-size:15px;">View my pass</a></p>'
        . '<table style="width:100%;border-collapse:collapse;font-size:14px;">'
        . '<tr><td style="padding:6px 0;color:#5f6368;width:90px;">Project</td>'
        . '<td style="padding:6px 0;font-weight:500;">' . $e($project) . '</td></tr>'
        . '<tr><td style="padding:6px 0;color:#5f6368;">Purpose</td>'
        . '<td style="padding:6px 0;font-weight:500;">' . $e($purpose) . '</td></tr>'
        . '</table>'
        . '<p style="margin:22px 0 0;font-size:12px;color:#5f6368;line-height:1.6;">'
        . 'If the button does not work, copy this link into your browser:<br>'
        . '<span style="word-break:break-all;">' . $e($passUrl) . '</span></p>'
        . '<p style="margin:16px 0 0;font-size:12px;color:#5f6368;">'
        . 'This link is personal to you. Please do not forward it.</p>'
        . '</div></body></html>';

    return "--$boundary\r\n"
        . "Content-Type: text/plain; charset=UTF-8\r\n"
        . "Content-Transfer-Encoding: 8bit\r\n\r\n"
        . $text . "\r\n\r\n"
        . "--$boundary\r\n"
        . "Content-Type: text/html; charset=UTF-8\r\n"
        . "Content-Transfer-Encoding: 8bit\r\n\r\n"
        . $html . "\r\n\r\n"
        . "--$boundary--\r\n";
}

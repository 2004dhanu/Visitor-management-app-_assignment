<?php

declare(strict_types=1);

function pass_escape($value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

function render_pass_page(array $config, array $visitor, string $assetsBase): string
{
    $status = (string) ($visitor['status'] ?? STATUS_REGISTERED);
    $id = (string) ($visitor['id'] ?? '');

    $isComplete = $status === STATUS_CHECKED_OUT;

    [$statusColor, $statusNote] = pass_status_presentation($status);

    $org = pass_escape($config['organisation_name'] ?? 'Visitor Management');
    $name = pass_escape($visitor['name'] ?? '');
    $statusText = pass_escape($status);
    $passId = pass_escape($id);
    $assets = pass_escape(rtrim($assetsBase, '/'));
    $note = pass_escape($statusNote);

    $qrPayload = json_encode(
        'VMS:' . $id,
        JSON_UNESCAPED_SLASHES | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT
    );

    $checkedIn = nullable_string($visitor['check_in_time'] ?? null);
    $checkedOut = nullable_string($visitor['check_out_time'] ?? null);

    $rows = pass_row('Project', (string) ($visitor['project'] ?? ''))
        . pass_row('Purpose', (string) ($visitor['purpose'] ?? ''))
        . pass_row('Visitor type', (string) ($visitor['visitor_type'] ?? ''));

    if ($checkedIn !== null) {
        $rows .= pass_row('Checked in', pass_format_time($checkedIn));
    }
    if ($checkedOut !== null) {
        $rows .= pass_row('Checked out', pass_format_time($checkedOut));
    }

    $qrBlock = $isComplete
        ? '<div class="done"><div class="done-icon">&#10003;</div>'
          . '<p class="done-text">This visit is complete.<br>The pass is no longer active.</p></div>'
        : '<div class="qr-frame"><div id="qr" class="qr"></div>'
          . '<noscript><p class="fallback">Enable JavaScript to display the QR code, '
          . 'or show the pass ID below to security.</p></noscript></div>';

    $script = $isComplete ? '' : <<<SCRIPT
  <script src="{$assets}/qrcode.min.js"></script>
  <script>
    (function () {
      var holder = document.getElementById('qr');
      if (!holder) return;

      if (typeof QRCode === 'undefined') {
        holder.innerHTML = '<p class="fallback">The QR code could not be ' +
          'displayed. Please show the pass ID below to security.</p>';
        return;
      }

      new QRCode(holder, {
        text: {$qrPayload},
        width: 232,
        height: 232,
        colorDark: '#000000',
        colorLight: '#ffffff',
        correctLevel: QRCode.CorrectLevel.M
      });
    })();
  </script>
SCRIPT;

    return <<<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="theme-color" content="#1565c0">
<title>Visitor Pass &middot; {$org}</title>
<style>
  :root {
    --bg: #eef1f5;
    --card: #ffffff;
    --ink: #1a1c1e;
    --muted: #5f6368;
    --line: #e3e6ea;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #121416;
      --card: #1c1f22;
      --ink: #e6e8ea;
      --muted: #9aa0a6;
      --line: #2c3034;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 24px 16px 40px;
    background: var(--bg);
    color: var(--ink);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
                 Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  .card {
    max-width: 420px;
    margin: 0 auto;
    background: var(--card);
    border: 1px solid var(--line);
    border-radius: 18px;
    padding: 28px 24px 24px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, .06);
  }
  .org {
    margin: 0 0 6px;
    font-size: 12px;
    letter-spacing: .08em;
    text-transform: uppercase;
    color: var(--muted);
    text-align: center;
  }
  h1 { margin: 0 0 18px; font-size: 20px; text-align: center; font-weight: 600; }
  .name { margin: 0; font-size: 24px; font-weight: 700; text-align: center; }
  .badge {
    display: block;
    width: fit-content;
    margin: 10px auto 0;
    padding: 5px 14px;
    border-radius: 999px;
    font-size: 12px;
    font-weight: 700;
  }
  .qr-frame {
    margin: 24px auto 8px;
    width: fit-content;
    padding: 16px;
    background: #ffffff;
    border: 1px solid var(--line);
    border-radius: 14px;
  }
  .qr { width: 232px; height: 232px; }
  .qr img, .qr canvas { display: block; width: 100% !important; height: auto !important; }
  .pid {
    margin: 10px auto 0;
    width: fit-content;
    padding: 5px 12px;
    background: var(--bg);
    border-radius: 6px;
    font-size: 13px;
    font-variant-numeric: tabular-nums;
    letter-spacing: .06em;
    color: var(--muted);
  }
  .hint {
    margin: 18px 0 0;
    font-size: 13px;
    line-height: 1.6;
    color: var(--muted);
    text-align: center;
  }
  table { width: 100%; border-collapse: collapse; margin-top: 22px; }
  th, td { padding: 9px 0; font-size: 14px; text-align: left; vertical-align: top; }
  th { width: 112px; color: var(--muted); font-weight: 400; }
  td { font-weight: 500; }
  tr + tr th, tr + tr td { border-top: 1px solid var(--line); }
  .done { margin: 28px 0 8px; text-align: center; }
  .done-icon {
    width: 64px;
    height: 64px;
    margin: 0 auto 14px;
    border-radius: 50%;
    background: rgba(46, 125, 50, .12);
    color: #2e7d32;
    font-size: 32px;
    line-height: 64px;
  }
  .done-text { margin: 0; font-size: 15px; line-height: 1.6; color: var(--muted); }
  .fallback { margin: 0; font-size: 13px; color: var(--muted); max-width: 220px; }
  .foot {
    max-width: 420px;
    margin: 18px auto 0;
    font-size: 12px;
    line-height: 1.6;
    color: var(--muted);
    text-align: center;
  }
  @media print {
    body { background: #fff; padding: 0; }
    .card { border: none; box-shadow: none; }
    .foot { display: none; }
  }
</style>
</head>
<body>
  <main class="card">
    <p class="org">{$org}</p>
    <h1>Visitor Pass</h1>
    <p class="name">{$name}</p>
    <span class="badge" style="color:{$statusColor};background:{$statusColor}1f;">{$statusText}</span>

    {$qrBlock}

    <p class="pid">PASS ID&nbsp;&nbsp;{$passId}</p>
    <p class="hint">{$note}</p>

    <table>{$rows}</table>
  </main>

  <p class="foot">This pass is personal to you. Please do not forward this link.</p>
{$script}
</body>
</html>
HTML;
}

function pass_status_presentation(string $status): array
{
    switch ($status) {
        case STATUS_CHECKED_IN:
            return ['#2e7d32', 'You are checked in. Show this pass again on your way out.'];
        case STATUS_CHECKED_OUT:
            return ['#6d4c41', 'Thank you for visiting.'];
        default:
            return ['#1565c0', 'Show this QR code at the gate and security will check you in.'];
    }
}

function pass_row(string $label, string $value): string
{
    if (trim($value) === '') {
        return '';
    }

    return '<tr><th>' . pass_escape($label) . '</th>'
        . '<td>' . pass_escape($value) . '</td></tr>';
}

function pass_format_time(string $iso): string
{
    try {
        return (new DateTimeImmutable($iso))->format('d M Y, h:i A');
    } catch (Throwable $error) {
        return $iso;
    }
}

function render_pass_not_found(array $config): string
{
    $org = pass_escape($config['organisation_name'] ?? 'Visitor Management');

    return <<<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Pass not found</title>
<style>
  body {
    margin: 0;
    min-height: 100vh;
    display: grid;
    place-items: center;
    padding: 24px;
    background: #eef1f5;
    color: #1a1c1e;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
                 Helvetica, Arial, sans-serif;
  }
  @media (prefers-color-scheme: dark) {
    body { background: #121416; color: #e6e8ea; }
    .card { background: #1c1f22 !important; border-color: #2c3034 !important; }
  }
  .card {
    max-width: 380px;
    background: #fff;
    border: 1px solid #e3e6ea;
    border-radius: 18px;
    padding: 32px 26px;
    text-align: center;
  }
  h1 { margin: 0 0 10px; font-size: 19px; }
  p { margin: 0; font-size: 14px; line-height: 1.6; color: #5f6368; }
</style>
</head>
<body>
  <main class="card">
    <h1>This pass is not available</h1>
    <p>The link may be incorrect or expired. Please contact the {$org}
       front desk and they will issue a new pass.</p>
  </main>
</body>
</html>
HTML;
}

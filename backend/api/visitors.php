<?php

declare(strict_types=1);

const STATUS_REGISTERED = 'Registered';
const STATUS_CHECKED_IN = 'Checked In';
const STATUS_CHECKED_OUT = 'Checked Out';

const VISITOR_STATUSES = [STATUS_REGISTERED, STATUS_CHECKED_IN, STATUS_CHECKED_OUT];
const VISITOR_TYPES = ['Customer', 'Vendor', 'Other'];

const VISITOR_COLUMNS = 'id, pass_token, name, mobile, email, visitor_type, project, '
    . 'purpose, status, created_at, check_in_time, check_out_time';

function allowed_transitions(string $current): array
{
    switch ($current) {
        case STATUS_REGISTERED:
            return [STATUS_CHECKED_IN];
        case STATUS_CHECKED_IN:
            return [STATUS_CHECKED_OUT];
        default:
            return [];
    }
}

function new_pass_token(): string
{
    return bin2hex(random_bytes(16));
}

function pass_url_for(string $baseUrl, ?string $token): ?string
{
    $base = rtrim($baseUrl, '/');
    if ($base === '' || $token === null || $token === '') {
        return null;
    }

    return $base . '/pass/' . $token;
}

function visitor_to_json(array $row, string $publicBaseUrl = ''): array
{
    return [
        'id' => (string) $row['id'],
        'name' => (string) $row['name'],
        'mobile' => (string) $row['mobile'],
        'email' => nullable_string($row['email'] ?? null),
        'visitor_type' => (string) $row['visitor_type'],
        'project' => (string) $row['project'],
        'purpose' => (string) $row['purpose'],
        'status' => (string) $row['status'],
        'created_at' => nullable_string($row['created_at'] ?? null),
        'check_in_time' => nullable_string($row['check_in_time'] ?? null),
        'check_out_time' => nullable_string($row['check_out_time'] ?? null),
        'pass_url' => pass_url_for(
            $publicBaseUrl,
            nullable_string($row['pass_token'] ?? null)
        ),
    ];
}

function nullable_string($value): ?string
{
    if ($value === null) {
        return null;
    }
    $text = trim((string) $value);
    return $text === '' ? null : $text;
}

function validate_visitor(array $input): array
{
    $errors = [];

    $name = trim((string) ($input['name'] ?? ''));
    if ($name === '') {
        $errors[] = 'Visitor name is required.';
    } elseif (mb_strlen($name) > 120) {
        $errors[] = 'Visitor name must be 120 characters or fewer.';
    }

    $mobile = trim((string) ($input['mobile'] ?? ''));
    if ($mobile === '') {
        $errors[] = 'Mobile number is required.';
    } elseif (preg_match('/^\d{10}$/', $mobile) !== 1) {
        $errors[] = 'Mobile number must be exactly 10 digits.';
    }

    $email = nullable_string($input['email'] ?? null);
    if ($email !== null && filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
        $errors[] = 'Email address is not valid.';
    }

    $type = trim((string) ($input['visitor_type'] ?? ''));
    if ($type === '') {
        $errors[] = 'Visitor type is required.';
    } elseif (!in_array($type, VISITOR_TYPES, true)) {
        $errors[] = 'Visitor type must be one of: ' . implode(', ', VISITOR_TYPES) . '.';
    }

    if (trim((string) ($input['project'] ?? '')) === '') {
        $errors[] = 'Project is required.';
    }

    if (trim((string) ($input['purpose'] ?? '')) === '') {
        $errors[] = 'Purpose of visit is required.';
    }

    $status = nullable_string($input['status'] ?? null);
    if ($status !== null && !in_array($status, VISITOR_STATUSES, true)) {
        $errors[] = 'Status must be one of: ' . implode(', ', VISITOR_STATUSES) . '.';
    }

    return $errors;
}

function visitors_all(PDO $pdo): array
{
    $sql = 'SELECT ' . VISITOR_COLUMNS . ' FROM visitors ORDER BY id DESC';

    return $pdo->query($sql)->fetchAll();
}

function visitor_find(PDO $pdo, string $id): ?array
{
    $statement = $pdo->prepare('SELECT ' . VISITOR_COLUMNS . ' FROM visitors WHERE id = ?');
    $statement->execute([$id]);
    $row = $statement->fetch();

    return $row === false ? null : $row;
}

function visitor_find_by_token(PDO $pdo, string $token): ?array
{
    if (preg_match('/^[a-f0-9]{32}$/', $token) !== 1) {
        return null;
    }

    $statement = $pdo->prepare(
        'SELECT ' . VISITOR_COLUMNS . ' FROM visitors WHERE pass_token = ?'
    );
    $statement->execute([$token]);
    $row = $statement->fetch();

    return $row === false ? null : $row;
}

function visitor_ensure_token(PDO $pdo, array $row): array
{
    if (nullable_string($row['pass_token'] ?? null) !== null) {
        return $row;
    }

    $token = new_pass_token();
    $pdo->prepare('UPDATE visitors SET pass_token = ? WHERE id = ?')
        ->execute([$token, (string) $row['id']]);

    $row['pass_token'] = $token;

    return $row;
}

function visitor_insert(PDO $pdo, array $input): array
{
    $statement = $pdo->prepare(
        'INSERT INTO visitors
            (pass_token, name, mobile, email, visitor_type, project, purpose,
             status, created_at, check_in_time, check_out_time)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );

    $statement->execute([
        new_pass_token(),
        trim((string) $input['name']),
        trim((string) $input['mobile']),
        nullable_string($input['email'] ?? null),
        trim((string) $input['visitor_type']),
        trim((string) $input['project']),
        trim((string) $input['purpose']),
        STATUS_REGISTERED,
        nullable_string($input['created_at'] ?? null) ?? iso_now(),
        null,
        null,
    ]);

    $row = visitor_find($pdo, (string) $pdo->lastInsertId());

    return $row ?? [];
}

function visitor_replace(PDO $pdo, string $id, array $input, array $existing): array
{
    $statement = $pdo->prepare(
        'UPDATE visitors SET
            name = ?, mobile = ?, email = ?, visitor_type = ?, project = ?,
            purpose = ?, status = ?, created_at = ?, check_in_time = ?,
            check_out_time = ?
         WHERE id = ?'
    );

    $statement->execute([
        trim((string) $input['name']),
        trim((string) $input['mobile']),
        nullable_string($input['email'] ?? null),
        trim((string) $input['visitor_type']),
        trim((string) $input['project']),
        trim((string) $input['purpose']),
        nullable_string($input['status'] ?? null) ?? $existing['status'],
        nullable_string($input['created_at'] ?? null) ?? $existing['created_at'],
        nullable_string($input['check_in_time'] ?? null),
        nullable_string($input['check_out_time'] ?? null),
        $id,
    ]);

    return visitor_find($pdo, $id) ?? [];
}

function visitor_patch(PDO $pdo, string $id, array $fields): array
{
    $allowed = [
        'name', 'mobile', 'email', 'visitor_type', 'project', 'purpose',
        'status', 'created_at', 'check_in_time', 'check_out_time',
    ];

    $assignments = [];
    $values = [];

    foreach ($allowed as $column) {
        if (!array_key_exists($column, $fields)) {
            continue;
        }
        $assignments[] = "$column = ?";
        $values[] = in_array($column, ['email', 'check_in_time', 'check_out_time'], true)
            ? nullable_string($fields[$column])
            : trim((string) $fields[$column]);
    }

    if ($assignments !== []) {
        $values[] = $id;
        $sql = 'UPDATE visitors SET ' . implode(', ', $assignments) . ' WHERE id = ?';
        $pdo->prepare($sql)->execute($values);
    }

    return visitor_find($pdo, $id) ?? [];
}

function visitor_delete(PDO $pdo, string $id): void
{
    $pdo->prepare('DELETE FROM visitors WHERE id = ?')->execute([$id]);
}

function iso_now(): string
{
    return (new DateTimeImmutable('now'))->format('Y-m-d\TH:i:sP');
}

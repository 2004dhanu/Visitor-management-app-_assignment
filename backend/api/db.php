<?php

declare(strict_types=1);

function db_connect(array $config): PDO
{
    $driver = $config['driver'] ?? 'mysql';

    if ($driver === 'sqlite') {
        $path = $config['sqlite_path'] ?? (__DIR__ . '/../visitors.sqlite');
        $pdo = new PDO('sqlite:' . $path, null, null, db_options());
        $pdo->exec('PRAGMA foreign_keys = ON');
        return $pdo;
    }

    $dsn = sprintf(
        'mysql:host=%s;dbname=%s;charset=%s',
        $config['host'] ?? 'localhost',
        $config['database'] ?? '',
        $config['charset'] ?? 'utf8mb4'
    );

    return new PDO(
        $dsn,
        $config['username'] ?? '',
        $config['password'] ?? '',
        db_options()
    );
}

function db_options(): array
{
    return [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ];
}

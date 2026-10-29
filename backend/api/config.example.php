<?php

declare(strict_types=1);

return [
    'driver' => 'mysql',
    'host' => 'localhost',
    'database' => 'uXXXXXXXXX_visitor',
    'username' => 'uXXXXXXXXX_visitor',
    'password' => 'your-database-password',
    'charset' => 'utf8mb4',
    'sqlite_path' => __DIR__ . '/../visitors.sqlite',
    'timezone' => 'Asia/Kolkata',
    'public_base_url' => '',
    'organisation_name' => 'Visitor Management',
    'mail_enabled' => true,
    'mail_from' => 'visitors@your-domain.com',
    'mail_from_name' => 'Visitor Management',
    'mail_reply_to' => '',
    'smtp_host' => '',
    'smtp_port' => 465,
    'smtp_secure' => 'ssl',
    'smtp_username' => '',
    'smtp_password' => '',
    'smtp_timeout' => 20,
    'api_key' => '',
    'debug' => true,
];

# Visitor Management Backend API

A lightweight REST API in PHP and MySQL for the Visitor Management Flutter app. It provides visitor registration, lookup, check-in, check-out status management, and digital pass generation with email delivery.

## Live Deployment

- **Base URL:** `https://dy.solvyngroups.com/api/v1`
- **Pass URL:** `https://dy.solvyngroups.com/api/pass/{token}`
- **Health check:** `https://dy.solvyngroups.com/api/v1/health`
- **Mail check:** `https://dy.solvyngroups.com/api/v1/mail-check`

## Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/v1/health` | Service and database connectivity check |
| GET | `/v1/mail-check` | Verifies SMTP server authentication without sending mail |
| GET | `/v1/visitors` | List all visitors (newest first) |
| POST | `/v1/visitors` | Register a new visitor and trigger pass email |
| GET | `/v1/visitors/{id}` | Get a single visitor by ID |
| PUT | `/v1/visitors/{id}` | Full update of a visitor record |
| PATCH | `/v1/visitors/{id}` | Partial update (used for check-in and check-out) |
| DELETE | `/v1/visitors/{id}` | Delete a visitor record |
| POST | `/v1/visitors/{id}/send-pass` | Re-send pass link email |
| GET | `/pass/{token}` | Public web pass page with QR code for the visitor |

## Database Structure

The API uses a single table: `visitors`.

- `id`: INT AUTO_INCREMENT PRIMARY KEY
- `pass_token`: VARCHAR(32) UNIQUE
- `name`: VARCHAR(120) NOT NULL
- `mobile`: VARCHAR(10) NOT NULL
- `email`: VARCHAR(255) DEFAULT NULL
- `visitor_type`: ENUM('Customer', 'Vendor', 'Other') NOT NULL
- `project`: VARCHAR(120) NOT NULL
- `purpose`: VARCHAR(255) NOT NULL
- `status`: ENUM('Registered', 'Checked In', 'Checked Out') NOT NULL DEFAULT 'Registered'
- `created_at`: VARCHAR(32) NOT NULL
- `check_in_time`: VARCHAR(32) DEFAULT NULL
- `check_out_time`: VARCHAR(32) DEFAULT NULL

## Setup and Configuration

1. Copy `config.example.php` to `config.php`:
   ```bash
   cp backend/api/config.example.php backend/api/config.php
   ```
2. Configure your database and mail settings in `config.php`:
   - `host`, `database`, `username`, `password`
   - `public_base_url` (e.g. `https://dy.solvyngroups.com/api`)
   - `organisation_name`
   - `smtp_host`, `smtp_port`, `smtp_username`, `smtp_password`
3. Upload the contents of `backend/api/` to your server. Ensure `.htaccess` and `assets/qrcode.min.js` are uploaded.

## How the Pass System Works

1. When a visitor is registered, the API generates a unique 32-character random token and creates a pass URL: `https://<domain>/api/pass/<token>`.
2. If an email address is provided, the visitor receives an email with their pass link.
3. Opening the link renders a mobile-friendly pass page displaying their visit details and a QR code encoding `VMS:<id>`.
4. When the visitor arrives at the gate, security scans the QR code using the mobile app to verify and record check-in and check-out.

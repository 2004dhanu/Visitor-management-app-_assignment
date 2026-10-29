# Visitor Management App

A Flutter mobile application designed for front-desk and security teams to manage visitor registrations, issue digital QR passes, scan passes at gates, track real-time check-in/check-out status, and monitor daily visitor activity.

## Tech Stack & Versions

- Flutter: 3.47.1 (stable)
- Dart: 3.13.1
- State Management: flutter_riverpod (3.4.3)
- Networking: dio (^5.11.1)
- Navigation: go_router (18.1.1)
- QR Utilities: qr_flutter (4.1.0) & mobile_scanner (7.4.2)
- Target Platform: Android

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

The app accepts the backend API URL as a compile-time define:

```bash
flutter run --dart-define=API_BASE_URL=https://dy.solvyngroups.com/api/v1
```

If launched without `--dart-define`, the app shows an in-app setup screen prompting for the required configuration.

### 3. Build Release APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://dy.solvyngroups.com/api/v1
```

The output APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

### 4. Run Tests

```bash
flutter test
```

## Features

- **Dashboard:** Real-time summary metrics for Total Visitors Today, Checked In, and Checked Out, along with quick actions for registration and QR scanning.
- **Visitor Registration & Editing:** Validates visitor details (name, 10-digit mobile, visitor type, project, and purpose). Once registered, a digital pass is generated and emailed to the visitor.
- **Visitor Directory & Filtering:** Search visitors instantly by name or mobile number, with filters by project and status. Includes edit and delete actions with confirmation dialogs.
- **QR Pass & Gate Scanner:** Integrated camera scanner with real-time pass detection (`VMS:<id>`). Displays visitor details and enables one-tap check-in and check-out transitions.
- **Digital Pass Link:** Visitors can view their pass on their mobile browser via a secure token link. Completed visits automatically retire the pass.
- **Strict Status Flow:** Enforces sequential transitions: `Registered -> Checked In -> Checked Out`. Invalid actions are prevented in the UI and validated by the backend.
- **Theme Support:** Polished light and dark theme modes with consistent typography and responsive layouts.

## Project Structure

```
lib/
├── core/
│   ├── config/          # Environment configuration (API base URL)
│   ├── network/         # Dio HTTP client and typed failure models
│   ├── theme/           # App colors, typography, and theme definitions
│   └── utils/           # Date formatters and input validators
├── features/
│   └── visitors/
│       ├── data/        # Visitor models, QR payload helpers, repository
│       ├── screens/     # Dashboard, List, Form, Details, Scanner screens
│       ├── state/       # Riverpod providers and list state notifier
│       └── widgets/     # Reusable UI cards, chips, timelines, sparklines
├── routing/             # GoRouter setup with floating navigation bar shell
├── shared/widgets/      # Custom input fields, buttons, feedback snackbars, state views
└── main.dart            # App entry point and ProviderScope setup
```

## Backend API

A PHP REST API is provided in the `backend/` folder and deployed live at:
`https://dy.solvyngroups.com/api/v1`

Key endpoints:
- `GET /v1/health` - Health check
- `GET /v1/visitors` - Get all visitor records
- `POST /v1/visitors` - Register visitor and email pass link
- `GET /v1/visitors/{id}` - Lookup visitor
- `PUT /v1/visitors/{id}` - Update visitor
- `PATCH /v1/visitors/{id}` - Status update (check-in / check-out)
- `DELETE /v1/visitors/{id}` - Remove visitor record
- `POST /v1/visitors/{id}/send-pass` - Resend pass email
- `GET /pass/{token}` - Public web pass view

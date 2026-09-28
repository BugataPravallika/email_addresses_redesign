# Email Address Manager

A Flutter prototype for managing account email addresses and completing email
verification. The same app code runs on Android, iOS, and web. It uses Material
3, Flutter's built-in `ChangeNotifier`, and a local mock service; it does not
currently send real email or connect to a backend.

## Purpose

The app demonstrates the account email setup journey: add an address, receive a
six-digit verification code, enter the code, and see the verified status on the
email list. It also demonstrates loading, empty, network-error, and long-address
layouts.

## Features

- View a list of account email addresses with contact/office type and verified
   status.
- Add an address with format and case-insensitive duplicate validation.
- Open verification immediately after a successful add; the verification screen
   requests a code when it opens.
- Enter or paste a six-digit code, retry an incorrect code, request another code
   after the 60-second countdown, or change the address.
- Keep the Add action pinned while the email list scrolls.
- Show loading placeholders, retryable load errors, and an empty state.
- Use the top-right demo menu to switch sample data scenarios.
- Display compact email cards. The card shows verification status and, when
   applicable, a Primary badge. Unverified addresses have an inline Verify
   action. Set-primary and remove actions are not exposed in the current UI,
   although the service/controller APIs retain support for them.

## Demo Behavior

- The mock service accepts **123456**. Other six-digit codes are rejected.
- The mock service simulates network latency so loading and progress states can
   be seen.
- The demo menu provides Multiple emails, Single verified email, Single
   unverified email, Long email addresses, Empty state, and Network error
   scenarios. The network-error scenario fails its first fetch; retry succeeds.
- To try duplicate validation, add `customer@example.com` in the default
   scenario. The check is case-insensitive.
- Verification codes are simulated locally. No email is sent.

## Architecture

- `EmailRedesignApp` in `lib/main.dart` sets up the Material app, theme, mock
   service, controller, and demo scenario callback.
- `EmailAddress` in `lib/models/email_address.dart` is the immutable email data
   model. It stores the ID, address, type, verified state, and primary state.
- `EmailService` in `lib/services/email_service.dart` defines the boundary
   between app logic and data access. `MockEmailService` supplies local demo
   data and simulated operations.
- `EmailController` in `lib/state/email_controller.dart` owns list state,
   validation, loading/error state, verification updates, and email business
   rules. It notifies the UI through `ChangeNotifier`.
- `EmailAddressesScreen` and `VerifyEmailScreen` implement the list and OTP
   flows.
- Reusable UI components in `lib/widgets/` implement email cards, status and
   primary badges, the email form, OTP input, loading animation, and pinned
   action bar.
- `AppTheme` and `AppColors` in `lib/theme/app_theme.dart` define the Material 3
   theme and the blue, green, amber, and neutral color roles.

## Business Rules

- Email input is trimmed, checked for a valid format, and rejected if it
   duplicates an existing address (case-insensitive).
- Newly added or changed addresses start unverified and non-primary.
- A six-digit code is required for verification. In the mock service, only
   `123456` succeeds.
- The first successfully verified address becomes primary if no primary address
   exists. This rule is mirrored in the controller; a production backend should
   enforce it as the source of truth.
- `EmailService` includes `setPrimary` and `removeEmail` operations for future
   UI/backend use, but those actions are intentionally absent from the current
   email cards.

## Project Structure

```text
lib/
   config/       Demo scenarios and mock OTP configuration
   models/       Email address data model
   screens/      Email list and verification screens
   services/     Email service interface and mock implementation
   state/        Email controller and business rules
   theme/        App theme and color tokens
   widgets/      Reusable cards, forms, badges, OTP input, and action bar
android/        Android runner and resources
ios/            iOS runner and resources
web/            Web runner files
test/           Flutter widget tests
```

## Dependencies

There are no third-party runtime packages. Direct dependencies in
`pubspec.yaml` are:

- `flutter` from the Flutter SDK.
- `flutter_test` from the Flutter SDK for tests.
- `flutter_lints` for development lint rules.

The app uses Flutter/Dart libraries for widgets, navigation, clipboard access,
timers, state notifications, and data structures.

## Requirements and Commands

Use Flutter with Dart SDK 3.6 or newer. The Android, iOS, and web platform
folders are already included in this repository.

```bash
flutter pub get
flutter analyze lib
flutter test
```

Run on Chrome:

```bash
flutter run -d chrome
```

Run on an Android emulator or connected device:

```bash
flutter devices
flutter run -d <device-id>
```

Run on iOS Simulator (macOS only):

```bash
open -a Simulator
flutter run -d <device-id>
```

Build an Android APK:

```bash
flutter build apk
```

For a physical iPhone, configure signing in Xcode using
`ios/Runner.xcworkspace` before running the app.

## Tests

The project includes a widget smoke test in `test/widget_test.dart`. Its
expectations should be kept in sync with the current screen; in particular, the
app bar no longer displays the `Email addresses` title. Run tests with
`flutter test`.

## Backend Integration

To connect a real service:

1. Implement `EmailService` in a new API service class.
2. Implement fetching, adding, changing, sending/resending codes, verifying,
    setting primary, and removing addresses.
3. Translate transport/server failures to `NetworkException` and invalid or
    expired codes to `InvalidOtpException`.
4. Replace `MockEmailService` in `lib/main.dart` with the API implementation.
5. Remove the demo scenario callback and mock/demo configuration when they are
    no longer needed.
6. Enforce duplicate, verification, and primary-address rules on the server.

Until this integration is complete, all data and verification behavior are
local demo behavior only.

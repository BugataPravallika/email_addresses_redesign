# Email Addresses: UX redesign prototype (Flutter)

One shared Flutter codebase for Android and iOS. No third-party packages.
Material 3, `ChangeNotifier` for state, mock service for data.

## Run

The project ships `lib/`, `pubspec.yaml` and `analysis_options.yaml`. Generate the
platform folders once, then run:

```bash
flutter create --project-name email_addresses_redesign --platforms=android,ios email_addresses_redesign
# copy lib/, pubspec.yaml, analysis_options.yaml, README.md from the zip over the generated project
cd email_addresses_redesign
flutter pub get
flutter analyze
```

**Android:** start an emulator (or plug in a device with USB debugging), then `flutter run`.

**iOS (macOS only):** `open -a Simulator`, then `flutter run`. For a physical iPhone, open
`ios/Runner.xcworkspace` in Xcode, set a signing team, then `flutter run`.

Requires Flutter 3.27 or newer (uses `Color`/`TextScaler` APIs and Dart 3 switch expressions).

## Demo behaviour

* Demo OTP: **123456**. Any other 6-digit code shows the "incorrect code" state.
* Flask icon (top right) switches data: multiple, single verified, single unverified,
  long emails, empty, network error (fails once, then "Try again" works).
* Duplicate check is case-insensitive. Try adding `customer@example.com` again.

## Test checklist

1. Launch: skeleton loading, then 3 emails (verified+primary, not verified, verified).
2. Scenario menu > *Single verified email*: one card, "Verified" and "Primary".
3. Scenario menu > *Single unverified email*: "Not verified" and a visible **Verify email** button, no Primary badge.
4. Scenario menu > *Multiple emails*: compact cards, list scrolls, Add button stays pinned.
5. Tap **Verify email** on work@example.com: OTP screen opens, keyboard is numeric, first box focused.
6. Type digits: boxes fill, backspace removes the last digit, **Verify & Continue** enables at 6 digits.
7. Enter `111111` > Verify: spinner, then red boxes + error message, boxes cleared, refocused.
8. Enter `123456` > Verify: spinner, success screen. Tap **Done**: card now says Verified, button gone.
9. Countdown: pill counts down from 01:00; at 00:00 it becomes **Resend code** (disabled while counting). Tap it: new countdown + snackbar.
10. Copy `654321`, tap **Paste code**: all 6 boxes fill.
11. **Change email**: sheet prefilled, submit a new address: OTP screen shows it, new countdown starts, list shows the new address as unverified.
12. **Add another email**: submit empty (error), `abc` (format error), a duplicate (duplicate error), then `newemail@example.com`: loading, sheet closes, card slides in as Not verified with Verify button.
13. ⋮ on a verified non-primary email > **Set as primary**: badge moves. ⋮ on an unverified email: Set as primary is disabled ("Verify this email first").
14. ⋮ on the primary email with several emails: Remove is disabled ("Set another email as primary first"). Remove a non-primary email: confirm dialog, card disappears.
15. Scenario menu > *Empty state*, *Long email addresses*, *Network error*. Also try system font size at maximum.

## Connecting a real backend

1. Create `lib/services/api_email_service.dart` implementing `EmailService`
   (`fetchEmails`, `addEmail`, `updateEmail`, `sendVerificationCode`, `verifyCode`, `setPrimary`, `removeEmail`).
2. Map HTTP failures to `NetworkException` and a wrong/expired OTP to `InvalidOtpException`.
3. In `main.dart` replace `MockEmailService()` with your implementation and delete `onSelectScenario`.
4. Delete `lib/config/demo_config.dart` and `lib/services/mock_email_service.dart`, and remove the `_DemoHint` on the verification screen.
5. The server should be the source of truth for "first verified email becomes primary". The controller currently mirrors that rule locally.

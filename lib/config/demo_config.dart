/// Prototype-only configuration. Delete this file (and its usages) when a real
/// backend is connected.
library;

/// The one OTP the mock service accepts. Any other 6-digit code is rejected so
/// the "incorrect code" state can be demonstrated.
const String kDemoOtp = '123456';

/// Shows the "Prototype" hint on the verification screen.
const bool kShowDemoHints = true;

/// Data sets the reviewer can switch between from the app bar (flask icon).
enum DemoScenario {
  multiple('Multiple emails'),
  singleVerified('Single verified email'),
  singleUnverified('Single unverified email'),
  longEmail('Long email addresses'),
  empty('Empty state'),
  networkError('Network error (fails once)');

  const DemoScenario(this.label);
  final String label;
}

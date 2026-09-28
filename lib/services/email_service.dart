import '../models/email_address.dart';

/// Thrown when the network / API is unreachable or returns a server error.
class NetworkException implements Exception {
  const NetworkException([this.message = 'Something went wrong. Please try again.']);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when the submitted verification code is wrong or expired.
class InvalidOtpException implements Exception {
  const InvalidOtpException([this.message = "That code isn't correct. Please try again."]);
  final String message;
  @override
  String toString() => message;
}

/// API boundary. The UI and controller only know this interface.
///
/// To go live, implement it with your HTTP client (for example `ApiEmailService`)
/// and pass that into `EmailController` in `main.dart`.
abstract class EmailService {
  Future<List<EmailAddress>> fetchEmails();

  /// Creates an unverified, non-primary email.
  Future<EmailAddress> addEmail(String email);

  /// Replaces the address (used by "Change email"). The result is unverified.
  Future<EmailAddress> updateEmail(String id, String email);

  /// Sends (or re-sends) a 6-digit code to the email.
  Future<void> sendVerificationCode(String id);

  /// Throws [InvalidOtpException] for a wrong / expired code.
  Future<void> verifyCode(String id, String code);

  Future<void> setPrimary(String id);

  Future<void> removeEmail(String id);
}

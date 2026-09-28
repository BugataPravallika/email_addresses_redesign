import '../config/demo_config.dart';
import '../models/email_address.dart';
import 'email_service.dart';

/// Prototype implementation. No network, no real email is ever sent.
///
/// - Verification succeeds only with [kDemoOtp].
/// - Every call has artificial latency so loading states are visible.
class MockEmailService implements EmailService {
  DemoScenario _scenario = DemoScenario.multiple;
  bool _failNextFetch = false;
  int _idCounter = 100;

  /// Used by the prototype's scenario switcher.
  void useScenario(DemoScenario scenario) {
    _scenario = scenario;
    _failNextFetch = scenario == DemoScenario.networkError;
  }

  Future<void> _latency([int ms = 600]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  @override
  Future<List<EmailAddress>> fetchEmails() async {
    await _latency(700);
    if (_failNextFetch) {
      _failNextFetch = false; // "Try again" then succeeds.
      throw const NetworkException();
    }
    return switch (_scenario) {
      DemoScenario.singleVerified => const [
          EmailAddress(
            id: '1',
            email: 'customer@example.com',
            type: EmailType.contact,
            isVerified: true,
            isPrimary: true,
          ),
        ],
      DemoScenario.singleUnverified => const [
          EmailAddress(
            id: '1',
            email: 'work@example.com',
            type: EmailType.office,
          ),
        ],
      DemoScenario.longEmail => const [
          EmailAddress(
            id: '1',
            email:
                'customer.with.a.really.long.address.for.layout.testing@subdomain.example-company.co.in',
            type: EmailType.contact,
            isVerified: true,
            isPrimary: true,
          ),
          EmailAddress(
            id: '2',
            email:
                'averyveryverylongunbrokenemailaddressthatkeepsgoingandgoing1234567890@example.com',
            type: EmailType.office,
          ),
        ],
      DemoScenario.empty => const [],
      DemoScenario.multiple || DemoScenario.networkError => const [
          EmailAddress(
            id: '1',
            email: 'customer@example.com',
            type: EmailType.contact,
            isVerified: true,
            isPrimary: true,
          ),
          EmailAddress(
            id: '2',
            email: 'work@example.com',
            type: EmailType.office,
          ),
          EmailAddress(
            id: '3',
            email: 'personal@example.com',
            type: EmailType.office,
            isVerified: true,
          ),
        ],
    };
  }

  @override
  Future<EmailAddress> addEmail(String email) async {
    await _latency(900);
    return EmailAddress(
      id: 'new-${_idCounter++}',
      email: email,
      type: EmailType.office,
    );
  }

  @override
  Future<EmailAddress> updateEmail(String id, String email) async {
    await _latency(700);
    return EmailAddress(id: id, email: email, type: EmailType.office);
  }

  @override
  Future<void> sendVerificationCode(String id) => _latency(600);

  @override
  Future<void> verifyCode(String id, String code) async {
    await _latency(1000);
    if (code != kDemoOtp) throw const InvalidOtpException();
  }

  @override
  Future<void> setPrimary(String id) => _latency(500);

  @override
  Future<void> removeEmail(String id) => _latency(500);
}

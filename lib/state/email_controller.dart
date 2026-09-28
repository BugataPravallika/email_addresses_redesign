import 'package:flutter/foundation.dart';

import '../models/email_address.dart';
import '../services/email_service.dart';

enum LoadStatus { loading, ready, error }

/// Presentation-agnostic state + business rules for the email list.
///
/// Rules:
/// * Only a verified email can become primary.
/// * When an email is verified and no primary exists yet, it becomes primary.
/// * A primary email cannot be removed while other emails exist.
/// * Duplicate emails (case-insensitive) are rejected.
class EmailController extends ChangeNotifier {
  EmailController(this._service);

  final EmailService _service;

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$',
  );

  LoadStatus _status = LoadStatus.loading;
  List<EmailAddress> _emails = const [];
  final Set<String> _busyIds = {};

  LoadStatus get status => _status;
  List<EmailAddress> get emails => List.unmodifiable(_emails);
  int get unverifiedCount => _emails.where((e) => !e.isVerified).length;
  bool isBusy(String id) => _busyIds.contains(id);

  EmailAddress? byId(String id) {
    for (final e in _emails) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---- Business rules exposed to the UI ----

  bool canSetPrimary(EmailAddress e) => e.isVerified && !e.isPrimary;

  bool canRemove(EmailAddress e) => !(e.isPrimary && _emails.length > 1);

  /// Returns an error message, or null when [raw] is acceptable.
  String? validateEmail(String? raw, {String? excludeId}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter an email address.';
    if (!_emailPattern.hasMatch(value)) {
      return 'Enter a valid email address, like name@example.com.';
    }
    final duplicate = _emails.any(
      (e) => e.id != excludeId && e.email.toLowerCase() == value.toLowerCase(),
    );
    if (duplicate) return 'This email address is already on your account.';
    return null;
  }

  // ---- Actions ----

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _emails = await _service.fetchEmails();
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<EmailAddress> addEmail(String email) async {
    final created = await _service.addEmail(email.trim());
    _emails = [..._emails, created];
    notifyListeners();
    return created;
  }

  Future<void> changeEmail(String id, String email) async {
    final updated = await _service.updateEmail(id, email.trim());
    _update(id, (current) => updated.copyWith(type: current.type));
  }

  Future<void> sendCode(String id) => _service.sendVerificationCode(id);

  Future<void> verify(String id, String code) async {
    await _service.verifyCode(id, code);
    _update(id, (e) => e.copyWith(isVerified: true));

    // First verified email becomes the primary one.
    if (!_emails.any((e) => e.isPrimary)) {
      try {
        await _service.setPrimary(id);
        _update(id, (e) => e.copyWith(isPrimary: true));
      } catch (_) {
        // Verification already succeeded; the user can set primary manually.
      }
    }
  }

  Future<void> setPrimary(String id) async {
    final target = byId(id);
    if (target == null || !canSetPrimary(target)) return;
    await _runBusy(id, () async {
      await _service.setPrimary(id);
      _emails = [for (final e in _emails) e.copyWith(isPrimary: e.id == id)];
    });
  }

  Future<void> remove(String id) async {
    final target = byId(id);
    if (target == null || !canRemove(target)) return;
    await _runBusy(id, () async {
      await _service.removeEmail(id);
      _emails = _emails.where((e) => e.id != id).toList();
    });
  }

  // ---- Helpers ----

  void _update(String id, EmailAddress Function(EmailAddress) change) {
    _emails = [for (final e in _emails) e.id == id ? change(e) : e];
    notifyListeners();
  }

  Future<void> _runBusy(String id, Future<void> Function() task) async {
    _busyIds.add(id);
    notifyListeners();
    try {
      await task();
    } finally {
      _busyIds.remove(id);
      notifyListeners();
    }
  }
}

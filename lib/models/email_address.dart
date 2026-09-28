import 'package:flutter/foundation.dart';

/// One email address linked to the customer's account.
///
/// "Verified" (ownership confirmed) and "primary" (default address) are two
/// independent concepts. Business rules that relate them live in
/// `EmailController`, not here.
enum EmailType {
  contact('Contact email'),
  office('Office email');

  const EmailType(this.label);

  final String label;
}

@immutable
class EmailAddress {
  const EmailAddress({
    required this.id,
    required this.email,
    this.type = EmailType.office,
    this.isVerified = false,
    this.isPrimary = false,
  });

  final String id;
  final String email;
  final EmailType type;
  final bool isVerified;
  final bool isPrimary;

  EmailAddress copyWith({
    String? email,
    EmailType? type,
    bool? isVerified,
    bool? isPrimary,
  }) {
    return EmailAddress(
      id: id,
      email: email ?? this.email,
      type: type ?? this.type,
      isVerified: isVerified ?? this.isVerified,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EmailAddress &&
      other.id == id &&
      other.email == email &&
      other.type == type &&
      other.isVerified == isVerified &&
      other.isPrimary == isPrimary;

  @override
  int get hashCode => Object.hash(id, email, type, isVerified, isPrimary);
}

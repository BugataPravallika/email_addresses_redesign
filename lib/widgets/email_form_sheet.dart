import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/email_service.dart';
import '../state/email_controller.dart';
import '../theme/app_theme.dart';

/// Bottom sheet with a single email field. Used for both "Add another email"
/// and "Change email" (during verification) so validation and behaviour are
/// identical.
///
/// Resolves with the submitted email, or null when dismissed.
class EmailFormSheet extends StatefulWidget {
  const EmailFormSheet({
    super.key,
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onSubmit,
    this.initialEmail,
    this.excludeId,
  });

  final EmailController controller;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String? initialEmail;

  /// Email id ignored by the duplicate check (the one being edited).
  final String? excludeId;

  /// Performs the API call. Throw [NetworkException] to show an inline error.
  final Future<void> Function(String email) onSubmit;

  static Future<String?> show(
    BuildContext context, {
    required EmailController controller,
    required String title,
    required String subtitle,
    required String actionLabel,
    required Future<void> Function(String email) onSubmit,
    String? initialEmail,
    String? excludeId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EmailFormSheet(
        controller: controller,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onSubmit: onSubmit,
        initialEmail: initialEmail,
        excludeId: excludeId,
      ),
    );
  }

  @override
  State<EmailFormSheet> createState() => _EmailFormSheetState();
}

class _EmailFormSheetState extends State<EmailFormSheet> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initialEmail);
  final FocusNode _focus = FocusNode();
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Select the prefilled address so "Change email" is one paste/typing away.
    _text.selection =
        TextSelection(baseOffset: 0, extentOffset: _text.text.length);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return; // Prevent duplicate submissions.
    final email = _text.text.trim();
    final error =
        widget.controller.validateEmail(email, excludeId: widget.excludeId);
    if (error != null) {
      setState(() => _error = error);
      _focus.requestFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(email);
      if (!mounted) return;
      Navigator.of(context).pop(email);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Keeps the button above the keyboard, or above the home indicator.
    final bottom =
        math.max(media.viewInsets.bottom, media.viewPadding.bottom) + 16;

    OutlineInputBorder border(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _text,
            focusNode: _focus,
            autofocus: true,
            readOnly: _submitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'name@example.com',
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              errorText: _error,
              errorMaxLines: 3,
              filled: true,
              fillColor: AppColors.background,
              border: border(AppColors.outline),
              enabledBorder: border(const Color(0xFFCBD1DC)),
              focusedBorder: border(AppColors.brand, 2),
              errorBorder: border(AppColors.danger),
              focusedErrorBorder: border(AppColors.danger, 2),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

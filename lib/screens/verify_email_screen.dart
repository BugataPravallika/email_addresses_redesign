import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/email_service.dart';
import '../state/email_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/email_form_sheet.dart';
import '../widgets/otp_input.dart';
import '../widgets/status_chip.dart';

enum _Phase { entry, verifying, success }

/// Dedicated screen for entering the 6-digit code. Pops with `true` once the
/// user taps "Done" after a successful verification. The list screen has
/// already updated by then because both share [EmailController].
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.controller,
    required this.emailId,
  });

  final EmailController controller;
  final String emailId;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _codeLength = 6;
  static const _resendSeconds = 60;

  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();

  Timer? _timer;
  int _secondsLeft = 0;
  bool _sending = false;
  _Phase _phase = _Phase.entry;
  String? _error;
  late String _email;

  @override
  void initState() {
    super.initState();
    _email = widget.controller.byId(widget.emailId)?.email ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ---- Actions ----

  Future<void> _requestCode({bool resend = false}) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.controller.sendCode(widget.emailId);
      if (!mounted) return;
      _startCountdown();
      if (resend) {
        _code.clear();
        _focus.requestFocus();
        _snack('A new code was sent to $_email');
      }
    } catch (_) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _secondsLeft = 0;
        _error = "We couldn't send the code. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft = math.max(0, _secondsLeft - 1));
      if (_secondsLeft == 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_phase == _Phase.verifying) return; // Prevent duplicate submissions.
    if (_code.text.length != _codeLength) {
      setState(() => _error = 'Enter all $_codeLength digits.');
      return;
    }
    setState(() {
      _phase = _Phase.verifying;
      _error = null;
    });
    try {
      await widget.controller.verify(widget.emailId, _code.text);
      if (!mounted) return;
      _timer?.cancel();
      FocusScope.of(context).unfocus();
      setState(() => _phase = _Phase.success);
    } on InvalidOtpException catch (e) {
      if (!mounted) return;
      _code.clear();
      setState(() {
        _phase = _Phase.entry;
        _error = e.message;
      });
      _focus.requestFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.entry;
        _error =
            "We couldn't verify the code. Check your connection and try again.";
      });
    }
  }

  Future<void> _changeEmail() async {
    final updated = await EmailFormSheet.show(
      context,
      controller: widget.controller,
      title: 'Change email address',
      subtitle: "We'll send a new code to this address.",
      actionLabel: 'Send new code',
      initialEmail: _email,
      excludeId: widget.emailId,
      onSubmit: (value) => widget.controller.changeEmail(widget.emailId, value),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _email = updated;
      _error = null;
    });
    _code.clear();
    _requestCode();
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || !mounted) return;
    _code.text = digits.substring(0, math.min(_codeLength, digits.length));
    setState(() => _error = null);
    _focus.requestFocus();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final success = _phase == _Phase.success;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: success
                    ? _SuccessView(
                        key: const ValueKey('success'), email: _email)
                    : _buildEntry(context),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: success
            ? FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Done'),
              )
            : FilledButton(
                onPressed: _code.text.length == _codeLength ? _verify : null,
                child: _phase == _Phase.verifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Verify & Continue'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final verifying = _phase == _Phase.verifying;

    return Column(
      key: const ValueKey('entry'),
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.brandTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_unread_outlined,
              size: 34, color: AppColors.brand),
        ),
        const SizedBox(height: 20),
        Text(
          'Verify your email',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 2),
        Text(
          _email,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 28),
        OtpInput(
          controller: _code,
          focusNode: _focus,
          length: _codeLength,
          hasError: _error != null,
          enabled: !verifying,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _verify(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.error_outline_rounded,
                              size: 18, color: AppColors.danger),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _error!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            if (_secondsLeft > 0)
              _CountdownPill(seconds: _secondsLeft)
            else
              TextButton.icon(
                onPressed: (_sending || verifying)
                    ? null
                    : () => _requestCode(resend: true),
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Resend code'),
              ),
            TextButton.icon(
              onPressed: verifying ? null : _pasteCode,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Paste code'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              "Didn't receive the email?",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
            children: [
              Text(
                'Check your spam folder or request a new code.',
                style:
                    textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: verifying ? null : _changeEmail,
          child: const Text('Change email'),
        ),
      ],
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    // Not a live region on purpose: announcing every second would be noise.
    return Semantics(
      label: 'You can request a new code in $seconds seconds',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text.rich(
          TextSpan(
            text: 'Resend code in ',
            children: [
              TextSpan(
                text: '$mm:$ss',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 15, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: 32),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.successTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 56, color: AppColors.success),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          child: Text(
            'Email verified',
            textAlign: TextAlign.center,
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        const StatusChip.verified(),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// 6 visual boxes driven by ONE invisible [TextField].
///
/// Why: a single field gives reliable backspace, paste, keyboard "done" and
/// iOS/Android one-time-code autofill for free, while the boxes stay purely
/// presentational (no per-box focus juggling).
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    // Always keep the caret at the end so backspace removes the last digit.
    final length = widget.controller.text.length;
    if (widget.controller.selection.baseOffset != length) {
      widget.controller.selection = TextSelection.collapsed(offset: length);
    }
    _rebuild();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = widget.focusNode.hasFocus;
    final activeIndex = text.length.clamp(0, widget.length - 1);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final boxWidth = ((constraints.maxWidth - gap * (widget.length - 1)) /
                widget.length)
            .clamp(36.0, 56.0);
        final boxHeight = boxWidth * 1.25;

        final boxes = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: boxWidth,
                height: boxHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: widget.hasError || (focused && i == activeIndex)
                        ? 2
                        : 1.2,
                    color: widget.hasError
                        ? AppColors.danger
                        : (focused && i == activeIndex)
                            ? AppColors.brand
                            : const Color(0xFFCBD1DC),
                  ),
                ),
                child: Text(
                  i < text.length ? text[i] : '',
                  textScaler: scaler,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ],
        );

        return Stack(
          children: [
            ExcludeSemantics(child: boxes),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: true,
                  readOnly: !widget.enabled,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: InputDecoration(
                    labelText: '${widget.length}-digit verification code',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

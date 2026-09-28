import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Verification status pill. Always icon + text, never colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip.verified({super.key})
      : label = 'Verified',
        icon = Icons.check_circle_rounded,
        foreground = AppColors.success,
        background = AppColors.successTint;

  const StatusChip.notVerified({super.key})
      : label = 'Not verified',
        icon = Icons.error_outline_rounded,
        foreground = AppColors.warning,
        background = AppColors.warningTint;

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Primary" marker. Deliberately a different colour AND shape (outlined,
/// indigo, star) from [StatusChip] (filled, green/amber) so the two concepts
/// are never confused.
class PrimaryBadge extends StatelessWidget {
  const PrimaryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 16, color: AppColors.brand),
            SizedBox(width: 4),
            Text(
              'Primary',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

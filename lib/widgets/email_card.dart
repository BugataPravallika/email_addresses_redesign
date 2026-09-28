import 'package:flutter/material.dart';

import '../models/email_address.dart';
import '../theme/app_theme.dart';
import 'primary_badge.dart';
import 'status_chip.dart';

/// Compact email row with status at the top-right and actions in the footer.
class EmailCard extends StatelessWidget {
  const EmailCard({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onMore,
    this.isBusy = false,
  });

  final EmailAddress email;
  final VoidCallback onVerify;
  final VoidCallback onMore;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final verified = email.isVerified;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: email.isPrimary ? AppColors.brand : AppColors.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LeadingIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.type.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email.email,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: verified
                        ? const StatusChip.verified(key: ValueKey('verified'))
                        : const StatusChip.notVerified(
                            key: ValueKey('not-verified'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (email.isPrimary) const PrimaryBadge(),
                  const Spacer(),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: isBusy
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.more_horiz_rounded),
                            tooltip: 'More actions for ${email.email}',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            onPressed: onMore,
                          ),
                  ),
                  if (!verified) ...[
                    const SizedBox(width: 4),
                    FilledButton.tonalIcon(
                      onPressed: isBusy ? null : onVerify,
                      icon:
                          const Icon(Icons.mark_email_read_outlined, size: 16),
                      label: const Text('Verify email'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.mail_outline_rounded,
        size: 22,
        color: AppColors.brand,
      ),
    );
  }
}

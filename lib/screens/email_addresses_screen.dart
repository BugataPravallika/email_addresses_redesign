import 'package:flutter/material.dart';

import '../config/demo_config.dart';
import '../models/email_address.dart';
import '../services/email_service.dart';
import '../state/email_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/appear_animation.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/email_card.dart';
import '../widgets/email_form_sheet.dart';
import '../widgets/primary_badge.dart';
import '../widgets/status_chip.dart';
import 'verify_email_screen.dart';

enum _EmailAction { verify, setPrimary, remove }

class EmailAddressesScreen extends StatelessWidget {
  const EmailAddressesScreen({
    super.key,
    required this.controller,
    this.onSelectScenario,
  });

  final EmailController controller;

  /// Prototype-only: lets a reviewer switch demo data. Null hides the menu.
  final ValueChanged<DemoScenario>? onSelectScenario;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ready = controller.status == LoadStatus.ready;
        final empty = controller.emails.isEmpty;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (onSelectScenario != null)
                _DemoMenu(onSelected: onSelectScenario!),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: switch (controller.status) {
              LoadStatus.loading => const _LoadingList(),
              LoadStatus.error => _ErrorState(onRetry: () => controller.load()),
              LoadStatus.ready => empty
                  ? const _EmptyState()
                  : _EmailList(
                      controller: controller,
                      onAddEmail: () => _addEmail(context),
                      onVerify: (e) => _openVerify(context, e),
                      onMore: (e) => _showActions(context, e),
                    ),
            },
          ),
          bottomNavigationBar: ready
              ? BottomActionBar(
                  child: empty
                      ? _EmptyAction(onAdd: () => _addEmail(context))
                      : FilledButton.icon(
                          onPressed: () => _addEmail(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add another email'),
                        ),
                )
              : null,
        );
      },
    );
  }

  // ---- Flows ----

  Future<void> _addEmail(BuildContext context) async {
    EmailAddress? createdEmail;
    final added = await EmailFormSheet.show(
      context,
      controller: controller,
      title: 'Add email address',
      subtitle: "We'll ask you to verify it with a 6-digit code.",
      actionLabel: 'Add email address',
      onSubmit: (email) async {
        createdEmail = await controller.addEmail(email);
      },
    );
    if (added == null || !context.mounted) return;
    final email = createdEmail;
    if (email != null) await _openVerify(context, email);
  }

  Future<void> _openVerify(BuildContext context, EmailAddress email) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            VerifyEmailScreen(controller: controller, emailId: email.id),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, EmailAddress email) async {
    final action = await showModalBottomSheet<_EmailAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActionsSheet(
        email: email,
        canSetPrimary: controller.canSetPrimary(email),
        canRemove: controller.canRemove(email),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _EmailAction.verify:
        await _openVerify(context, email);
      case _EmailAction.setPrimary:
        await _guard(context, () async {
          await controller.setPrimary(email.id);
          if (context.mounted) {
            _snack(context, '${email.email} is now your primary email.');
          }
        });
      case _EmailAction.remove:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Remove email?'),
            content: Text('${email.email} will be removed from your account.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(88, 48),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await _guard(context, () async {
          await controller.remove(email.id);
          if (context.mounted) _snack(context, '${email.email} was removed.');
        });
    }
  }

  Future<void> _guard(
      BuildContext context, Future<void> Function() task) async {
    try {
      await task();
    } on NetworkException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Something went wrong. Please try again.');
      }
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ---------------------------------------------------------------------------

class _EmailList extends StatelessWidget {
  const _EmailList({
    required this.controller,
    required this.onAddEmail,
    required this.onVerify,
    required this.onMore,
  });

  final EmailController controller;
  final VoidCallback onAddEmail;
  final ValueChanged<EmailAddress> onVerify;
  final ValueChanged<EmailAddress> onMore;

  @override
  Widget build(BuildContext context) {
    final emails = controller.emails;
    Widget card(EmailAddress email) => Padding(
          key: ValueKey(email.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: AppearAnimation(
            child: EmailCard(
              email: email,
              isBusy: controller.isBusy(email.id),
              onVerify: () => onVerify(email),
              onMore: () => onMore(email),
            ),
          ),
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _ListHeader(
                count: emails.length, unverified: controller.unverifiedCount),
            const SizedBox(height: 16),
            for (final email in emails) card(email),
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.count, required this.unverified});

  final int count;
  final int unverified;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage the emails linked to your account.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$count ${count == 1 ? 'email' : 'emails'}',
                style:
                    textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (unverified > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '$unverified ${unverified == 1 ? 'needs' : 'need'} verification',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({
    required this.email,
    required this.canSetPrimary,
    required this.canRemove,
  });

  final EmailAddress email;
  final bool canSetPrimary;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                  const SizedBox(height: 2),
                  Text(
                    email.email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (email.isVerified)
                        const StatusChip.verified()
                      else
                        const StatusChip.notVerified(),
                      if (email.isPrimary) const PrimaryBadge(),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (!email.isVerified)
              ListTile(
                leading: const Icon(Icons.mark_email_read_outlined),
                title: const Text('Verify email'),
                onTap: () => Navigator.of(context).pop(_EmailAction.verify),
              ),
            if (!email.isPrimary)
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('Set as primary'),
                subtitle: email.isVerified
                    ? null
                    : const Text('Verify this email first'),
                enabled: canSetPrimary,
                onTap: () => Navigator.of(context).pop(_EmailAction.setPrimary),
              ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: canRemove ? AppColors.danger : null,
              ),
              title: Text(
                'Remove email',
                style: TextStyle(color: canRemove ? AppColors.danger : null),
              ),
              subtitle: canRemove
                  ? null
                  : const Text('Set another email as primary first'),
              enabled: canRemove,
              onTap: () => Navigator.of(context).pop(_EmailAction.remove),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DemoMenu extends StatelessWidget {
  const _DemoMenu({required this.onSelected});

  final ValueChanged<DemoScenario> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DemoScenario>(
      icon: const Icon(Icons.science_outlined),
      tooltip: 'Prototype: switch demo scenario',
      onSelected: onSelected,
      itemBuilder: (_) => [
        const PopupMenuItem<DemoScenario>(
          enabled: false,
          child: Text('PROTOTYPE SCENARIOS'),
        ),
        const PopupMenuDivider(),
        for (final s in DemoScenario.values)
          PopupMenuItem<DemoScenario>(value: s, child: Text(s.label)),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFF3),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Semantics(
      label: 'Loading email addresses',
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFF3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(180, 14),
                          const SizedBox(height: 10),
                          bar(96, 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  size: 36,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Add your email address',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  'We use it to verify your identity and help secure your account.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'EMAIL PREVIEW',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _EmailPreviewCard(),
              const SizedBox(height: 24),
              _JourneySteps(textTheme: textTheme),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 17,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Never share your verification code with anyone.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailPreviewCard extends StatelessWidget {
  const _EmailPreviewCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mail_outline_rounded,
                color: AppColors.brand,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Office email',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'you@company.com',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const StatusChip.verified(),
          ],
        ),
      ),
    );
  }
}

class _EmptyAction extends StatelessWidget {
  const _EmptyAction({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add email address'),
          ),
        ),
        Text(
          'You can do this later from Profile.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
        ),
      ],
    );
  }
}

class _JourneySteps extends StatelessWidget {
  const _JourneySteps({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.add_circle_outline_rounded, 'Add email'),
      (Icons.mark_email_unread_outlined, 'Get code'),
      (Icons.verified_outlined, 'Verified'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 14),
                child: Divider(color: AppColors.outline, height: 1),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Icon(steps[index].$1, color: AppColors.brand, size: 26),
                const SizedBox(height: 7),
                Text(
                  steps[index].$2,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Placeholder for API failures. `onRetry` re-runs the load call.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.inkMuted),
            const SizedBox(height: 16),
            Text(
              "Couldn't load your emails",
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';

/// Empty states invite the next action; they never just say "no data".
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primaryContainer,
                ),
                child: Icon(icon, size: 36, color: c.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.headingMd,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.text.bodyMd.copyWith(color: c.textSecondary),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  isFullWidth: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error states explain what happened and how to get out of it.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: context.l10n.stateErrorTitle,
    message: message,
    actionLabel: context.l10n.commonRetry,
    onAction: onRetry,
  );
}

/// Square social provider button from the sign-in reference.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    required this.icon,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final Widget icon;
  final String provider;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = context.l10n.stateSocialContinueWith(provider);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            height: AppSizes.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: isLoading
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.textSecondary,
                        )
                      : icon,
                ),
                const SizedBox(width: AppSpacing.base),
                Text(
                  label,
                  style: context.text.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

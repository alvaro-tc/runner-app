import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/core/utils/validators.dart';
import 'package:camrun/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    setState(() => _error = Validators.email(t, _email.text));
    if (_error != null) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return AuthScaffold(
      children: [
        Text(t.authForgotTitle, style: context.text.displayMd),
        const SizedBox(height: AppSpacing.md),
        Text(
          _sent ? t.authForgotSent(_email.text.trim()) : t.authForgotIntro,
          style: context.text.bodyMd.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (!_sent) ...[
          AppTextField(
            label: t.authEmailLabel,
            controller: _email,
            hint: t.authEmailHint,
            errorText: _error,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: t.authSendResetLink,
            isLoading: _loading,
            onPressed: _submit,
          ),
        ] else
          AppButton(
            label: t.authSendAgain,
            variant: AppButtonVariant.secondary,
            onPressed: () => setState(() => _sent = false),
          ),
      ],
    );
  }
}

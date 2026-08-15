import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/core/utils/validators.dart';
import 'package:paceup/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';

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
    setState(() => _error = Validators.email(_email.text));
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
    return AuthScaffold(
      children: [
        Text('Reset your\npassword.', style: context.text.displayMd),
        const SizedBox(height: AppSpacing.md),
        Text(
          _sent
              ? 'Check ${_email.text.trim()}. The link works for one hour; '
                    'request another if it expires.'
              : 'Give us the email on your account and we will send a link to '
                    'set a new password.',
          style: context.text.bodyMd.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (!_sent) ...[
          AppTextField(
            label: 'Email',
            controller: _email,
            hint: 'pandu@paceup.app',
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
            label: 'Send reset link',
            isLoading: _loading,
            onPressed: _submit,
          ),
        ] else
          AppButton(
            label: 'Send it again',
            variant: AppButtonVariant.secondary,
            onPressed: () => setState(() => _sent = false),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paceup/app/router/app_routes.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/core/utils/validators.dart';
import 'package:paceup/features/auth/presentation/providers/auth_provider.dart';
import 'package:paceup/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';
import 'package:paceup/shared/widgets/molecules/states.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  String? _identifierError;
  String? _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _identifierError = Validators.identifier(_identifier.text);
      _passwordError = Validators.password(_password.text);
    });
    if (_identifierError != null || _passwordError != null) return;

    setState(() => _loading = true);
    final failure = await ref
        .read(authProvider.notifier)
        .signIn(_identifier.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (failure != null) {
      setState(() => _passwordError = failure.message);
      return;
    }
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AuthScaffold(
      children: [
        Text("Let's Sign you in.", style: context.text.displayMd),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Welcome back',
          style: context.text.headingMd.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
        Text(
          "You've been missed!",
          style: context.text.headingMd.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: 'Username or Email',
          controller: _identifier,
          hint: 'pandu@paceup.app',
          errorText: _identifierError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          onChanged: (_) {
            if (_identifierError != null) {
              setState(() => _identifierError = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Password',
          controller: _password,
          hint: 'At least 8 characters',
          errorText: _passwordError,
          isPassword: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(Routes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const AuthDivider(),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialAuthButton(
              icon: Icons.g_mobiledata_rounded,
              provider: 'Google',
              onPressed: () => context.showSnack(
                'Google sign-in is coming soon. Use your email for now.',
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            SocialAuthButton(
              icon: Icons.work_outline_rounded,
              provider: 'LinkedIn',
              onPressed: () => context.showSnack(
                'LinkedIn sign-in is coming soon. Use your email for now.',
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            SocialAuthButton(
              icon: Icons.facebook_rounded,
              provider: 'Facebook',
              onPressed: () => context.showSnack(
                'Facebook sign-in is coming soon. Use your email for now.',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
            TextButton(
              onPressed: () => context.pushReplacement(Routes.signUp),
              child: const Text('Register'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Login', isLoading: _loading, onPressed: _submit),
      ],
    );
  }
}

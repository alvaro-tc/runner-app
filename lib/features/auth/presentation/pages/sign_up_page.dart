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
import 'package:paceup/shared/widgets/atoms/app_indicators.dart';
import 'package:paceup/shared/widgets/atoms/app_text_field.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _name = TextEditingController();
  final _ci = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _errors = <String, String?>{};
  bool _acceptedTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _ci.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    setState(() {
      _errors
<<<<<<< HEAD
        ..['name'] = Validators.required(
          _name.text,
          t.validationFullNameRequired,
        )
        ..['email'] = Validators.email(t, _email.text)
        ..['password'] = Validators.password(t, _password.text)
=======
        ..['name'] = Validators.required(_name.text, 'full name')
        ..['ci'] = Validators.ci(_ci.text)
        // El correo es opcional: solo se valida si escribio algo. Exigirlo
        // dejaria fuera a quien no tiene, que es justo a quien hay que dejar
        // inscribirse.
        ..['email'] = _email.text.trim().isEmpty
            ? null
            : Validators.email(_email.text)
        ..['password'] = Validators.password(_password.text)
>>>>>>> main
        ..['confirm'] = Validators.confirmPassword(
          t,
          _confirm.text,
          _password.text,
        );
    });
    if (_errors.values.any((e) => e != null)) return;
    if (!_acceptedTerms) {
      context.showSnack(t.authAcceptTermsRequired);
      return;
    }

    setState(() => _loading = true);
    final failure = await ref
        .read(authProvider.notifier)
        .signUp(
          name: _name.text.trim(),
          password: _password.text,
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          ci: _ci.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (failure != null) {
      setState(() => _errors['password'] = failure.message);
      return;
    }
    context.go(Routes.home);
  }

  void _clear(String key) {
    if (_errors[key] != null) setState(() => _errors[key] = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return AuthScaffold(
      children: [
        Text(t.authSignUpTitle, style: context.text.displayMd),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.authSignUpSubtitle,
          style: context.text.bodyMd.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: t.authFullNameLabel,
          controller: _name,
          hint: t.authFullNameHint,
          errorText: _errors['name'],
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => _clear('name'),
        ),
        const SizedBox(height: AppSpacing.lg),
        // La CI es la credencial que vale en las dos puntas: con ella entras a
        // la app y con ella la web reconoce un pago tuyo hecho fuera de aqui.
        AppTextField(
<<<<<<< HEAD
          label: t.authEmailLabel,
=======
          label: 'ID number (CI)',
          controller: _ci,
          hint: '1234567 LP',
          errorText: _errors['ci'],
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          onChanged: (_) => _clear('ci'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Email (optional)',
>>>>>>> main
          controller: _email,
          hint: t.authEmailHint,
          errorText: _errors['email'],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => _clear('email'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Without it we cannot email you a password reset link, so keep your '
          'ID number to hand.',
          style: context.text.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: t.authPasswordLabel,
          controller: _password,
          hint: t.authPasswordHint,
          errorText: _errors['password'],
          isPassword: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => _clear('password'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: t.authConfirmPasswordLabel,
          controller: _confirm,
          hint: t.authConfirmPasswordHint,
          errorText: _errors['confirm'],
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) => _clear('confirm'),
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            AppCheckbox(
              value: _acceptedTerms,
              semanticsLabel: t.authAcceptTermsSemantics,
              onChanged: (v) => setState(() => _acceptedTerms = v),
            ),
            Expanded(
              child: Text(
                t.authAcceptTerms,
                style: context.text.bodySm.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: t.authCreateAccount,
          isLoading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.authHaveAccount,
              style: context.text.bodyMd.copyWith(color: c.textSecondary),
            ),
            TextButton(
              onPressed: () => context.pushReplacement(Routes.signIn),
              child: Text(t.authLogin),
            ),
          ],
        ),
      ],
    );
  }
}

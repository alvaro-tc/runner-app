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

/// Cambio obligatorio de contrasena.
///
/// La ve quien se inscribio desde la web: ahi la cuenta se crea con **usuario
/// CI y contrasena CI**, que es una clave que sabe cualquiera que le haya visto
/// el carnet. El guard no deja salir de esta pantalla hasta que la cambie, y
/// por eso no hay boton de "ahora no": un "ahora no" sobre una contrasena
/// publica es no cambiarla nunca.
///
/// Tampoco hay boton de volver. La unica salida lateral es cerrar sesion.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  final _errors = <String, String?>{};
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errors
        ..['current'] = Validators.required(_current.text, 'current password')
        ..['next'] = Validators.password(_next.text)
        ..['confirm'] = Validators.confirmPassword(_confirm.text, _next.text);
    });
    if (_errors.values.any((e) => e != null)) return;

    setState(() => _loading = true);
    final failure = await ref
        .read(authProvider.notifier)
        .changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (failure != null) {
      setState(() => _errors['current'] = failure.message);
      return;
    }

    // El guard ya dejo de bloquear al cambiar el estado; esto solo evita
    // quedarse mirando el formulario ya enviado.
    context.go(Routes.home);
  }

  void _clear(String key) {
    if (_errors[key] != null) setState(() => _errors[key] = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AuthScaffold(
      children: [
        Text('Choose your\npassword.', style: context.text.displayMd),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your account was created with your ID number as both the username '
          'and the password. Anyone who has seen your ID knows it, so pick a '
          'new one before you go on.',
          style: context.text.bodyMd.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: 'Current password',
          controller: _current,
          hint: 'Your ID number, if nobody changed it',
          errorText: _errors['current'],
          isPassword: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clear('current'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'New password',
          controller: _next,
          hint: 'At least 8 characters, with a letter and a number',
          errorText: _errors['next'],
          isPassword: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => _clear('next'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Confirm new password',
          controller: _confirm,
          hint: 'Type it once more',
          errorText: _errors['confirm'],
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) => _clear('confirm'),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Save and continue',
          isLoading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Sign out',
          variant: AppButtonVariant.ghost,
          onPressed: () => ref.read(authProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

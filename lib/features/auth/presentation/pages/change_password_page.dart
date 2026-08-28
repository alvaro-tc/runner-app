import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/core/utils/validators.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final t = context.l10n;
    setState(() {
      _errors
        ..['current'] = Validators.required(
          _current.text,
          t.validationCurrentPasswordRequired,
        )
        ..['next'] = Validators.password(t, _next.text)
        ..['confirm'] = Validators.confirmPassword(
          t,
          _confirm.text,
          _next.text,
        );
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
    final t = context.l10n;

    return AuthScaffold(
      children: [
        Text(t.changePasswordTitle, style: context.text.displayMd),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.changePasswordBody,
          style: context.text.bodyMd.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: t.changePasswordCurrentLabel,
          controller: _current,
          hint: t.changePasswordCurrentHint,
          errorText: _errors['current'],
          isPassword: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clear('current'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: t.changePasswordNewLabel,
          controller: _next,
          hint: t.changePasswordNewHint,
          errorText: _errors['next'],
          isPassword: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => _clear('next'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: t.changePasswordConfirmLabel,
          controller: _confirm,
          hint: t.changePasswordConfirmHint,
          errorText: _errors['confirm'],
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) => _clear('confirm'),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: t.changePasswordSubmit,
          isLoading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: t.profileLogOut,
          variant: AppButtonVariant.ghost,
          onPressed: () => ref.read(authProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

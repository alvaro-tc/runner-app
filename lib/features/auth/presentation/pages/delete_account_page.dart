import 'package:camrun/core/constants/legal_urls.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/core/utils/validators.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/atoms/app_icon_button.dart';
import 'package:camrun/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Borrado de cuenta. Google Play y App Store exigen que se pueda pedir desde
/// dentro de la app, no solo escribiendo a soporte.
///
/// Son dos puertas a proposito: la contrasena —que la cuenta la borre su dueno
/// y no quien coja el telefono desbloqueado— y un dialogo de confirmacion, por
/// lo que se pierde. No hay deshacer.
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool conPassword}) async {
    final t = context.l10n;
    if (conPassword) {
      setState(
        () => _error = Validators.required(
          _password.text,
          t.validationCurrentPasswordRequired,
        ),
      );
      if (_error != null) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteAccountConfirmTitle),
        content: Text(t.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              t.deleteAccountConfirmAction,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _loading = true);
    final failure = await ref
        .read(authProvider.notifier)
        .deleteAccount(conPassword ? _password.text : null);
    if (!mounted) return;
    setState(() => _loading = false);

    // Si salio bien la sesion ya cayo y el guard se lleva la pantalla por
    // delante: solo hay que pintar el error del caso contrario.
    if (failure != null) setState(() => _error = failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final conPassword = ref.watch(authProvider).hasPassword;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsLabel: t.commonBack,
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(t.deleteAccountTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          Text(
            t.deleteAccountBody,
            style: context.text.bodyMd.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(t.deleteAccountWhatGoes, style: context.text.bodyMd),
          const SizedBox(height: AppSpacing.xl),
          // Las cuentas de Google no tienen contrasena que confirmar: el
          // dialogo sigue estando, que es lo que hace irreversible al boton.
          if (conPassword)
            AppTextField(
              label: t.deleteAccountPasswordLabel,
              controller: _password,
              hint: t.deleteAccountPasswordHint,
              errorText: _error,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(conPassword: true),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            )
          else ...[
            Text(
              t.deleteAccountNoPassword,
              style: context.text.bodySm.copyWith(color: c.textSecondary),
            ),
            if (_error != null)
              Text(
                _error!,
                style: context.text.bodySm.copyWith(color: c.error),
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: t.deleteAccountSubmit,
            variant: AppButtonVariant.danger,
            isLoading: _loading,
            onPressed: () => _submit(conPassword: conPassword),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(t.deleteAccountWebTitle, style: context.text.headingMd),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.deleteAccountWebBody,
            style: context.text.bodySm.copyWith(color: c.textSecondary),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.openExternal(LegalUrls.deleteAccount),
              child: Text(t.deleteAccountWebOpen, style: context.text.bodySm),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:flutter/material.dart';

/// La sala de espera de una maraton que esta a punto de largar.
///
/// **Es toda la app mientras dura.** No tiene barra de navegacion, ni boton de
/// atras, ni nada que tocar: el organizador cerro el kiosko y a partir de ese
/// momento lo unico que el corredor necesita saber esta escrito aqui. Dejar la
/// app viva por debajo significaria que alguien cambia su categoria, cancela su
/// inscripcion o arranca un entrenamiento con el arco montado delante.
class MarathonPreparingPage extends StatelessWidget {
  const MarathonPreparingPage({required this.entry, this.message, super.key});

  final RaceEntry entry;

  /// Lo que escribio el organizador. Vacio o `null` = el texto por defecto, que
  /// sale del ARB y llega en el idioma del corredor.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final aviso = message?.trim();

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.hourglass_top_rounded, size: 64, color: c.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  t.marathonPreparingTitle,
                  textAlign: TextAlign.center,
                  style: context.text.headingLg,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  entry.marathon.name,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMd.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    aviso == null || aviso.isEmpty
                        ? t.marathonPreparingDefault
                        : aviso,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMd,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Dorsal(bib: entry.bibNumber),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  t.marathonPreparingHint,
                  textAlign: TextAlign.center,
                  style: context.text.bodySm.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El dorsal, grande. Es lo unico que a esta persona le van a pedir en la
/// siguiente media hora.
class _Dorsal extends StatelessWidget {
  const _Dorsal({required this.bib});

  final String bib;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text(
          context.l10n.marathonPreparingBib,
          style: context.text.labelSm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(bib, style: context.text.displayLg.copyWith(color: c.primary)),
      ],
    );
  }
}

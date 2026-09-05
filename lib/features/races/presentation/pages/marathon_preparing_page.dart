import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/presentation/widgets/pre_race_beacon.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La sala de espera de una maraton que esta a punto de largar.
///
/// **Es toda la app mientras dura.** No tiene barra de navegacion, ni boton de
/// atras, ni nada que tocar: el organizador cerro el kiosko y a partir de ese
/// momento lo unico que el corredor necesita saber esta escrito aqui. Dejar la
/// app viva por debajo significaria que alguien cambia su categoria, cancela su
/// inscripcion o arranca un entrenamiento con el arco montado delante.
class MarathonPreparingPage extends ConsumerWidget {
  const MarathonPreparingPage({required this.entry, this.message, super.key});

  final RaceEntry entry;

  /// Lo que escribio el organizador. Vacio o `null` = el texto por defecto, que
  /// sale del ARB y llega en el idioma del corredor.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.l10n;
    final aviso = message?.trim();
    final permiso = ref.watch(preRaceBeaconProvider);

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
                // Sin ubicacion este corredor no aparece en el mapa del
                // organizador, que es quien decide con ese mapa si larga o
                // espera. Es lo unico accionable de esta pantalla.
                if (permiso != null && !permiso.isGranted) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SinUbicacion(outcome: permiso),
                ],
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

/// El aviso de que falta el permiso, con las dos salidas: volver a pedirlo y,
/// cuando el sistema ya no pregunta, abrir los ajustes.
class _SinUbicacion extends ConsumerWidget {
  const _SinUbicacion({required this.outcome});

  final LocationPermissionOutcome outcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final faro = ref.read(preRaceBeaconProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_rounded, color: c.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            outcome.message(context.l10n),
            textAlign: TextAlign.center,
            style: context.text.bodySm.copyWith(color: c.error),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => faro.encender(forzar: true),
                child: Text(context.l10n.commonRetry),
              ),
              TextButton(
                onPressed: faro.abrirAjustes,
                child: Text(context.l10n.commonSettings),
              ),
            ],
          ),
        ],
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

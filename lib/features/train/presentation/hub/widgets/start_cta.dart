import 'dart:async';

import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/presentation/hub/widgets/hub_motion.dart';
import 'package:camrun/features/train/presentation/providers/run_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// El boton de arrancar.
///
/// Es lo mas grande de la pantalla porque es lo unico que la pantalla quiere
/// que pase. Lleva un brillo que lo cruza cada pocos segundos: suficiente para
/// que el ojo vuelva ahi sin que nada se mueva mientras se lee la lista.
class StartCta extends ConsumerStatefulWidget {
  const StartCta({super.key});

  @override
  ConsumerState<StartCta> createState() => _StartCtaState();
}

class _StartCtaState extends ConsumerState<StartCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  /// Arrancar una salida libre desde aqui pide el permiso de ubicacion y abre
  /// el GPS antes de navegar: empujando solo la pantalla se llega a una sesion
  /// que no graba nada.
  void _freeRun() {
    unawaited(ref.read(runSessionProvider.notifier).start(RunGoal.free));
    unawaited(context.push(Routes.trainSession));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Pressable(
        onTap: () => context.push(Routes.trainSetup),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: c.brandGradient,
              boxShadow: c.floatingShadow,
            ),
            child: Stack(
              children: [
                if (!context.reduceMotion)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shine,
                      builder: (context, _) => FractionallySizedBox(
                        widthFactor: 0.45,
                        // De -0.45 a 1: entra por fuera del borde izquierdo y
                        // sale por fuera del derecho, nunca aparece de la nada
                        // en medio del boton.
                        alignment: Alignment(-1 + 3 * _shine.value, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                c.onPrimary.withValues(alpha: 0),
                                c.onPrimary.withValues(alpha: 0.16),
                                c.onPrimary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.onPrimary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: c.onPrimary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.trainHubStart,
                              style: context.text.headingMd.copyWith(
                                color: c.onPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            // Atajo a la salida libre: el camino largo pasa
                            // por elegir objetivo, y quien ya sabe que va a
                            // trotar no deberia tener que pasar por ahi.
                            GestureDetector(
                              onTap: _freeRun,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t.trainHubQuickFree,
                                    style: context.text.bodySm.copyWith(
                                      color: c.onPrimary.withValues(
                                        alpha: 0.85,
                                      ),
                                      decoration: TextDecoration.underline,
                                      decorationColor: c.onPrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 16,
                                    color: c.onPrimary.withValues(alpha: 0.85),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: c.onPrimary.withValues(alpha: 0.9),
                      ),
                    ],
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

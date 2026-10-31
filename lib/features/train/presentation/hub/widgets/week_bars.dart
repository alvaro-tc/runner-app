import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:flutter/material.dart';

/// La tira lunes-domingo de una semana.
///
/// Cada barra crece con su propia duracion, un poco mas larga que la anterior:
/// eso es el escalonado, y sale gratis dejando que la animacion implicita haga
/// el tween. Y como es implicita, deslizar de semana no reinicia nada: las
/// barras se mueven de la altura vieja a la nueva.
class WeekBars extends StatelessWidget {
  const WeekBars({
    required this.days,
    required this.miles,
    this.height = 72,
    super.key,
  });

  final List<DayStat> days;
  final bool miles;
  final double height;

  @override
  Widget build(BuildContext context) {
    final initials = Fmt.weekdayInitials();
    final max = days.fold<double>(
      0,
      (m, day) => day.distanceKm > m ? day.distanceKm : m,
    );
    final today = DateTime.now().weekday;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: _Bar(
                day: days[i],
                label: initials[i],
                factor: max <= 0 ? 0 : days[i].distanceKm / max,
                isToday: days[i].weekday == today,
                duration: Duration(milliseconds: 520 + i * 70),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.label,
    required this.factor,
    required this.isToday,
    required this.duration,
  });

  final DayStat day;
  final String label;
  final double factor;
  final bool isToday;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // La via vacia: sin ella, un martes sin correr es un hueco y
                // no se entiende que la barra falta a proposito.
                Container(
                  decoration: BoxDecoration(
                    color: c.ringTrack.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                if (day.workouts > 0)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: factor.clamp(0.08, 1.0)),
                    duration: context.reduceMotion ? Duration.zero : duration,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      heightFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              c.primary.withValues(alpha: 0.7),
                              c.primaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.text.labelSm.copyWith(
              color: isToday ? c.primary : c.textSecondary,
              fontWeight: isToday ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

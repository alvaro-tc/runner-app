import 'package:flutter/material.dart';
import 'package:paceup/core/extensions/context_x.dart';
import 'package:paceup/core/theme/app_spacing.dart';
import 'package:paceup/shared/widgets/atoms/app_progress_ring.dart';

/// Finishing a run is destructive, so it needs a deliberate 1.5 s press rather
/// than a tap that can happen in a pocket.
class HoldToFinishButton extends StatefulWidget {
  const HoldToFinishButton({required this.onFinish, super.key});

  final VoidCallback onFinish;

  static const holdDuration = Duration(milliseconds: 1500);

  @override
  State<HoldToFinishButton> createState() => _HoldToFinishButtonState();
}

class _HoldToFinishButtonState extends State<HoldToFinishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(
        vsync: this,
        duration: HoldToFinishButton.holdDuration,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _ctrl.reset();
          widget.onFinish();
        }
      });

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.runHoldToFinishSemantics,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: _ctrl.reverse,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => SizedBox(
            height: AppSizes.controlHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: c.error,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _ctrl.value,
                    child: Container(
                      height: AppSizes.controlHeight,
                      decoration: BoxDecoration(
                        color: c.error.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppProgressRing(
                      progress: _ctrl.value,
                      size: 22,
                      strokeWidth: 2.5,
                      animate: false,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _ctrl.value > 0
                          ? context.l10n.runKeepHolding
                          : context.l10n.runHoldToFinish,
                      style: context.text.button.copyWith(color: c.onPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

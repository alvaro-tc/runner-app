import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shimmer placeholder. Loading states use these instead of a centred spinner
/// so the page keeps its shape while data arrives.
class Skeleton extends StatefulWidget {
  const Skeleton({
    required this.width,
    required this.height,
    this.radius = AppRadius.md,
    super.key,
  });

  const Skeleton.circle({required double size, Key? key})
    : this(width: size, height: size, radius: AppRadius.pill, key: key);

  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (context.reduceMotion) {
      return _box(c.shimmerBase, null);
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value * 2 - 1;
        return _box(
          c.shimmerBase,
          LinearGradient(
            begin: Alignment(t - 1, 0),
            end: Alignment(t + 1, 0),
            colors: [c.shimmerBase, c.shimmerHighlight, c.shimmerBase],
          ),
        );
      },
    );
  }

  Widget _box(Color base, Gradient? gradient) => Container(
    width: widget.width,
    height: widget.height,
    decoration: BoxDecoration(
      color: gradient == null ? base : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(widget.radius),
    ),
  );
}

/// Stack of skeleton lines, the shape most list placeholders need.
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({
    this.lines = 3,
    this.width = double.infinity,
    super.key,
  });

  final int lines;
  final double width;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = width.isFinite ? width : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lines; i++) ...[
              Skeleton(width: i == lines - 1 ? full * 0.6 : full, height: 12),
              if (i != lines - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

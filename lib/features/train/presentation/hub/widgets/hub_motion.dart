import 'dart:async';

import 'package:camrun/core/extensions/context_x.dart';
import 'package:flutter/material.dart';

/// Entrada de un bloque: sube un poco y aparece.
///
/// Cada bloque trae su propio [delay] y asi la pantalla se arma de arriba
/// abajo en lugar de encenderse de golpe. Con "reducir movimiento" puesto
/// devuelve el hijo tal cual —ni tween ni controlador—: una animacion que el
/// sistema pidio no hacer no se hace mas despacio, no se hace.
class Reveal extends StatefulWidget {
  const Reveal({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
    super.key,
  });

  final Widget child;
  final Duration delay;

  /// Pixeles que recorre de abajo hacia arriba.
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Lo que se toca se hunde. Es el unico aviso de que algo es pulsable en una
/// tarjeta sin borde, y cuesta un `AnimatedScale`.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.onLongPress,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    onLongPress: widget.onLongPress,
    onTapDown: (_) => setState(() => _down = true),
    onTapUp: (_) => setState(() => _down = false),
    onTapCancel: () => setState(() => _down = false),
    child: AnimatedScale(
      scale: _down && !context.reduceMotion ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Un numero que se llena en vez de aparecer puesto.
///
/// Anima tambien al cambiar de valor —al deslizar de semana, por ejemplo—
/// porque el tween arranca del valor anterior, no de cero.
class CountUp extends StatelessWidget {
  const CountUp({
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
    super.key,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => builder(context, value),
    );
  }
}

/// El rectangulo que respira mientras se carga. Nuevo y no el `Skeleton`
/// compartido: esta seccion dibuja sus propios huecos con el radio de sus
/// propias tarjetas.
class PulseBox extends StatefulWidget {
  const PulseBox({
    this.width = double.infinity,
    this.height = 16,
    this.radius = 12,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<PulseBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.shimmerBase;
    final highlight = context.colors.shimmerHighlight;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.reduceMotion
              ? base
              : Color.lerp(base, highlight, _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

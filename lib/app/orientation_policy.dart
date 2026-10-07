import 'package:camrun/core/layout/breakpoints.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// El telefono va siempre en vertical; la tablet, como se la sostenga.
///
/// Se mide la **pantalla** y no la ventana: un iPad en Split View sigue
/// siendo una tablet. Y se mide aqui, con la vista ya montada, y no al
/// arrancar: antes del primer frame la pantalla puede no estar medida
/// todavia, y un plegable cambia de telefono a tablet al abrirlo.
///
/// En iPhone `Info.plist` ya solo admite vertical, asi que ni siquiera arranca
/// de lado; esto es lo que lo cumple en Android.
class OrientationPolicy extends StatefulWidget {
  const OrientationPolicy({required this.child, super.key});

  final Widget child;

  @override
  State<OrientationPolicy> createState() => _OrientationPolicyState();
}

class _OrientationPolicyState extends State<OrientationPolicy> {
  bool? _tablet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depende del tamano de la ventana solo para enterarse de que algo cambio
    // —abrir un plegable cambia los dos—; lo que decide es la pantalla.
    MediaQuery.sizeOf(context);
    final display = View.of(context).display;
    final tablet = AppBreakpoints.isTablet(
      display.size / display.devicePixelRatio,
    );
    if (tablet == _tablet) return;
    _tablet = tablet;
    // Lista vacia = lo que permita la plataforma: en tablet, todas.
    SystemChrome.setPreferredOrientations(
      tablet ? const [] : const [DeviceOrientation.portraitUp],
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

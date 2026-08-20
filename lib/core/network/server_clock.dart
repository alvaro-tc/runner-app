/// Reloj del servidor.
///
/// Cada respuesta trae `meta.timestamp`. Las cuentas regresivas se calculan
/// contra esa hora y no contra la del telefono, que el usuario puede tener
/// desviada minutos —y una carrera no empieza cuando el diga.
class ServerClock {
  Duration _offset = Duration.zero;

  /// Diferencia observada entre el servidor y el dispositivo.
  Duration get offset => _offset;

  void sync(DateTime serverTime) =>
      _offset = serverTime.difference(DateTime.now().toUtc());

  DateTime now() => DateTime.now().toUtc().add(_offset);
}

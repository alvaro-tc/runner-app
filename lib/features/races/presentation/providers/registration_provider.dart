import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/races/data/datasources/races_api.dart';
import 'package:paceup/features/races/domain/entities/registration.dart';
import 'package:paceup/features/races/presentation/providers/races_provider.dart';

/// Cada cuanto se pregunta por un cobro que quedo pendiente (QR, transferencia).
///
/// Dos segundos es lo que aguanta alguien mirando un QR sin creer que se colgo,
/// y el endpoint esta pensado para sondearse: cada lectura resuelve el cobro si
/// ya toca.
const _cadenciaSondeo = Duration(seconds: 2);

/// Tope del sondeo. Pasado esto el cobro sigue vivo del lado del servidor —el
/// webhook lo cerrara— pero la pantalla deja de esperar en vez de girar para
/// siempre.
const _tiempoMaximoSondeo = Duration(minutes: 5);

/// El estado del flujo de inscripcion.
@immutable
class RegistrationFlowState {
  const RegistrationFlowState({
    this.marathonId,
    this.registration,
    this.quote,
    this.payment,
    this.busy = false,
    this.error,
  });

  /// De que maraton es este flujo. Sirve para descartarlo al abrir otro: dos
  /// altas a medias en la misma pantalla acabarian pagando la que no era.
  final String? marathonId;

  /// El borrador vivo. `null` antes del paso 1.
  final Registration? registration;

  /// El total vigente, recalculado por el servidor en cada cambio.
  final RegistrationQuote? quote;

  /// El ultimo cobro intentado. Con `pending` la pantalla espera.
  final PaymentInfo? payment;

  final bool busy;
  final Failure? error;

  bool get isConfirmed => registration?.state.isConfirmed ?? false;

  bool get isAwaitingPayment =>
      payment != null && payment!.state == RacePaymentState.pending;

  RegistrationFlowState copyWith({
    String? marathonId,
    Registration? registration,
    RegistrationQuote? quote,
    PaymentInfo? payment,
    bool? busy,
    Failure? error,
    bool clearError = false,
  }) => RegistrationFlowState(
    marathonId: marathonId ?? this.marathonId,
    registration: registration ?? this.registration,
    quote: quote ?? this.quote,
    payment: payment ?? this.payment,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Lleva la inscripcion por sus tres pasos.
///
/// **El estado real vive en el servidor**, no aqui: el borrador tiene id, paso
/// y precio calculado del otro lado. Este notifier es la copia local de eso,
/// para que la pantalla no tenga que volver a pedirlo en cada frame.
///
/// La **clave de idempotencia se genera una sola vez por borrador** y se
/// conserva mientras el flujo siga vivo: es lo que hace que tocar "pagar" dos
/// veces, o reintentar tras un timeout, no cobre dos veces.
class RegistrationFlowNotifier extends Notifier<RegistrationFlowState> {
  String? _claveDeCobro;
  Timer? _sondeo;

  @override
  RegistrationFlowState build() {
    ref.onDispose(() => _sondeo?.cancel());
    return const RegistrationFlowState();
  }

  /// Prepara el flujo para una maraton. Idempotente: llamarlo con la misma
  /// maraton no tira el borrador en curso.
  void openFor(String marathonId) {
    if (state.marathonId == marathonId) return;

    _sondeo?.cancel();
    _claveDeCobro = null;
    state = RegistrationFlowState(marathonId: marathonId);
  }

  /// Paso 1. Si ya habia un borrador para esta maraton, el servidor lo devuelve
  /// en vez de abrir otro: el flujo se retoma donde se dejo.
  Future<bool> submitPersonalData(RegistrationPersonalData datos) {
    final marathonId = state.marathonId;
    if (marathonId == null) return Future.value(false);

    return _run(
      () => ref
          .read(raceRepositoryProvider)
          .startRegistration(marathonId: marathonId, data: datos),
    );
  }

  /// Paso 2. [extras] es la seleccion completa, no un incremento.
  Future<bool> submitCategoryAndExtras({
    String? categoryId,
    required List<ExtraSelection> extras,
  }) {
    final id = state.registration?.id;
    if (id == null) return Future.value(false);

    return _run(
      () => ref
          .read(raceRepositoryProvider)
          .setCategoryAndExtras(
            registrationId: id,
            categoryId: categoryId,
            extras: extras,
          ),
    );
  }

  /// Paso 3. Devuelve `true` cuando la inscripcion queda confirmada; con QR o
  /// transferencia vuelve `false` y arranca el sondeo.
  Future<bool> pay({required RacePaymentMethod method, CardDetails? card}) async {
    final id = state.registration?.id;
    if (id == null || state.busy) return false;

    state = state.copyWith(busy: true, clearError: true);
    _claveDeCobro ??= RacesApi.newIdempotencyKey();

    final resultado = await ref
        .read(raceRepositoryProvider)
        .checkout(
          registrationId: id,
          method: method,
          idempotencyKey: _claveDeCobro!,
          card: card,
        );

    return resultado.fold(
      (salida) {
        state = state.copyWith(
          registration: salida.registration,
          quote: salida.registration.quote,
          payment: salida.payment,
          busy: false,
        );

        if (salida.isConfirmed) {
          // La carrera nueva tiene que aparecer en "Mis carreras" sin que el
          // usuario tenga que tirar de la lista.
          ref.invalidate(racesProvider);
          return true;
        }

        if (salida.payment.state == RacePaymentState.pending) _sondear();
        return false;
      },
      (fallo) {
        state = state.copyWith(busy: false, error: fallo);
        return false;
      },
    );
  }

  /// Vuelve a intentar el cobro tras un rechazo.
  ///
  /// **Con clave nueva**: la anterior identifica el intento que ya se resolvio
  /// —en rechazo— y reusarla devolveria ese mismo rechazo para siempre.
  void retryPayment() {
    _claveDeCobro = null;
    state = state.copyWith(clearError: true);
  }

  // ─── Interno ─────────────────────────────────────────────────────────────

  /// Sondea el cobro pendiente hasta que se resuelva o se acabe la paciencia.
  void _sondear() {
    _sondeo?.cancel();
    final hasta = DateTime.now().add(_tiempoMaximoSondeo);

    _sondeo = Timer.periodic(_cadenciaSondeo, (timer) async {
      final pago = state.payment;
      if (pago == null || DateTime.now().isAfter(hasta)) {
        timer.cancel();
        return;
      }

      final resultado = await ref
          .read(raceRepositoryProvider)
          .pollPayment(pago.id);

      resultado.fold(
        (PaymentInfo actualizado) {
          state = state.copyWith(payment: actualizado);
          if (!actualizado.isSettled) return;

          timer.cancel();
          // El cobro cerro: la inscripcion cambio de estado del otro lado, asi
          // que se relee en vez de deducirlo aqui.
          unawaited(_refrescarInscripcion());
        },
        // Un fallo de red en un sondeo no es un fallo del cobro: se calla y se
        // reintenta en el siguiente tic.
        (Failure _) {},
      );
    });
  }

  Future<void> _refrescarInscripcion() async {
    final id = state.registration?.id;
    if (id == null) return;

    final resultado = await ref.read(raceRepositoryProvider).quote(id);
    resultado.fold(
      (RegistrationQuote q) => state = state.copyWith(quote: q),
      (Failure _) {},
    );

    if (state.payment?.state == RacePaymentState.paid) {
      ref.invalidate(racesProvider);
    }
  }

  /// Ejecuta un paso que devuelve el borrador y refresca el total con el.
  Future<bool> _run(Future<Result<Registration>> Function() paso) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, clearError: true);

    final resultado = await paso();

    return resultado.fold(
      (Registration registro) {
        state = state.copyWith(
          registration: registro,
          quote: registro.quote,
          busy: false,
        );
        return true;
      },
      (Failure fallo) {
        state = state.copyWith(busy: false, error: fallo);
        return false;
      },
    );
  }
}

/// Uno solo: la pantalla de alta es una a la vez, y `openFor` descarta el flujo
/// anterior al abrir otra maraton.
final registrationFlowProvider =
    NotifierProvider<RegistrationFlowNotifier, RegistrationFlowState>(
      RegistrationFlowNotifier.new,
    );

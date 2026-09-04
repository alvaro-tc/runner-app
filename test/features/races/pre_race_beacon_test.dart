import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/presentation/providers/live_marathon_provider.dart';
import 'package:camrun/features/races/presentation/widgets/pre_race_beacon.dart';
import 'package:camrun/features/tracking/data/live_uploader.dart';
import 'package:camrun/features/tracking/tracking_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cuando el corredor empieza a aparecer en el mapa del organizador.
///
/// Las dos que importan el dia de la carrera: que en preparacion ya se manda la
/// posicion —si no, el organizador decide si larga mirando un mapa vacio— y que
/// la largada **no** la apaga, que borraria a todo el mundo del mapa en el peor
/// momento posible.
void main() {
  late _FaroFalso faro;
  late _Puerta puerta;

  Future<void> montar(WidgetTester tester) async {
    faro = _FaroFalso();
    puerta = _Puerta();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveUploaderProvider.overrideWithValue(faro),
          locationServiceProvider.overrideWithValue(_UbicacionConcedida()),
          marathonGateProvider.overrideWith(() => puerta),
        ],
        child: const PreRaceBeacon(child: SizedBox.shrink()),
      ),
    );
  }

  Future<void> poner(WidgetTester tester, MarathonGate estado) async {
    puerta.poner(estado);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('en preparacion se enciende, la largada no lo apaga', (
    tester,
  ) async {
    await montar(tester);
    expect(faro.encendidos, 0);

    await poner(tester, GatePreparing(entry: _entrada));
    expect(faro.encendidos, 1);

    // Un segundo aviso de la misma preparacion no vuelve a pedir permiso ni a
    // reencender: llegan cada pocos segundos.
    await poner(tester, GatePreparing(entry: _entrada));
    expect(faro.encendidos, 1);

    await poner(
      tester,
      GateRunning(entry: _entrada, startedAt: DateTime(2026, 9, 2, 7)),
    );
    expect(faro.apagados, 0, reason: 'la sesion de carrera se hace cargo');

    await poner(tester, const GateOpen());
    expect(faro.apagados, 1);
  });
}

class _Puerta extends MarathonGateNotifier {
  @override
  MarathonGate build() => const GateOpen();

  void poner(MarathonGate estado) => state = estado;
}

class _FaroFalso implements LiveUploader {
  int encendidos = 0;
  int apagados = 0;

  @override
  Future<bool> start() async {
    encendidos++;
    return true;
  }

  @override
  Future<void> stop() async => apagados++;
}

class _UbicacionConcedida implements LocationService {
  @override
  Future<LocationPermissionOutcome> ensurePermission() async =>
      LocationPermissionOutcome.granted;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _entrada = RaceEntry(
  id: 'r1',
  marathon: Marathon(
    id: 'm1',
    name: 'Maraton de La Paz',
    date: DateTime(2026, 9, 2, 7),
    city: 'La Paz',
    country: 'BO',
    heroImageUrl: '',
    distanceKm: 42.2,
    entryFee: const Money(350, 'BOB'),
    slotsTotal: 500,
    slotsTaken: 100,
    status: RegistrationStatus.closed,
    about: '',
    schedule: const [],
    included: const [],
    routePreview: const [],
  ),
  registeredAt: DateTime(2026, 8),
  amountPaid: const Money(350, 'BOB'),
  paymentStatus: PaymentStatus.paid,
  bibNumber: '1234',
  status: RaceEntryStatus.upcoming,
);

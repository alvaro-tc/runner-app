import 'package:camrun/features/home/data/home_mappers.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/domain/entities/registration.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';

/// JSON de la API -> entidades de carreras.
///
/// Las unidades de la API son crudas —metros, segundos, centavos, ISO-8601 UTC—
/// y aqui es donde dejan de serlo. Ningun `Map` cruza hacia arriba.

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

int _i(Object? v) => (v as num?)?.toInt() ?? 0;

DateTime? _fechaOpcional(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

Money _dinero(Object? centavos, String moneda) =>
    Money(_i(centavos) / 100, moneda);

// ─── Mis carreras ──────────────────────────────────────────────────────────

/// Una carrera de `/races/me` o `/races/:registrationId`.
///
/// [payments] es lo que devuelve `/registrations/:id/payments`, del mas nuevo
/// al mas viejo. Va aparte porque la lista de carreras no lo trae: el monto
/// cobrado solo hace falta en el detalle, y pedirlo para pintar cada tarjeta
/// serian N llamadas para una linea de texto.
RaceEntry raceEntryFrom(
  Map<String, dynamic> j, {
  List<Map<String, dynamic>> payments = const [],
}) {
  final resultado = j['result'] as Map<String, dynamic>?;
  final cobrado = payments
      .where((p) => p['status'] == 'paid' || p['status'] == 'refunded')
      .firstOrNull;
  final ultimo = payments.firstOrNull;
  final moneda = (ultimo?['currency'] as String?) ?? 'BOB';

  return RaceEntry(
    id: j['registrationId'] as String,
    marathon: marathonFrom(j['marathon']! as Map<String, dynamic>),
    registeredAt: _fechaOpcional(j['registeredAt']) ?? DateTime.now(),
    amountPaid: cobrado == null
        ? Money.zero
        : _dinero(cobrado['amountCents'], moneda),
    paymentStatus: _estadoDePago(j['paymentStatus'] as String?),
    bibNumber: j['bibNumber'] as String? ?? '—',
    status: _estadoDeCarrera(j['status'] as String?, resultado),
    paymentMethod: _metodo(ultimo),
    result: resultado == null
        ? null
        : _resultado(
            resultado,
            j,
            splits: (j['splits'] as List? ?? const [])
                .cast<Map<String, dynamic>>(),
            recorrido: j['routeGeoJson'],
          ),
  );
}

PaymentStatus _estadoDePago(String? valor) => switch (valor) {
  'paid' => PaymentStatus.paid,
  'refunded' => PaymentStatus.refunded,
  'failed' => PaymentStatus.failed,
  _ => PaymentStatus.pending,
};

/// La API distingue proxima de pasada por la fecha de largada. Una carrera que
/// ya paso y no dejo resultado no es "completada": es un DNF hasta que alguien
/// diga lo contrario.
RaceEntryStatus _estadoDeCarrera(String? valor, Map<String, dynamic>? result) =>
    switch (valor) {
      'completed' =>
        result == null ? RaceEntryStatus.dnf : RaceEntryStatus.completed,
      _ => RaceEntryStatus.upcoming,
    };

/// Etiqueta del metodo, con lo unico que se guarda de la tarjeta.
String _metodo(Map<String, dynamic>? pago) {
  if (pago == null) return '—';
  final detalles = pago['methodDetails'] as Map<String, dynamic>? ?? const {};

  return switch (pago['method']) {
    'card' => 'Card •••• ${detalles['last4'] ?? '????'}',
    'qr' => 'QR',
    'bank_transfer' => 'Bank transfer',
    _ => '—',
  };
}

RaceResult _resultado(
  Map<String, dynamic> r,
  Map<String, dynamic> carrera, {
  required List<Map<String, dynamic>> splits,
  required Object? recorrido,
}) {
  final distanciaKm = _d(r['distanceMeters']) / 1000;
  final chip = _i(r['chipTimeSeconds']);

  return RaceResult(
    finishTime: Duration(seconds: _i(r['finishTimeSeconds'])),
    // Sin chip, el tiempo oficial es lo unico que hay: repetirlo dice la verdad
    // ("no hubo chip") mejor que un cero.
    chipTime: Duration(seconds: chip == 0 ? _i(r['finishTimeSeconds']) : chip),
    avgPacePerKm: Duration(seconds: _i(r['avgPaceSecPerKm'])),
    avgSpeedKmh: _d(r['avgSpeedMps']) * 3.6,
    distanceKm: distanciaKm,
    route: _puntos(recorrido),
    splits: _splits(splits),
    elevationGainM: _d(r['elevationGainMeters']),
    overallRank: (r['overallRank'] as num?)?.toInt(),
    ageGroupRank: (r['categoryRank'] as num?)?.toInt(),
    totalParticipants: (r['finishers'] as num?)?.toInt(),
    bestKm: _mejorKm(splits, (r['bestKmIndex'] as num?)?.toInt()),
  );
}

/// Los parciales llegan por indice; la UI los pinta por numero de kilometro y
/// necesita ademas la diferencia con el anterior, que la API no manda.
List<KmSplit> _splits(List<Map<String, dynamic>> crudos) {
  final salida = <KmSplit>[];
  var anterior = Duration.zero;

  for (final s in crudos) {
    final ritmo = Duration(seconds: _i(s['paceSecPerKm']));
    salida.add(
      KmSplit(
        km: _i(s['index']) + 1,
        duration: Duration(seconds: _i(s['durationSeconds'])),
        pace: ritmo,
        deltaToPrevious: anterior == Duration.zero
            ? Duration.zero
            : ritmo - anterior,
        elevationGainM: _d(s['elevationGainMeters']),
      ),
    );
    anterior = ritmo;
  }

  return salida;
}

Duration? _mejorKm(List<Map<String, dynamic>> splits, int? indice) {
  if (indice == null) return null;
  final mejor = splits.where((s) => _i(s['index']) == indice).firstOrNull;

  return mejor == null ? null : Duration(seconds: _i(mejor['paceSecPerKm']));
}

/// GeoJSON `LineString` viene en `[lng, lat]`; el mapa los quiere al reves.
///
/// Las marcas de tiempo no viajan en el recorrido —es una geometria, no un
/// track— asi que se rellenan con el epoch: la UI del resultado dibuja la linea
/// y no mira los tiempos.
List<GeoPoint> _puntos(Object? geoJson) {
  if (geoJson is! Map) return const [];
  final coords = geoJson['coordinates'];
  if (coords is! List) return const [];

  return [
    for (final punto in coords)
      if (punto is List && punto.length >= 2)
        GeoPoint(
          lat: _d(punto[1]),
          lng: _d(punto[0]),
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        ),
  ];
}

/// El recorrido oficial de una maraton, para dibujarlo bajo el del corredor.
List<GeoPoint> routePointsFrom(Object? geoJson) => _puntos(geoJson);

/// `GET /races/me/summary`. La cabecera de "Mis carreras".
RaceTotals raceTotalsFrom(Map<String, dynamic> j) {
  final moneda = j['currency'] as String? ?? 'BOB';

  return RaceTotals(
    racesJoined: _i(j['racesCompleted']) + _i(j['racesUpcoming']),
    distanceRacedKm: _d(j['totalDistanceMeters']) / 1000,
    totalSpent: _dinero(j['totalSpentCents'], moneda),
  );
}

// ─── Inscripcion ───────────────────────────────────────────────────────────

Registration registrationFrom(Map<String, dynamic> j) {
  final maraton = j['marathon'] as Map<String, dynamic>? ?? const {};

  return Registration(
    id: j['id'] as String,
    marathonId: maraton['id'] as String? ?? '',
    marathonName: maraton['name'] as String? ?? '',
    state: RegistrationState.fromApi(j['status'] as String?),
    step: RegistrationStep.fromNumber(_i(j['step'])),
    quote: quoteFrom(j),
    categoryId: j['categoryId'] as String?,
    bibNumber: j['bibNumber'] as String?,
  );
}

/// Sirve para la respuesta de `/quote` y para el desglose embebido en una
/// inscripcion: es la misma forma en los dos sitios.
RegistrationQuote quoteFrom(Map<String, dynamic> j) {
  final moneda = j['currency'] as String? ?? 'BOB';
  final fee = j['serviceFee'] as Map<String, dynamic>?;

  return RegistrationQuote(
    lines: [
      for (final l
          in (j['items'] as List? ?? const []).cast<Map<String, dynamic>>())
        QuoteLine(
          label: l['label'] as String? ?? '',
          quantity: _i(l['quantity']) == 0 ? 1 : _i(l['quantity']),
          amount: _dinero(l['amountCents'], moneda),
        ),
    ],
    subtotal: _dinero(j['subtotalCents'], moneda),
    total: _dinero(j['totalCents'], moneda),
    // `null` es "hoy no se cobra cargo", que no es lo mismo que cobrar cero:
    // pintar "Bs 0,00" promete una linea que no existe.
    serviceFee: fee == null ? null : _dinero(fee['amountCents'], moneda),
    serviceFeeLabel: fee?['label'] as String?,
  );
}

PaymentInfo paymentFrom(Map<String, dynamic> j) {
  final detalles = j['methodDetails'] as Map<String, dynamic>? ?? const {};
  // El QR del organizador viaja en su propio campo, no en el del QR simulado:
  // son dos cosas distintas y mezclarlas haria que la pantalla pintara un QR
  // que se paga solo cuando en realidad espera a una persona.
  final qrManual = detalles['manualQr'] as Map<String, dynamic>?;
  final banco = detalles['bank'] as Map<String, dynamic>?;

  return PaymentInfo(
    id: j['id'] as String,
    method: switch (j['method']) {
      'qr' => RacePaymentMethod.qr,
      'qr_manual' => RacePaymentMethod.qrManual,
      'bank_transfer' => RacePaymentMethod.bankTransfer,
      _ => RacePaymentMethod.card,
    },
    state: RacePaymentState.fromApi(j['status'] as String?),
    amount: _dinero(j['amountCents'], j['currency'] as String? ?? 'BOB'),
    failureReason: j['failureReason'] as String?,
    qrPayload: qrManual?['payload'] as String?,
    qrInstructions: qrManual?['instructions'] as String?,
    qrReference: qrManual?['reference'] as String?,
    bankReference: banco?['reference'] as String?,
    last4: detalles['last4'] as String?,
    proof: proofFrom(j['proof'] as Map<String, dynamic>?),
  );
}

PaymentProof? proofFrom(Map<String, dynamic>? j) {
  if (j == null) return null;

  return PaymentProof(
    id: j['id'] as String,
    state: ProofState.fromApi(j['status'] as String?),
    imageUrl: j['imageUrl'] as String? ?? '',
    reference: j['reference'] as String?,
    note: j['note'] as String?,
  );
}

CheckoutOutcome checkoutFrom(Map<String, dynamic> j) => CheckoutOutcome(
  payment: paymentFrom(j['payment']! as Map<String, dynamic>),
  registration: registrationFrom(j['registration']! as Map<String, dynamic>),
);

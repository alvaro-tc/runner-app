import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/core/network/network_providers.dart';
import 'package:paceup/core/services/location_service.dart';
import 'package:paceup/core/sync/sync_providers.dart';
import 'package:paceup/features/tracking/data/tracking_api.dart';
import 'package:paceup/features/tracking/data/tracking_service.dart';

final trackingApiProvider = Provider<TrackingApi>(
  (ref) => TrackingApi(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);

/// Vive mientras viva la app: una grabacion no puede depender de que una
/// pantalla siga montada.
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final service = TrackingService(
    ref.watch(appDatabaseProvider),
    ref.watch(trackingApiProvider),
    ref.watch(locationServiceProvider),
    ref.watch(syncServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

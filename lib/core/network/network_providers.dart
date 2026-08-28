import 'package:camrun/core/config/app_config_api.dart';
import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/core/network/session_controller.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:camrun/features/auth/data/datasources/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final serverClockProvider = Provider<ServerClock>((ref) => ServerClock());

final sessionControllerProvider = Provider<SessionController>(
  (ref) => SessionController(
    storage: ref.watch(tokenStorageProvider),
    refreshClient: buildRefreshClient(),
  ),
);

final dioProvider = Provider<Dio>(
  (ref) => buildApiClient(
    session: ref.watch(sessionControllerProvider),
    clock: ref.watch(serverClockProvider),
  ),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);

final appConfigApiProvider = Provider<AppConfigApi>(
  (ref) => AppConfigApi(ref.watch(dioProvider)),
);

/// Un solo socket para toda la app: el mapa en vivo del panel y el aviso de
/// largada del corredor viajan por la misma conexion.
final liveSocketProvider = Provider<LiveSocket>((ref) {
  final socket = LiveSocket(ref.watch(tokenStorageProvider));
  ref.onDispose(socket.dispose);
  return socket;
});

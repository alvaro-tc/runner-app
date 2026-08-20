import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adaptador de mentira: responde lo que diga [handler], sin socket ninguno.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

ResponseBody jsonBody(Object body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Una respuesta con el sobre `{ data, meta }` que devuelve la API.
ResponseBody envelope(Object data, {int status = 200}) => jsonBody({
  'data': data,
  'meta': {
    'requestId': 'req-1',
    'timestamp': DateTime.utc(2026, 8, 20, 12).toIso8601String(),
  },
}, status);

ResponseBody errorBody(String code, {int status = 400}) => jsonBody({
  'error': {'code': code, 'message': 'texto humano', 'details': <Object?>[]},
  'meta': {'requestId': 'req-1'},
}, status);

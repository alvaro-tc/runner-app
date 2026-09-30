import 'dart:convert';
import 'dart:io';

/// Prepara los ajustes nativos antes de que Xcode lea los xcconfig.
/// Usa el mismo archivo que --dart-define-from-file, sin dependencias externas.
void main(List<String> args) {
  if (args.length > 1) {
    stderr.writeln('Uso: dart tool/configure_google_ios.dart [archivo.env]');
    exitCode = 64;
    return;
  }

  final envPath = args.isEmpty ? '.env' : args.single;
  try {
    final values = _readDefines(File(envPath).readAsStringSync());
    final iosId = _clientId(values, 'GOOGLE_IOS_CLIENT_ID', envPath);
    final serverId = _clientId(values, 'GOOGLE_SERVER_CLIENT_ID', envPath);
    if (iosId == serverId) {
      throw const FormatException(
        'GOOGLE_IOS_CLIENT_ID debe ser el cliente de tipo iOS; '
        'GOOGLE_SERVER_CLIENT_ID debe ser el cliente de tipo Web.',
      );
    }

    final reversedId = iosId.split('.').reversed.join('.');
    final root = File.fromUri(Platform.script).parent.parent;
    final output = File(
      '${root.path}/ios/Flutter/GoogleSignIn.generated.xcconfig',
    );
    final config =
        '// Generado por tool/configure_google_ios.dart.\n'
        '// Editar el archivo de entorno y volver a ejecutar make google-ios.\n'
        'GOOGLE_IOS_CLIENT_ID = $iosId\n'
        'GOOGLE_IOS_REVERSED_CLIENT_ID = $reversedId\n'
        'GOOGLE_SERVER_CLIENT_ID = $serverId\n';
    if (!output.existsSync() || output.readAsStringSync() != config) {
      output.writeAsStringSync(config);
    }
    stdout.writeln(
      'Google para iOS configurado desde $envPath. '
      'Recompila la app con --dart-define-from-file=$envPath.',
    );
  } on FormatException catch (error) {
    stderr.writeln('Configuracion de Google para iOS: ${error.message}');
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('No se pudo leer o guardar la configuracion: ${error.path}');
    exitCode = 74;
  }
}

Map<String, String> _readDefines(String contents) {
  if (contents.trimLeft().startsWith('{')) {
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El archivo JSON debe contener un objeto.');
    }
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  final values = <String, String>{};
  for (final line in const LineSplitter().convert(contents)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final separator = trimmed.indexOf('=');
    if (separator < 1) continue;
    final key = trimmed.substring(0, separator).trim();
    final value = trimmed.substring(separator + 1).trim();
    final quoted = RegExp(r'''^(["'`])(.*)\1\s*(?:#.*)?$''').firstMatch(value);
    values[key] = quoted?.group(2) ?? value.split('#').first.trim();
  }
  return values;
}

String _clientId(Map<String, String> values, String key, String envPath) {
  final value = values[key]?.trim() ?? '';
  if (value.isEmpty) {
    throw FormatException('Completa $key en $envPath antes de compilar iOS.');
  }
  // Ademas de detectar errores, limita lo que se escribe en el xcconfig.
  if (!RegExp(
    r'^[0-9]+-[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$',
  ).hasMatch(value)) {
    throw FormatException('$key no tiene el formato de un cliente OAuth.');
  }
  return value;
}

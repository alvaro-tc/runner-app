import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Avisos hablados durante la carrera.
///
/// Corriendo no se mira la pantalla: lo que pasa —se cerro una vuelta— hay que
/// **oirlo**. Habla el sintetizador del sistema y no audios grabados, que
/// serian un fichero por frase y por idioma, y ademas no sabrian decir "vuelta
/// 3 de 5".
///
/// Nunca lanza: quedarse sin voz es una molestia, cortar la carrera por ello
/// no. Un telefono sin motor de voz instalado —o en silencio— simplemente no
/// dice nada.
class VoiceService {
  VoiceService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  String? _idioma;

  /// Lee [texto] en el idioma de [locale], interrumpiendo lo que estuviera
  /// diciendo: el aviso nuevo siempre importa mas que el anterior.
  Future<void> say(String texto, {required Locale locale}) async {
    // `es` a secas no lo reconocen todos los motores; con region si.
    final idioma = switch (locale.languageCode) {
      'es' => 'es-ES',
      _ => 'en-US',
    };
    try {
      if (_idioma != idioma) {
        await _tts.setLanguage(idioma);
        _idioma = idioma;
      }
      await _tts.stop();
      await _tts.speak(texto);
    } on Exception catch (_) {
      // Sin voz se sigue corriendo.
    } on Error catch (_) {
      // Un motor de voz ausente tira `MissingPluginException` y similares.
    }
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) => VoiceService());

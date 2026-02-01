import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Function(String)? onStatusChanged;
  Function(String)? onErrorChanged;

  Future<bool> init() async {
    if (!_isInitialized) {
      try {
        _isInitialized = await _speech.initialize(
          onError: (val) {
            print('Speech Error: $val');
            String msg = val.errorMsg;
            if (val.errorMsg == 'error_speech_timeout') {
              msg = 'Listening timed out. Please speak louder.';
            } else if (val.errorMsg == 'error_no_match') {
              msg = 'Could not understand. Try again.';
            }
            if (onErrorChanged != null) onErrorChanged!(msg);
          },
          onStatus: (val) {
            print('Speech Status: $val');
            if (onStatusChanged != null) onStatusChanged!(val);
          },
        );
        if (_isInitialized) {
          var locales = await _speech.locales();
          print('Create: Available Locales: ${locales.map((l) => l.localeId).join(', ')}');
        }
      } catch (e) {
        print('Speech Init Error: $e');
        _isInitialized = false;
      }
    }
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required String localeId,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (_isInitialized) {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId, // 'en_US' or 'bn_BD'
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: true,
      );
    }
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;
}

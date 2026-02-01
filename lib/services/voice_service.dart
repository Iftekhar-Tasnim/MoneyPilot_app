import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Function(String)? onStatusChanged;
  Function(String)? onErrorChanged;

  List<LocaleName> _availableLocales = [];

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
          _availableLocales = await _speech.locales();
          print('Create: Available Locales: ${_availableLocales.map((l) => l.localeId).join(', ')}');
        }
      } catch (e) {
        print('Speech Init Error: $e');
        _isInitialized = false;
      }
    }
    return _isInitialized;
  }

  String _getBestLocale(String langCode) {
    if (_availableLocales.isEmpty) return 'en_US';

    // 1. Try exact match for preferred regions
    if (langCode == 'bn') {
       if (_availableLocales.any((l) => l.localeId == 'bn_BD')) return 'bn_BD';
       if (_availableLocales.any((l) => l.localeId == 'bn_IN')) return 'bn_IN';
    }
    
    // 2. Try any match starting with the code (e.g. 'bn_XY')
    try {
      final partialHook = _availableLocales.firstWhere((l) => l.localeId.startsWith(langCode));
      return partialHook.localeId;
    } catch (_) {}

    // 3. Fallback defaults
    return langCode == 'bn' ? 'bn_BD' : 'en_US';
  }

  Future<String?> startListening({
    required Function(String) onResult,
    required String languageCode, // 'en' or 'bn'
  }) async {
    String? warningMessage;
    
    if (!_isInitialized) {
      await init();
    }

    if (_isInitialized) {
      final selectedLocale = _getBestLocale(languageCode);
      print('DEBUG: VoiceService using locale: $selectedLocale for lang: $languageCode');

      // Check if actually supported in list
      bool isSupported = _availableLocales.isEmpty || _availableLocales.any((l) => l.localeId == selectedLocale);
      
      if (!isSupported && _availableLocales.isNotEmpty) {
           print('Warning: $selectedLocale not found. Attempting anyway (Online mode).');
           warningMessage = 'online_mode_pack_missing';
      }

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: selectedLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: true,
      );
    }
    return warningMessage;
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;
}

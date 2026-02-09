import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/voice_indicator_state.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  Timer? _activeStateTimer;

  // Streams for UI communication
  final _stateController = StreamController<VoiceIndicatorState>.broadcast();
  final _commandController = StreamController<String>.broadcast();

  Stream<VoiceIndicatorState> get stateStream => _stateController.stream;
  Stream<String> get commandStream => _commandController.stream;

  VoiceIndicatorState _currentState = VoiceIndicatorState.disabled;
  VoiceIndicatorState get currentState => _currentState;

  String _currentLocaleId = 'es-ES';
  final String _wakeWord =
      'lumis'; // Actualizado según la solicitud del usuario

  Future<bool> init() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) => print('Voice Error: $error'),
    );
    return _isInitialized;
  }

  void _handleStatus(String status) {
    print('Voice Status: $status');
    if (status == 'done' || status == 'notListening') {
      if (_currentState != VoiceIndicatorState.disabled) {
        _startListening();
      }
    }
  }

  Future<void> startService() async {
    if (!await init()) return;
    _currentState = VoiceIndicatorState.passive;
    _stateController.add(_currentState);
    await _startListening();
  }

  Future<void> stopService() async {
    _currentState = VoiceIndicatorState.disabled;
    _activeStateTimer?.cancel();
    _stateController.add(_currentState);
    await _speech.stop();
  }

  Future<void> _startListening() async {
    if (!_isInitialized || _speech.isListening) return;

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: _currentLocaleId,
      cancelOnError: false,
      partialResults: true,
      listenMode: _currentState == VoiceIndicatorState.passive
          ? ListenMode.dictation
          : ListenMode.confirmation,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // We only process final results or high confidence partials for wake word
    if (result.confidence < 0.5 && !result.finalResult) return;

    String text = result.recognizedWords.toLowerCase().trim();
    print('Recognized: "$text" (State: $_currentState)');

    if (_currentState == VoiceIndicatorState.passive) {
      if (text.contains(_wakeWord)) {
        _enterActiveMode();
      }
    } else if (_currentState == VoiceIndicatorState.active &&
        result.finalResult) {
      if (text.isNotEmpty && !text.contains(_wakeWord)) {
        _handleCommand(text);
      }
    }
  }

  void _enterActiveMode() {
    _currentState = VoiceIndicatorState.active;
    _stateController.add(_currentState);

    // Start a timer to return to passive if no command is heard
    _activeStateTimer?.cancel();
    _activeStateTimer = Timer(const Duration(seconds: 5), () {
      if (_currentState == VoiceIndicatorState.active) {
        _currentState = VoiceIndicatorState.passive;
        _stateController.add(_currentState);
        _startListening();
      }
    });

    // Stop current listening to clear buffer and start again for the command
    _speech.stop();
  }

  void _handleCommand(String text) {
    _activeStateTimer?.cancel();
    _commandController.add(text);

    // Briefly show "heard" state
    _currentState = VoiceIndicatorState.heard;
    _stateController.add(_currentState);

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentState != VoiceIndicatorState.disabled) {
        _currentState = VoiceIndicatorState.passive;
        _stateController.add(_currentState);
        _startListening();
      }
    });
  }

  void setLocale(String localeId) {
    _currentLocaleId = localeId;
  }
}

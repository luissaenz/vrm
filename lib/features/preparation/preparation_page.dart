import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../l10n/app_localizations.dart';
import '../recording/recording_page.dart';

enum PreparationPhase { fixation, decision }

class PreparationPage extends StatefulWidget {
  const PreparationPage({super.key});

  @override
  State<PreparationPage> createState() => _PreparationPageState();
}

class _PreparationPageState extends State<PreparationPage> {
  // Design Tokens
  static const Color forest = Color(0xFF2D4B44);
  static const Color backgroundLight = Color(0xFFF9F8F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // State
  PreparationPhase _currentPhase = PreparationPhase.fixation;
  bool _isVoiceControlActive = false;

  // Phase 1: Fixation (Simulated reading)
  double _readingProgress = 0.0;
  Timer? _readingTimer;
  final String _scriptText =
      "Hola, mi nombre es Juan y quiero presentar mi proyecto.";

  // Phase 2: Decision (Countdown)
  int _countdown = 3;
  double _countdownProgress = 0.0;
  Timer? _countdownTimer;

  // TTS
  late FlutterTts _flutterTts;

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _startFixationPhase();
  }

  void _initSpeech() async {
    if (kIsWeb) {
      debugPrint("Reconocimiento de voz desactivado en Web por ahora.");
      return;
    }
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) => debugPrint('Speech Status: $status'),
        onError: (error) => debugPrint('Speech Error: $error'),
      );
      setState(() {});
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    if (kIsWeb) {
      debugPrint("TTS en modo simulado para Web.");
      return;
    }

    _flutterTts.setLanguage("es-ES");
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.5);

    _flutterTts.setCompletionHandler(() {
      if (mounted && _currentPhase == PreparationPhase.fixation) {
        _onReadingFinished();
      }
    });

    _flutterTts.setStartHandler(() {
      if (mounted) {
        debugPrint("TTS Started");
      }
    });
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _countdownTimer?.cancel();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  void _startFixationPhase() {
    setState(() {
      _currentPhase = PreparationPhase.fixation;
      _isVoiceControlActive = false;
      _readingProgress = 0.0;
      _countdown = 3;
      _countdownProgress = 0.0;
    });

    // Speak the text
    if (!kIsWeb) {
      _flutterTts.speak(_scriptText);
    }

    // Coordinate visual progress with expected duration (~2.5s for this string at 0.5 rate)
    // In a real app, we'd use setProgressHandler, but here we keep the smooth simulation
    const duration = Duration(milliseconds: 2800);
    const interval = Duration(milliseconds: 50);
    int steps = duration.inMilliseconds ~/ interval.inMilliseconds;
    int currentStep = 0;

    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(interval, (timer) {
      if (!mounted || _currentPhase != PreparationPhase.fixation) {
        timer.cancel();
        return;
      }
      setState(() {
        currentStep++;
        _readingProgress = (currentStep / steps).clamp(0.0, 1.0);
        if (currentStep >= steps) {
          timer.cancel();
          if (kIsWeb) {
            _onReadingFinished();
          }
        }
      });
    });
  }

  void _onReadingFinished() {
    // Wait 1 second before moving to Decision phase
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startDecisionPhase();
        _startListening();
      }
    });
  }

  void _startListening() async {
    if (_speechEnabled && !_speechToText.isListening) {
      await _speechToText.listen(onResult: _onSpeechResult, localeId: "es-ES");
      setState(() {});
    }
  }

  void _stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {});
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      if (result.finalResult) {
        _onVoiceCommand(_lastWords);
      }
    });
  }

  void _startDecisionPhase() {
    setState(() {
      _currentPhase = PreparationPhase.decision;
      _isVoiceControlActive = true;
      _countdown = 3;
      _countdownProgress = 0.0;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
          _countdownProgress += 0.33;
        } else {
          timer.cancel();
          _countdown = 0;
          _countdownProgress = 1.0;
          _onDecisionPhaseTimeout();
        }
      });
    });
  }

  void _onDecisionPhaseTimeout() {
    _stopListening();
    // Wait 1 second before restarting Phase 1
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _startFixationPhase();
    });
  }

  // Simulated Voice Command Handler
  void _onVoiceCommand(String command) {
    if (_currentPhase != PreparationPhase.decision) return;

    final l10n = AppLocalizations.of(context)!;
    final cmd = command.toLowerCase().trim();

    // English & Spanish commands
    if (cmd == l10n.record.toLowerCase() ||
        cmd == 'record' ||
        cmd == 'grabar') {
      _navigateToRecording();
    } else if (cmd == 'volver' || cmd == 'return' || cmd == 'back') {
      Navigator.pop(context);
    }
  }

  void _navigateToRecording() {
    _readingTimer?.cancel();
    _countdownTimer?.cancel();
    _flutterTts.stop();
    _stopListening();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildProgressSection(l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScriptHeader(l10n),
                    const SizedBox(height: 16),
                    _buildHighlightedScript(),
                    const SizedBox(height: 60),
                    _buildCentralVisual(l10n),
                  ],
                ),
              ),
            ),
            _buildFooter(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleBtn(Icons.arrow_back, () => Navigator.pop(context)),
          Text(
            l10n.preparation.toUpperCase(),
            style: const TextStyle(
              color: forest,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: forest),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildProgressSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.fragmentCount("1", "5").toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: forest.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              _buildVoiceIndicator(l10n),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.2,
              backgroundColor: forest.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(forest),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceIndicator(AppLocalizations l10n) {
    final active = _isVoiceControlActive;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? forest : Colors.grey[400],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          (active ? l10n.listening : l10n.waiting).toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active ? forest : Colors.grey[400],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildScriptHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Icon(Icons.volume_up, size: 18, color: forest.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Text(
          l10n.systemReads.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: forest.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedScript() {
    // Split text into two parts based on progress
    int charsToShow = (_scriptText.length * _readingProgress).round();
    String finishedText = _scriptText.substring(0, charsToShow);
    String remainingText = _scriptText.substring(charsToShow);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: finishedText,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: forest,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: remainingText,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: forest.withValues(alpha: 0.3),
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralVisual(AppLocalizations l10n) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Device Frame
          Container(
            width: 176,
            height: 288,
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -15,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundLight,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 16,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conditional Countdown Overlay
          if (_currentPhase == PreparationPhase.decision) _buildCountdown(l10n),

          if (_currentPhase == PreparationPhase.fixation)
            Icon(
              Icons.graphic_eq_rounded,
              size: 48,
              color: forest.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdown(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 128,
              height: 128,
              child: CircularProgressIndicator(
                value: _countdownProgress,
                strokeWidth: 2,
                backgroundColor: forest.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(forest),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              "$_countdown",
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: forest,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.getReady.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: forest.withValues(alpha: 0.4),
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceLight.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildVoiceControlBadge(l10n),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildControlBtn(
                      Icons.replay,
                      l10n.repeat,
                      56,
                      () => _startFixationPhase(),
                    ),
                    _buildRecordBtn(l10n.record),
                    _buildControlBtn(Icons.skip_next, l10n.next, 56, () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceControlBadge(AppLocalizations l10n) {
    final active = _isVoiceControlActive;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? forest.withValues(alpha: 0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? forest.withValues(alpha: 0.1) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.mic : Icons.mic_off,
            size: 14,
            color: active ? forest : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Text(
            (active ? l10n.voiceControlActive : l10n.voiceControlDisabled)
                .toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: active ? forest.withValues(alpha: 0.6) : Colors.grey[500],
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn(
    IconData icon,
    String label,
    double size,
    VoidCallback onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Icon(icon, color: forest.withValues(alpha: 0.4), size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"$label"'.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: forest.withValues(alpha: 0.3),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordBtn(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: forest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: forest.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _navigateToRecording,
            child: const Icon(
              Icons.fiber_manual_record,
              color: surfaceLight,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"$label"'.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: forest,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

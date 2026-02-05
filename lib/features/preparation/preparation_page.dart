import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../recording/recording_page.dart';

import '../new_project/models/script_analysis.dart';

enum PreparationPhase { fixation, decision }

class PreparationPage extends StatefulWidget {
  final ScriptAnalysis analysis;

  const PreparationPage({super.key, required this.analysis});

  @override
  State<PreparationPage> createState() => _PreparationPageState();
}

class _PreparationPageState extends State<PreparationPage> {
  // Using AppTheme colors for consistency

  // State
  PreparationPhase _currentPhase = PreparationPhase.fixation;
  bool _isVoiceControlActive = false;
  bool _isPaused = false;
  int _currentSegmentIndex = 0;

  // Phase 1: Fixation (Simulated reading)
  int _charsReadCount = 0;
  int _totalReadingTimeMs = 0;
  int _elapsedReadingTimeMs = 0;
  List<_HighlightEvent> _timeline = [];
  Timer? _readingTimer;
  String get _scriptText => widget.analysis.segments[_currentSegmentIndex].text;

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
      if (mounted) {
        if (_currentPhase == PreparationPhase.fixation) {
          _onReadingFinished();
        }
      }
    });

    _flutterTts.setStartHandler(() {
      if (mounted) {
        debugPrint("TTS Started");
      }
    });

    _flutterTts.setErrorHandler((msg) {
      // Handle error if needed
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

  void _startFixationTimer() {
    const interval = Duration(milliseconds: 20);
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(interval, (timer) {
      if (!mounted || _currentPhase != PreparationPhase.fixation || _isPaused) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedReadingTimeMs += interval.inMilliseconds;
        int newIndex = 0;
        for (var event in _timeline) {
          if (event.timeMs <= _elapsedReadingTimeMs) {
            newIndex = event.charIndex;
          } else {
            break;
          }
        }
        _charsReadCount = newIndex;
        if (_elapsedReadingTimeMs >= _totalReadingTimeMs) {
          timer.cancel();
          _onReadingFinished();
        }
      });
    });
  }

  void _startDecisionTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) {
        timer.cancel();
        return;
      }

      if (_countdown > 1) {
        setState(() {
          _countdown--;
          _countdownProgress += 0.33;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _countdownProgress = 1.0;
        });
        _onDecisionPhaseTimeout();
      }
    });
  }

  void _onDecisionPhaseTimeout() {
    _stopListening();
    if (!mounted) return;
    if (_isPaused) return;
    if (_currentPhase != PreparationPhase.decision) return;

    // Avanzamos al siguiente segmento (con bucle)
    setState(() {
      _currentSegmentIndex =
          (_currentSegmentIndex + 1) % widget.analysis.segments.length;
    });

    _startFixationPhase();
  }

  void _onVoiceCommand(String command) {
    if (_currentPhase != PreparationPhase.decision) return;
    final l10n = AppLocalizations.of(context)!;
    final cmd = command.toLowerCase().trim();
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

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _flutterTts.stop();
        _readingTimer?.cancel();
        _countdownTimer?.cancel();
      } else {
        if (_currentPhase == PreparationPhase.fixation) {
          _flutterTts.speak(_scriptText);
          _startFixationTimer();
        } else {
          _startDecisionTimer();
        }
      }
    });
  }

  void _startFixationPhase() {
    _buildReadingTimeline();

    setState(() {
      _currentPhase = PreparationPhase.fixation;
      _isVoiceControlActive = false;
      _charsReadCount = 0;
      _elapsedReadingTimeMs = 0;
      _countdown = 3;
      _countdownProgress = 0.0;
    });

    // Speak the text
    if (!kIsWeb) {
      _flutterTts.speak(_scriptText);
    }

    _startFixationTimer();
  }

  void _buildReadingTimeline() {
    final segment = widget.analysis.segments[_currentSegmentIndex];
    final double ppm = segment.editMetadata.wpm;
    final String text = segment.text;
    final pauseRefs = _parseReferences(segment.direction.pauses);
    final punctuationRegex = RegExp(r'[.,;:!?]');

    List<int> pauseIndices = [];
    for (var ref in pauseRefs) {
      int start = 0;
      while ((start = text.indexOf(ref, start)) != -1) {
        int endOfRef = start + ref.length;
        if (endOfRef < text.length &&
            punctuationRegex.hasMatch(text[endOfRef])) {
          pauseIndices.add(endOfRef + 1);
        } else {
          pauseIndices.add(endOfRef);
        }
        start += ref.length;
      }
    }
    pauseIndices = pauseIndices.toSet().toList()..sort();

    final words = text.split(RegExp(r'\s+'));
    final msPerWord = (60000 / ppm).round();

    _timeline = [];
    int currentTime = 0;
    int currentTextPos = 0;

    _timeline.add(_HighlightEvent(timeMs: 0, charIndex: 0));

    for (var word in words) {
      if (word.isEmpty) continue;
      int wordStart = text.indexOf(word, currentTextPos);
      if (wordStart == -1) continue;
      int wordEnd = wordStart + word.length;

      currentTime += msPerWord;
      _timeline.add(_HighlightEvent(timeMs: currentTime, charIndex: wordEnd));

      bool hasPause = pauseIndices.any(
        (p) => p >= currentTextPos && p <= wordEnd + 1,
      );
      if (hasPause) {
        currentTime += 100;
        _timeline.add(_HighlightEvent(timeMs: currentTime, charIndex: wordEnd));
      }

      currentTextPos = wordEnd;
    }

    _totalReadingTimeMs = currentTime;
  }

  void _onReadingFinished() {
    if (_isPaused) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isPaused) {
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
    _startDecisionTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildProgressSection(l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleBtn(Icons.arrow_back, () => Navigator.pop(context)),
          Text(
            l10n.preparation.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.forest,
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
        color: AppTheme.surfaceColor,
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
        icon: Icon(icon, size: 20, color: AppTheme.forest),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildProgressSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "FRAGMENTO ${_currentSegmentIndex + 1} DE ${widget.analysis.segments.length}"
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forest.withValues(alpha: 0.6),
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
              value:
                  (_currentSegmentIndex + 1) / widget.analysis.segments.length,
              backgroundColor: AppTheme.forest.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.forest),
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
            color: active ? AppTheme.forest : Colors.grey[400],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          (active ? l10n.listening : l10n.waiting).toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active ? AppTheme.forest : Colors.grey[400],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildScriptHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          "SEGMENTO A GRABAR",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.forest.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedScript() {
    final segment = widget.analysis.segments[_currentSegmentIndex];
    final text = segment.text;
    final emphasisRefs = _parseReferences(segment.direction.emphasis);
    final pauseRefs = _parseReferences(segment.direction.pauses);

    // Identificar rangos de énfasis (negrita)
    List<RangeValues> emphasisRanges = [];
    for (var ref in emphasisRefs) {
      int start = 0;
      while ((start = text.indexOf(ref, start)) != -1) {
        emphasisRanges.add(
          RangeValues(start.toDouble(), (start + ref.length).toDouble()),
        );
        start += ref.length;
      }
    }

    // Identificar puntos de pausa
    List<int> pausePoints = [];
    final punctuationRegex = RegExp(r'[.,;:!?]');
    for (var ref in pauseRefs) {
      int start = 0;
      while ((start = text.indexOf(ref, start)) != -1) {
        int endOfRef = start + ref.length;
        if (endOfRef < text.length &&
            punctuationRegex.hasMatch(text[endOfRef])) {
          pausePoints.add(endOfRef + 1);
        } else {
          pausePoints.add(endOfRef);
        }
        start += ref.length;
      }
    }
    pausePoints = pausePoints.toSet().toList()..sort();

    // Construir los spans usando marcadores
    final Set<int> markers = {0, text.length};
    for (var r in emphasisRanges) {
      markers.add(r.start.toInt());
      markers.add(r.end.toInt());
    }
    for (var p in pausePoints) {
      markers.add(p);
    }

    final List<int> sortedMarkers = markers.toList()..sort();
    final List<InlineSpan> spans = [];

    // Lógica de progreso de lectura (solo para el color base)
    int charsToShow = _charsReadCount;

    for (int i = 0; i < sortedMarkers.length - 1; i++) {
      int start = sortedMarkers[i];
      int end = sortedMarkers[i + 1];

      if (pausePoints.contains(start)) {
        spans.add(_buildPauseIcon());
      }

      if (start < end) {
        String chunk = text.substring(start, end);
        bool isBold = emphasisRanges.any(
          (r) => start >= r.start && end <= r.end,
        );

        // Determinar si este chunk ya fue "leído"
        bool isRead = start < charsToShow;
        final Color baseColor = isBold
            ? const Color(0xFFC2410C)
            : AppTheme.forest;

        spans.add(
          TextSpan(
            text: chunk,
            style: TextStyle(
              fontSize: 30,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              height: 1.3,
              letterSpacing: -0.5,
              color: isRead ? baseColor : baseColor.withValues(alpha: 0.5),
            ),
          ),
        );
      }
    }

    if (pausePoints.contains(text.length)) {
      spans.add(_buildPauseIcon());
    }

    final bool isDisabled = _currentPhase == PreparationPhase.decision;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDisabled ? 0.3 : 1.0,
      child: Text.rich(TextSpan(children: spans)),
    );
  }

  WidgetSpan _buildPauseIcon() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.pause_rounded,
          size: 16,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  List<String> _parseReferences(String input) {
    if (input.isEmpty) return [];
    final regex = RegExp(r"'([^']*)'");
    return regex.allMatches(input).map((m) => m.group(1)!).toList();
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
              color: AppTheme.surfaceColor,
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
                  color: AppTheme.backgroundLight,
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
            _SoundWaveAnimation(color: AppTheme.forest, isPaused: _isPaused),
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
                backgroundColor: AppTheme.forest.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.forest,
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              "$_countdown",
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: AppTheme.forest,
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
            color: AppTheme.forest.withValues(alpha: 0.4),
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    // El footer se habilita y cambia a verde oscuro durante toda la fase de decisión, pausada o no.

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppTheme.backgroundLight,
            AppTheme.backgroundLight.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVoiceControlBadge(l10n),
          const SizedBox(height: 24),
          Row(
            children: [
              // 1. Regresar (Izquierda)
              Expanded(
                child: _buildControlBtn(
                  Icons.arrow_back_ios_new_rounded,
                  "Regresar",
                  56,
                  (_currentPhase == PreparationPhase.decision)
                      ? () => Navigator.pop(context)
                      : null,
                  isSpecial: true,
                  activeState: (_currentPhase == PreparationPhase.decision),
                ),
              ),
              // 2. Grabar (Centro)
              Expanded(
                child: _buildRecordBtn(
                  "Grabar",
                  enabled: (_currentPhase == PreparationPhase.decision),
                  activeState: (_currentPhase == PreparationPhase.decision),
                ),
              ),
              // 3. Pausar (Derecha)
              Expanded(
                child: _buildControlBtn(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  _isPaused ? "Continuar" : "Pausar",
                  56,
                  (_currentPhase == PreparationPhase.decision)
                      ? _togglePause
                      : null,
                  activeState: (_currentPhase == PreparationPhase.decision),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControlBadge(AppLocalizations l10n) {
    final active = _isVoiceControlActive;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.forest.withValues(alpha: 0.05)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppTheme.forest.withValues(alpha: 0.1)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.mic : Icons.mic_off,
            size: 14,
            color: active ? AppTheme.forest : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Text(
            (active ? l10n.voiceControlActive : l10n.voiceControlDisabled)
                .toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: active
                  ? AppTheme.forest.withValues(alpha: 0.6)
                  : Colors.grey[500],
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
    VoidCallback? onTap, {
    bool isSpecial = false,
    bool activeState = false,
  }) {
    final bool isActuallyEnabled = onTap != null;
    // tanto los iconos como los textos deben estar en color verde oscuro (cuando activo)
    // tanto los iconos como los textos deben estar en color verde gris (cuando desactivo)
    final Color currentColor = activeState
        ? AppTheme.forest
        : AppTheme.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActuallyEnabled
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              if (isActuallyEnabled)
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
            child: Icon(icon, color: currentColor, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: currentColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordBtn(
    String label, {
    bool enabled = true,
    bool activeState = false,
  }) {
    // tanto los iconos como los textos deben estar en color verde oscuro (cuando activo)
    // tanto los iconos como los textos deben estar en color verde gris (cuando desactivo)
    final Color currentColor = activeState
        ? AppTheme.forest
        : AppTheme.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: AppTheme.forest.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? _navigateToRecording : null,
            child: Icon(
              Icons.fiber_manual_record,
              color: currentColor,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: currentColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _HighlightEvent {
  final int timeMs;
  final int charIndex;

  _HighlightEvent({required this.timeMs, required this.charIndex});
}

class _SoundWaveAnimation extends StatefulWidget {
  final Color color;
  final bool isPaused;
  const _SoundWaveAnimation({required this.color, this.isPaused = false});

  @override
  State<_SoundWaveAnimation> createState() => _SoundWaveAnimationState();
}

class _SoundWaveAnimationState extends State<_SoundWaveAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int _barCount = 15;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_barCount, (index) {
      // Calculamos una duración más corta para dar más velocidad
      final int offset = (index - _barCount ~/ 2).abs();
      return AnimationController(
        duration: Duration(milliseconds: 300 + (offset * 50)),
        vsync: this,
      );
    });

    _animations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;

      // Las barras del centro tienen más rango de movimiento
      final centerFactor =
          1.0 - ((index - _barCount ~/ 2).abs() / (_barCount / 1.5));
      final double beginValue = 0.1;
      final double endValue = (0.3 + (0.7 * centerFactor)).clamp(0.2, 1.0);

      return Tween<double>(begin: beginValue, end: endValue).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutSine),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 20), () {
        if (mounted && !widget.isPaused) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _SoundWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        for (var c in _controllers) {
          c.stop();
        }
      } else {
        for (var c in _controllers) {
          c.repeat(reverse: true);
        }
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 80,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final double value = _animations[index].value;
              final double height = 8 + (60 * value);
              final double opacity = (0.1 + (0.4 * value)).clamp(0.1, 0.5);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3.5,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    if (!widget.isPaused)
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

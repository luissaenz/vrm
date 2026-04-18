import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import '../../core/theme.dart';
import '../new_project/models/script_analysis.dart';

import 'models/recording_state.dart';
import 'models/voice_indicator_state.dart';
import 'models/session_data.dart';
import 'widgets/voice_indicator.dart';
import 'widgets/telepronter.dart';
import 'recording_end_page.dart';
import 'clip_review_page.dart';
import 'services/voice_command_service.dart';
import 'services/permission_service.dart';
import 'services/camera_service.dart';
import 'services/clip_storage_service.dart';
import 'services/recording_manager.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:video_player/video_player.dart';
import 'dart:io';

class RecordingPage extends StatefulWidget {
  final ScriptAnalysis analysis;
  final int currentFragmentIndex;
  final String projectId;

  const RecordingPage({
    super.key,
    required this.analysis,
    this.currentFragmentIndex = 0,
    required this.projectId,
  });

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countdownController;
  late Animation<double> _countdownProgress;

  RecordingState _recordingState = RecordingState.idle;
  late int _activeFragmentIndex;
  final int _currentWordIndex = 0;
  int _countdownValue = 3;
  Timer? _countdownTimer;

  late AnimationController _menuController;
  late Animation<Offset> _menuAnimation;

  // Menu Features State
  bool _isGridActive = true;
  bool _isStreetModeActive = false;
  bool _isGhostActive = false;
  bool _isLightActive = false;
  bool _isMirrorActive = false;
  bool _isVoiceControlActive = true;
  bool _isFocusLocked = false;
  bool _isMonitorActive = false;
  double _teleprompterFontSize = 24.0;
  double _readingSpeed = 150.0;
  double _screenBrightness = 0.8;

  final VoiceCommandService _voiceService = VoiceCommandService();
  final PermissionService _permissionService = PermissionService();

  VoiceIndicatorState _voiceState = VoiceIndicatorState.passive;
  String? _detectedCommand;
  StreamSubscription? _voiceStateSub;
  StreamSubscription? _voiceCommandSub;

  // Recording services (replace direct CameraController usage)
  late CameraService _cameraService;
  late ClipStorageService _clipStorageService;
  RecordingManager? _recordingManager;
  SessionData? _sessionData;

  // Ghost Mode State
  VideoPlayerController? _ghostController;

  bool _isCameraInitialized = false;
  bool _isProcessingRecording = false;
  bool _hasPermissionError = false;
  String? _cameraInitError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _countdownProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _menuAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _menuController, curve: Curves.easeOutCubic),
        );

    _activeFragmentIndex = widget.currentFragmentIndex;
    _menuPageController = PageController();

    // Initialize services
    _cameraService = CameraService();
    _clipStorageService = ClipStorageService(projectId: widget.projectId);

    // Initialize SessionData eagerly in initState to prevent data loss
    // from state rebuilds (rotation, memory pressure) before recording starts
    _sessionData = SessionData(
      projectId: widget.projectId,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );

    // Register lifecycle observer for background handling
    WidgetsBinding.instance.addObserver(this);

    // Check permissions first
    _checkPermissionsAndInitCamera();

    _initVoiceCommands();
  }

  /// Check permissions and initialize camera.
  Future<void> _checkPermissionsAndInitCamera() async {
    final granted = await _permissionService.checkPermissions();
    if (!granted) {
      final requested = await _permissionService.requestPermissions();
      if (!requested) {
        if (mounted) {
          setState(() => _hasPermissionError = true);
        }
        return;
      }
    }

    await _initCamera();
  }

  /// Initialize camera using CameraService.
  Future<void> _initCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraInitError = null;
        });
        _applyHardwareSettings(); // Aplicar ajustes iniciales
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraInitError = e.toString();
        });
      }
    }
  }

  late PageController _menuPageController;
  int _currentMenuPage = 0;

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _voiceStateSub?.cancel();
    _voiceCommandSub?.cancel();
    _voiceService.stopService();
    _recordingManager?.dispose();
    _cameraService.dispose();
    _menuPageController.dispose();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _countdownController.dispose();
    _menuController.dispose();
    _ghostController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background — stop recording and save partial clip
      _handleBackgroundTransition();
    }
  }

  /// Handles app going to background during recording.
  /// Stops recording and saves whatever was captured as a partial clip.
  Future<void> _handleBackgroundTransition() async {
    if (_recordingManager == null || !_recordingManager!.isRecording) {
      return;
    }

    debugPrint(
      '[RecordingPage] App paused during recording — saving partial clip',
    );

    try {
      final result = await _recordingManager!.stopAndSavePartial();
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.idle;
          _isProcessingRecording = false;
        });

        // Show error feedback if partial save failed
        if (result.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Hubo un problema al guardar el clip parcial. Es posible que se haya perdido.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[RecordingPage] Failed to save partial clip: $e');
      // Force cleanup
      _isProcessingRecording = false;
      if (_cameraService.isRecording) {
        try {
          await _cameraService.stopRecording();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.idle;
        });
      }
    }
  }

  void _initVoiceCommands() {
    _voiceService.init().then((_) {
      _voiceStateSub = _voiceService.stateStream.listen((state) {
        if (mounted) setState(() => _voiceState = state);
      });

      _voiceCommandSub = _voiceService.commandStream.listen((command) {
        if (mounted) {
          setState(() => _detectedCommand = command.toUpperCase());
          _handleVoiceCommand(command);
        }
      });

      if (_isVoiceControlActive) {
        _voiceService.startService();
      }
    });
  }

  void _handleVoiceCommand(String command) {
    final cmd = command.toLowerCase().trim();
    debugPrint('[Lumis Voice] Ejecutando comando: $cmd');

    if (cmd.contains('grabar') || cmd.contains('record')) {
      if (_recordingState == RecordingState.idle) {
        _startCountdown();
      }
    } else if ((cmd.contains('stop') ||
            cmd.contains('detener') ||
            cmd.contains('parar')) &&
        (_recordingState == RecordingState.recording ||
            _recordingState == RecordingState.commandRecorded)) {
      _stopRecording();
    } else if (cmd.contains('volver') ||
        cmd.contains('atrás') ||
        cmd.contains('back')) {
      if (_recordingState == RecordingState.teleprompterSettings) {
        setState(() => _recordingState = RecordingState.menu);
      } else {
        Navigator.of(context).pop();
      }
    } else if (cmd.contains('siguiente') || cmd.contains('next')) {
      if (_activeFragmentIndex < widget.analysis.segments.length - 1) {
        setState(() {
          _activeFragmentIndex++;
        });
        _updateGhostController();
      }
    } else if (cmd.contains('grilla') || cmd.contains('cuadrícula')) {
      setState(() => _isGridActive = !_isGridActive);
    } else if (cmd.contains('menú') || cmd.contains('configurar')) {
      if (_recordingState == RecordingState.idle) {
        _voiceService.stopService();
        _menuController.forward();
      }
    } else if (cmd.contains('calle') || cmd.contains('ruido')) {
      setState(() => _isStreetModeActive = !_isStreetModeActive);
      _applyHardwareSettings();
    } else if (cmd.contains('fantasma') || cmd.contains('ghost')) {
      setState(() => _isGhostActive = !_isGhostActive);
      _updateGhostController();
    } else if (cmd.contains('luz') || cmd.contains('flash')) {
      setState(() => _isLightActive = !_isLightActive);
      _applyHardwareSettings();
    } else if (cmd.contains('espejo') || cmd.contains('mirror')) {
      setState(() => _isMirrorActive = !_isMirrorActive);
    } else if (cmd.contains('enfoque') || cmd.contains('foco')) {
      setState(() => _isFocusLocked = !_isFocusLocked);
      _applyHardwareSettings();
    } else if (cmd.contains('monitor') || cmd.contains('audio')) {
      setState(() => _isMonitorActive = !_isMonitorActive);
    } else if (cmd.contains('teleprompter') ||
        cmd.contains('ajustes') ||
        cmd.contains('texto')) {
      setState(() => _recordingState = RecordingState.teleprompterSettings);
    } else if (cmd.contains('más grande') || cmd.contains('subir texto')) {
      setState(
        () => _teleprompterFontSize = min(30.0, _teleprompterFontSize + 1.0),
      );
    } else if (cmd.contains('más pequeño') ||
        cmd.contains('bajar texto') ||
        cmd.contains('más chico')) {
      setState(
        () => _teleprompterFontSize = max(20.0, _teleprompterFontSize - 1.0),
      );
    } else if (cmd.contains('más rápido') || cmd.contains('subir velocidad')) {
      setState(() => _readingSpeed = min(300, _readingSpeed + 20));
    } else if (cmd.contains('más lento') || cmd.contains('bajar velocidad')) {
      setState(() => _readingSpeed = max(50, _readingSpeed - 20));
    } else if (cmd.contains('más brillo') || cmd.contains('subir luz')) {
      setState(() => _screenBrightness = min(1.0, _screenBrightness + 0.1));
    } else if (cmd.contains('menos brillo') || cmd.contains('bajar luz')) {
      setState(() => _screenBrightness = max(0.1, _screenBrightness - 0.1));
    } else if (cmd.contains('regrabar') || cmd.contains('repeat')) {
      if (_recordingState == RecordingState.idle) {
        _startCountdown();
      }
    }
  }

  bool get _isRecordingActive =>
      _recordingState == RecordingState.recording ||
      _recordingState == RecordingState.commandRecorded;

  void _startCountdown() {
    setState(() {
      _recordingState = RecordingState.countdown;
      _countdownValue = 3;
    });

    _voiceService.stopService();

    // Start first ring animation
    _countdownController.forward(from: 0.0);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
        // Restart ring animation for next number
        _countdownController.forward(from: 0.0);
      } else {
        timer.cancel();
        _startActualRecording();
      }
    });
  }

  void _startActualRecording() async {
    if (_isProcessingRecording) return;

    // SessionData is already initialized in initState
    // Initialize RecordingManager lazily on first use
    _recordingManager ??= RecordingManager(
      camera: _cameraService,
      storage: _clipStorageService,
      sessionData: _sessionData!,
    );

    // Check storage space before starting
    final hasSpace = await _clipStorageService.hasFreeSpace();
    if (!hasSpace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Almacenamiento insuficiente. Libera espacio e intenta de nuevo.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // Reset to idle since countdown already fired
      setState(() {
        _recordingState = RecordingState.idle;
      });
      return;
    }

    setState(() {
      _isProcessingRecording = true;
      _recordingState = RecordingState.recording;
    });
    _countdownController.stop();

    try {
      await _recordingManager!.startRecording(_activeFragmentIndex);
      setState(() {
        _isProcessingRecording = _recordingManager!.isProcessing;
      });
    } catch (e) {
      debugPrint('[RecordingPage] Failed to start recording: $e');
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.idle;
          _isProcessingRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar grabación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopRecording() async {
    if (_recordingManager == null || !_recordingManager!.isRecording) {
      // Safety fallback: just reset state
      setState(() {
        _recordingState = RecordingState.idle;
      });
      return;
    }

    setState(() {
      _isProcessingRecording = true;
    });

    try {
      final clipPath = await _recordingManager!.stopRecording();

      if (mounted) {
        setState(() {
          _recordingState = RecordingState.idle;
          _isProcessingRecording = false;
        });

        // Navegar a página de revisión
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClipReviewPage(
              clipPath: clipPath,
              projectId: widget.projectId,
              analysis: widget.analysis,
              currentFragmentIndex: _activeFragmentIndex,
              recordingManager: _recordingManager!,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[RecordingPage] Failed to stop recording: $e');
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.idle;
          _isProcessingRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el clip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Aplica los ajustes de hardware (luz, enfoque, exposiciÃ³n) segÃºn el estado actual.
  Future<void> _applyHardwareSettings() async {
    if (!_isCameraInitialized) return;

    try {
      // 1. Flash / Luz (Modo Torch para video)
      await _cameraService.setFlashMode(
        _isLightActive ? FlashMode.torch : FlashMode.off,
      );

      // 2. Street Mode logic (Lockers)
      if (_isStreetModeActive) {
        // Bloqueamos ambos para evitar cambios bruscos en exteriores
        await _cameraService.setExposureMode(ExposureMode.locked);
        await _cameraService.setFocusMode(FocusMode.locked);
      } else {
        // 3. Enfoque Manual / Auto
        await _cameraService.setFocusMode(
          _isFocusLocked ? FocusMode.locked : FocusMode.auto,
        );
        // Si no es calle, permitimos exposiciÃ³n automÃ¡tica
        await _cameraService.setExposureMode(ExposureMode.auto);
      }
    } catch (e) {
      debugPrint('[RecordingPage] Error aplicando ajustes de hardware: $e');
    }
  }

  /// Actualiza el controlador de Ghost Mode cargando el clip aprobado del fragmento.
  Future<void> _updateGhostController() async {
    if (!mounted) return;

    // Detener y liberar anterior
    if (_ghostController != null) {
      final oldController = _ghostController!;
      _ghostController = null;
      setState(() {}); // UI Update to hide ghost
      await oldController.dispose();
    }

    if (!_isGhostActive || _sessionData == null) return;

    final path = _sessionData!.approvedClips[_activeFragmentIndex];
    if (path == null) return;

    final file = File(path);
    if (!await file.exists()) {
      debugPrint('[RecordingPage] Ghost file not found: $path');
      return;
    }

    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(false); // Ver primer frame
      
      if (mounted && _isGhostActive) {
        setState(() {
          _ghostController = controller;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('[RecordingPage] Error initializing ghost controller: $e');
    }
  }

  Widget _buildCountdownOverlay() {
    return Stack(
      children: [
        // Black overlay (60% opacity)
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.6)),
        ),

        // Countdown center
        Center(
          child: SizedBox(
            width: 256,
            height: 256,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                AnimatedBuilder(
                  animation: _countdownProgress,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(256, 256),
                      painter: CountdownRingPainter(
                        progress: _countdownProgress.value,
                      ),
                    );
                  },
                ),

                // Countdown number with glow
                Text(
                  '$_countdownValue',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFragments = widget.analysis.segments.length;
    final currentFragment = _activeFragmentIndex + 1;
    final isCountingDown = _recordingState == RecordingState.countdown;

    if (_recordingState == RecordingState.finished) {
      return const RecordingEndPage();
    }

    // Show error screen if permissions were denied
    if (_hasPermissionError) {
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
                const SizedBox(height: 24),
                const Text(
                  'Cámara no disponible',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'VRM necesita acceso a la cámara y al micrófono. '
                  'Actívalos en Configuración.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  child: const Text('Ir a Configuración'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Volver',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading screen if camera is not ready
    if (!_isCameraInitialized && _cameraInitError == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Preparando cámara...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // Show camera init error
    if (_cameraInitError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error de cámara',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _cameraInitError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _initCamera,
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async => openAppSettings(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white24,
                  ),
                  child: const Text('Configuración'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          // Background layer (z-0)
          _buildBackground(),

          // Grid overlay (z-10)
          _buildGridOverlay(),

          // UI Elements (z-40) with conditional dimming
          AnimatedOpacity(
            opacity: isCountingDown ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(currentFragment, totalFragments),

                  // Script text card
                  Telepronter(
                    analysis: widget.analysis,
                    activeFragmentIndex: _activeFragmentIndex,
                    currentWordIndex: _currentWordIndex,
                    fontSize: _teleprompterFontSize,
                    readingSpeed: _readingSpeed,
                    isScrolling: _recordingState == RecordingState.recording,
                  ),

                  // Spacer
                  const Spacer(),

                  // Bottom controls
                  _buildBottomControls(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Countdown overlay (shown only during countdown)
          if (isCountingDown) _buildCountdownOverlay(),

          // Menu overlay (z-50)
          _buildMenuOverlay(),

          // Teleprompter Settings overlay (z-60)
          _buildTeleprompterSettingsOverlay(),

          // Screen brightness overlay
          if (_screenBrightness < 1.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 1.0 - _screenBrightness,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            if (_isCameraInitialized && _cameraService.controller != null)
              Positioned.fill(
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      Center(child: CameraPreview(_cameraService.controller!)),
                      if (_isGhostActive &&
                          _ghostController != null &&
                          _ghostController!.value.isInitialized)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.2, // SUPUESTO: 0.2 opacidad para efecto fantasma
                            child: AspectRatio(
                              aspectRatio: _ghostController!.value.aspectRatio,
                              child: VideoPlayer(_ghostController!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              // Fallback image while loading
              Opacity(
                opacity: 0.5,
                child: Image.network(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=1200&fit=crop',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    if (!_isGridActive) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.3,
          child: Stack(
            children: [
              // Vertical lines
              Row(
                children: [
                  const Spacer(),
                  Container(width: 1, color: Colors.white),
                  const Spacer(),
                  Container(width: 1, color: Colors.white),
                  const Spacer(),
                ],
              ),
              // Horizontal lines
              Column(
                children: [
                  const Spacer(),
                  Container(height: 1, color: Colors.white),
                  const Spacer(),
                  Container(height: 1, color: Colors.white),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(int current, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          _buildGlassButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
            isEnabled: !_isRecordingActive,
          ),

          // Fragment counter
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _recordingState == RecordingState.recording
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _recordingState == RecordingState.recording
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_recordingState == RecordingState.recording) ...[
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha:
                                0.5 +
                                (0.5 * (1.4 - _pulseAnimation.value) / 0.4),
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _recordingState == RecordingState.recording
                      ? 'GRABANDO FRAGMENTO $current / $total'
                      : 'FRAGMENTO $current / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                  ),
                ),
              ],
            ),
          ),

          // Camera switch button
          _buildGlassButton(
            icon: Icons.cameraswitch,
            onTap: () async {
              if (_isRecordingActive || _isProcessingRecording) return;
              try {
                setState(() => _isCameraInitialized = false);
                await _recordingManager?.switchCamera();
                if (mounted) {
                  setState(() => _isCameraInitialized = true);
                }
              } catch (e) {
                debugPrint('[RecordingPage] Failed to switch camera: $e');
              }
            },
            isEnabled: !_isRecordingActive,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isEnabled ? 1.0 : 0.3,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Voice indicator
          if (!_isRecordingActive) ...[
            _buildVoiceIndicator(),
            const SizedBox(height: 32),
          ],

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Grid button
              _buildSideButton(
                icon: Icons.grid_view,
                label: 'GRILLA',
                isActive: _isGridActive,
                onTap: () {
                  setState(() {
                    _isGridActive = !_isGridActive;
                  });
                },
                isEnabled: !_isRecordingActive,
              ),

              // Record button
              _buildRecordButton(),

              // Menu button
              _buildSideButton(
                icon: Icons.menu,
                label: 'MENÚ',
                onTap: () {
                  _voiceService.stopService();
                  _menuController.forward();
                },
                isEnabled: !_isRecordingActive,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
    bool isActive = false,
  }) {
    final primaryColor = context.colorScheme.primary;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isEnabled ? 1.0 : 0.4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? primaryColor
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isActive ? primaryColor : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? primaryColor.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceIndicator() {
    return VRMVoiceIndicator(
      state: _isRecordingActive ? VoiceIndicatorState.disabled : _voiceState,
      pulseAnimation: _pulseAnimation,
      detectedCommand: _detectedCommand,
    );
  }

  void _closeMenu() {
    _menuController.reverse().then((_) {
      if (mounted) {
        if (_isVoiceControlActive) {
          _voiceService.startService();
        }
        setState(() {
          _recordingState = RecordingState.idle;
        });
      }
    });
  }

  Widget _buildMenuOverlay() {
    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, child) {
        if (_menuController.isDismissed &&
            _recordingState != RecordingState.menu) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Backdrop dimming/tap to close
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _menuController.value,
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
            ),

            // Bottom Menu Sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _menuAnimation,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.44,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(56),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white10, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 60,
                        spreadRadius: 20,
                        offset: Offset(0, -20),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 10) {
                        _closeMenu();
                      }
                    },
                    child: Column(
                      children: [
                        // Top handle area
                        Container(
                          width: double.infinity,
                          color: Colors.transparent,
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),

                        // Header with "Cerrar" and status
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _closeMenu,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.expand_more,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CERRAR',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '64.2 GB',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.battery_5_bar,
                                    size: 18,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Grid of options with PageView
                        Expanded(
                          child: PageView(
                            controller: _menuPageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentMenuPage = index;
                              });
                            },
                            children: [
                              // Page 1 (6 items)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 24,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildMenuFeature(
                                      icon: Icons.grid_view,
                                      label: 'GRILLA',
                                      isActive: _isGridActive,
                                      onTap: () {
                                        setState(
                                          () => _isGridActive = !_isGridActive,
                                        );
                                      },
                                    ),
                                    _buildMenuFeature(
                                      icon: Icons.text_snippet,
                                      label: 'TELEPRONTER',
                                      isActive:
                                          _recordingState ==
                                          RecordingState.teleprompterSettings,
                                      onTap: () {
                                        setState(() {
                                          _recordingState = RecordingState
                                              .teleprompterSettings;
                                        });
                                      },
                                    ),
                                    _buildMenuFeature(
                                      icon: Icons.directions_run,
                                      label: 'CALLE',
                                      isActive: _isStreetModeActive,
                                      onTap: () {
                                        setState(
                                          () => _isStreetModeActive =
                                              !_isStreetModeActive,
                                        );
                                        _applyHardwareSettings();
                                      },
                                    ),
                                    _buildMenuFeature(
                                      icon: Icons.copy,
                                      label: 'FANTASMA',
                                      isActive: _isGhostActive,
                                      onTap: () {
                                        setState(
                                          () => _isGhostActive = !_isGhostActive,
                                        );
                                        _updateGhostController();
                                      },
                                    ),
                                    _buildMenuFeature(
                                      icon: Icons.flashlight_on,
                                      label: 'LUZ',
                                      isActive: _isLightActive,
                                      onTap: () {
                                        setState(
                                          () => _isLightActive = !_isLightActive,
                                        );
                                        _applyHardwareSettings();
                                      },
                                    ),
                                    _buildMenuFeature(
                                      icon: Icons.flip,
                                      label: 'ESPEJO',
                                      isActive: _isMirrorActive,
                                      onTap: () => setState(
                                        () =>
                                            _isMirrorActive = !_isMirrorActive,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Page 2 (Remaining items)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 24,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildMenuFeature(
                                      icon: Icons.filter_center_focus,
                                      label: 'ENFOQUE',
                                      isActive: _isFocusLocked,
                                      onTap: () {
                                        setState(
                                          () => _isFocusLocked = !_isFocusLocked,
                                        );
                                        _applyHardwareSettings();
                                      },
                                    ),
                                    _buildMenuFeature(
                                      icon: Icons.headphones,
                                      label: 'MONITOR',
                                      isActive: _isMonitorActive,
                                      onTap: () => setState(
                                        () => _isMonitorActive =
                                            !_isMonitorActive,
                                      ),
                                    ),
                                    _buildMenuFeature(
                                      icon: Icons.mic,
                                      label: 'VOZ',
                                      isActive: _isVoiceControlActive,
                                      onTap: () {
                                        setState(() {
                                          _isVoiceControlActive =
                                              !_isVoiceControlActive;
                                        });
                                        if (_isVoiceControlActive) {
                                          _voiceService.startService();
                                        } else {
                                          _voiceService.stopService();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Pagination dots
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _menuPageController.animateToPage(
                                  0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                ),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentMenuPage == 0
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: _currentMenuPage == 0
                                        ? [
                                            const BoxShadow(
                                              color: Colors.white,
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _menuPageController.animateToPage(
                                  1,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                ),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentMenuPage == 1
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: _currentMenuPage == 1
                                        ? [
                                            const BoxShadow(
                                              color: Colors.white,
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeleprompterSettingsOverlay() {
    if (_recordingState != RecordingState.teleprompterSettings) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _recordingState = RecordingState.menu),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),

        // Bottom Sheet
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
              border: Border(top: BorderSide(color: Colors.white10, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 60,
                  spreadRadius: 20,
                  offset: Offset(0, -20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                const Text(
                  'AJUSTES DE TELEPROMPTER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 48),

                // Text Size Slider
                _buildSettingsSlider(
                  icon: Icons.format_size,
                  label: 'TAMAÑO DEL TEXTO',
                  value: _teleprompterFontSize,
                  min: 20,
                  max: 30,
                  unit: 'PT',
                  onChanged: (val) =>
                      setState(() => _teleprompterFontSize = val),
                ),
                const SizedBox(height: 36),

                // Reading Speed Slider
                _buildSettingsSlider(
                  icon: Icons.speed,
                  label: 'VELOCIDAD DE LECTURA',
                  value: _readingSpeed,
                  min: 50,
                  max: 300,
                  unit: 'PPM',
                  onChanged: (val) => setState(() => _readingSpeed = val),
                ),
                const SizedBox(height: 36),

                // Brightness Slider
                _buildSettingsSlider(
                  icon: Icons.light_mode,
                  label: 'BRILLO DE PANTALLA',
                  value: _screenBrightness * 100,
                  min: 0,
                  max: 100,
                  unit: '%',
                  onChanged: (val) =>
                      setState(() => _screenBrightness = val / 100),
                ),
                const SizedBox(height: 48),

                // Accept Button
                GestureDetector(
                  onTap: () {
                    _menuController.reverse();
                    setState(() {
                      _recordingState = RecordingState.idle;
                    });
                  },

                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D4B44),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D4B44).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'ACEPTAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            Text(
              '${value.round()}$unit',
              style: const TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 10,
            activeTrackColor: const Color(0xFF2D4B44),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildMenuFeature({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isActive
                  ? colors.cardBackground
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? primaryColor : colors.cardBorder,
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 20,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive
                  ? primaryColor
                  : Colors.white.withValues(alpha: 0.9),
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    final isCountingDown = _recordingState == RecordingState.countdown;
    final isRecording = _recordingState == RecordingState.recording;
    final isCommandRecorded = _recordingState == RecordingState.commandRecorded;
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        // Debounce: ignore if processing
        if (_isProcessingRecording) return;

        if (_recordingState == RecordingState.idle) {
          _startCountdown();
        } else if (_recordingState == RecordingState.recording ||
            _recordingState == RecordingState.commandRecorded) {
          _stopRecording();
        }
      },
      child: SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer border
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCommandRecorded
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.5)
                      : (isRecording
                            ? Colors.white.withValues(alpha: 0.2)
                            : (context.isDarkMode
                                  ? colors.cardBorder.withValues(
                                      alpha: isCountingDown ? 0.05 : 0.2,
                                    )
                                  : Colors.white.withValues(alpha: 0.1))),
                  width: isCommandRecorded ? 2 : 1,
                ),
              ),
            ),

            // White circle with shadow
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isCommandRecorded
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.white.withValues(
                        alpha: isCountingDown ? 0.2 : 1.0,
                      ),
                shape: BoxShape.circle,
                boxShadow: isCountingDown
                    ? []
                    : [
                        BoxShadow(
                          color: isCommandRecorded
                              ? const Color(0xFF2DD4BF).withValues(alpha: 0.4)
                              : (isRecording
                                    ? const Color(
                                        0xFFFF3B30,
                                      ).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.3)),
                          blurRadius: isCommandRecorded
                              ? 40
                              : (isRecording ? 20 : 30),
                          spreadRadius: isCommandRecorded ? 10 : 0,
                        ),
                      ],
              ),
            ),

            // Inner circle/square
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCommandRecorded ? 80 : (isRecording ? 40 : 32),
              height: isCommandRecorded ? 80 : (isRecording ? 40 : 32),
              decoration: BoxDecoration(
                color: isCommandRecorded
                    ? const Color(0xFF2DD4BF)
                    : (isRecording
                          ? const Color(0xFFFF3B30)
                          : (isCountingDown
                                ? (context.isDarkMode
                                          ? colors.cardBackground
                                          : Colors.black)
                                      .withValues(alpha: 0.5)
                                : primaryColor)),
                shape: isCommandRecorded ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCommandRecorded
                    ? null
                    : BorderRadius.circular(isRecording ? 8 : 6),
              ),
              child: isCommandRecorded
                  ? Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCommandRecorded
                              ? const Color(0xFF2D4B44)
                              : (context.isDarkMode
                                    ? colors.cardBackground
                                    : Colors.black),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for countdown ring
class CountdownRingPainter extends CustomPainter {
  final double progress;

  CountdownRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

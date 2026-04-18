import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../l10n/app_localizations.dart';
import '../new_project/models/script_analysis.dart';
import 'services/recording_manager.dart';
import 'widgets/auto_accept_bar.dart';
import 'widgets/clip_video_area.dart';
import 'widgets/review_overlay.dart';
import '../../shared/widgets/vrm_button.dart';

/// Página de revisión de clips grabados.
/// Permite al usuario validar el clip antes de proceder al siguiente fragmento.
class ClipReviewPage extends StatefulWidget {
  final String clipPath;
  final String projectId;
  final ScriptAnalysis analysis;
  final int currentFragmentIndex;
  final RecordingManager recordingManager;

  const ClipReviewPage({
    super.key,
    required this.clipPath,
    required this.projectId,
    required this.analysis,
    required this.currentFragmentIndex,
    required this.recordingManager,
  });

  @override
  State<ClipReviewPage> createState() => _ClipReviewPageState();
}

class _ClipReviewPageState extends State<ClipReviewPage>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isProcessing = false;
  Timer? _autoAcceptTimer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _initializeVideo();
  }

  @override
  void dispose() {
    _autoAcceptTimer?.cancel();
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// Inicializa el controlador de video con manejo de errores.
  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.clipPath));
      await _videoController!.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Video initialization exceeded 5s'),
      );

      if (!mounted) return;

      // Configurar video: loop y muted
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0);
      await _videoController!.play();

      setState(() {
        _isVideoInitialized = true;
      });

      // Iniciar timer de auto-aceptación
      _startAutoAcceptTimer();
    } catch (e) {
      debugPrint('[ClipReviewPage] Video initialization failed: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  /// Inicia el timer de auto-aceptación de 3 segundos.
  void _startAutoAcceptTimer() {
    _autoAcceptTimer?.cancel();
    _progressController.forward(from: 0.0);

    _autoAcceptTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isProcessing) {
        _acceptClip();
      }
    });
  }

  /// Cancela el timer de auto-aceptación.
  void _cancelAutoAcceptTimer() {
    _autoAcceptTimer?.cancel();
    _progressController.stop();
  }

  /// Acepta el clip y navega al siguiente fragmento.
  Future<void> _acceptClip() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _cancelAutoAcceptTimer();

    try {
      await widget.recordingManager.acceptCurrentClip(widget.clipPath);

      if (!mounted) return;

      // Navegar al siguiente fragmento o página final
      final nextIndex = widget.currentFragmentIndex + 1;
      if (nextIndex < widget.analysis.segments.length) {
        // Volver a RecordingPage con el siguiente fragmento
        Navigator.of(context).pushReplacementNamed(
          '/recording',
          arguments: {
            'analysis': widget.analysis,
            'currentFragmentIndex': nextIndex,
            'projectId': widget.projectId,
          },
        );
      } else {
        // Todos los fragmentos completados - iniciar stitching
        Navigator.of(context).pushReplacementNamed(
          '/stitch-progress',
          arguments: {
            'projectId': widget.projectId,
            'approvedClips': widget.recordingManager.sessionData.approvedClips.values.toList(),
          },
        );
      }
    } catch (e) {
      debugPrint('[ClipReviewPage] Failed to accept clip: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.acceptClipError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        _startAutoAcceptTimer(); // Reiniciar timer en caso de error
      }
    }
  }

  /// Rechaza el clip, lo elimina y vuelve a la grabación.
  Future<void> _rejectClip() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _cancelAutoAcceptTimer();

    try {
      await widget.recordingManager.rejectCurrentClip(widget.clipPath);

      if (!mounted) return;

      // Volver a RecordingPage para re-grabar el mismo fragmento
      Navigator.of(context).pushReplacementNamed(
        '/recording',
        arguments: {
          'analysis': widget.analysis,
          'currentFragmentIndex': widget.currentFragmentIndex,
          'projectId': widget.projectId,
        },
      );
    } catch (e) {
      debugPrint('[ClipReviewPage] Failed to reject clip: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.rejectClipError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isVideoInitialized && !_isProcessing,
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video background
          ClipVideoArea(
            videoController: _videoController,
            isVideoInitialized: _isVideoInitialized,
          ),

          // Overlays
          ReviewOverlay(
            analysis: widget.analysis,
            currentFragmentIndex: widget.currentFragmentIndex,
            recordingManager: widget.recordingManager,
          ),

          // Auto-accept progress bar
          AutoAcceptBar(
            progressAnimation: _progressAnimation,
          ),

          // Control buttons
          _buildControlButtons(),

          // Loading indicator
          if (!_isVideoInitialized) _buildLoadingIndicator(),

          // Error screen
          if (!_isVideoInitialized)
            _buildErrorScreen(),
        ],
      ),
    ),
    );
  }



  Widget _buildControlButtons() {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Repeat button
          Expanded(
            child: VRMButton(
              label: AppLocalizations.of(context)!.repeat,
              icon: Icons.replay,
              isSecondary: true,
              color: Colors.white70,
              onPressed: _isProcessing ? null : _rejectClip,
            ),
          ),
          const SizedBox(width: 16),
          // Accept button
          Expanded(
            child: VRMButton(
              label: AppLocalizations.of(context)!.next,
              icon: Icons.check_circle_outline,
              isLoading: _isProcessing,
              onPressed: _isProcessing ? null : _acceptClip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
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
             Text(
               AppLocalizations.of(context)!.videoLoadError,
               style: TextStyle(
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
                 color: Colors.white,
               ),
             ),
            const SizedBox(height: 12),
             Text(
               AppLocalizations.of(context)!.videoLoadErrorDesc,
               textAlign: TextAlign.center,
               style: TextStyle(fontSize: 14, color: Colors.white70),
             ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _rejectClip,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
               child: Text(AppLocalizations.of(context)!.reRecord),
            ),
          ],
        ),
      ),
    );
  }
}
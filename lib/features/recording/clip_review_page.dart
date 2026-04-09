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
        // Todos los fragmentos completados - ir a página final
        Navigator.of(context).pushReplacementNamed(
          '/recording-end',
          arguments: {'projectId': widget.projectId},
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
          // Reject button
          _buildControlButton(
            icon: Icons.close,
            label: AppLocalizations.of(context)!.repeat,
            color: Colors.redAccent,
            onPressed: _rejectClip,
          ),

          // Accept button
          _buildControlButton(
            icon: Icons.check,
            label: AppLocalizations.of(context)!.next,
            color: const Color(0xFF2DD4BF),
            onPressed: _acceptClip,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          opacity: _isProcessing ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
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
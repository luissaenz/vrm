import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import '../../core/services/export_service.dart';
import '../../shared/widgets/vrm_button.dart';
import '../../shared/widgets/widget_progress.dart';
import '../../shared/utils/vrm_notifications.dart';
import 'models/session_data.dart';

class RecordingEndPage extends StatefulWidget {
  final String? finalVideoPath;
  final SessionData? sessionData;

  const RecordingEndPage({super.key, this.finalVideoPath, this.sessionData});

  @override
  State<RecordingEndPage> createState() => _RecordingEndPageState();
}

class _RecordingEndPageState extends State<RecordingEndPage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _isExporting = false;
  bool _exportDone = false;
  bool _isSavingOverlay = false;
  double _exportProgress = 0.0;
  StreamSubscription<double>? _exportProgressSub;

  String get _durationMinutes {
    final sd = widget.sessionData;
    if (sd == null) return '--';
    final elapsed = sd.lastUpdatedAt.difference(sd.startedAt);
    final minutes = elapsed.inMinutes;
    return minutes > 0 ? minutes.toString() : '<1';
  }

  int get _totalTakes {
    final sd = widget.sessionData;
    if (sd == null) return 0;
    return sd.takesPerChunk.values.fold(0, (sum, t) => sum + t.total);
  }

  @override
  void initState() {
    super.initState();
    if (widget.finalVideoPath != null) {
      _initializeVideo();
    }
    _exportProgressSub = ExportService().progressStream.listen((progress) {
      if (mounted) {
        setState(() => _exportProgress = progress);
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _exportProgressSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(
        File(widget.finalVideoPath!),
      );
      await _videoController!.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Video initialization exceeded 5s'),
      );

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[RecordingEndPage] Video initialization failed: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    if (_isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _exportVideo() async {
    final l10n = AppLocalizations.of(context)!;

    // Guard: verificar que existe el path
    if (widget.finalVideoPath == null) {
      _showSnackBar(l10n.videoNotAvailable, isError: true);
      return;
    }

    final file = File(widget.finalVideoPath!);
    if (!file.existsSync()) {
      _showSnackBar(l10n.videoFileNotFound, isError: true);
      return;
    }

    if (mounted) {
      setState(() {
        _isExporting = true;
        _isSavingOverlay = true;
        _exportProgress = 0.0;
      });
    }

    try {
      // Paso 1: Guardar en galería
      final exportService = ExportService();
      final result = await exportService.saveToGallery(widget.finalVideoPath!);

      if (!result.success) {
        if (result.error == 'permanently_denied') {
          // Permiso denegado permanentemente: mostrar diálogo
          if (mounted) {
            final shouldOpenSettings = await _showPermissionDeniedDialog();
            if (shouldOpenSettings) {
              await openAppSettings();
            }
            // Aún así abrir share sheet (no requiere permiso de galería)
            await exportService.shareVideo(widget.finalVideoPath!);
          }
        } else {
          // Error al guardar: mostrar SnackBar y abrir share igualmente
          if (mounted) {
            _showSnackBar(l10n.errorSavingVideo, isError: true);
            await exportService.shareVideo(widget.finalVideoPath!);
          }
        }
      } else {
        // Éxito: SnackBar de confirmación
        if (mounted) {
          _showSnackBar(l10n.videoSavedGallery);
          // Abrir share sheet
          await exportService.shareVideo(widget.finalVideoPath!);
        }
      }
    } catch (e) {
      debugPrint('[RecordingEndPage] Export error: $e');
      if (mounted) {
        _showSnackBar(l10n.errorSavingVideo, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportDone = true;
          _isSavingOverlay = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      VRMNotifications.showError(context, message);
    } else {
      VRMNotifications.showSuccess(context, message);
    }
  }

  Future<bool> _showPermissionDeniedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.galleryPermissionTitle),
        content: Text(l10n.galleryPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: isDark
          ? context.colorScheme.surface
          : const Color(0xFFF9FAF9),
      body: _isSavingOverlay
          ? WidgetProgress(
              title: 'Guardando en galería...',
              subtitle: '${(_exportProgress * 100).round()}% completado',
              description:
                  'El video se está guardando en tu galería. '
                  'No cierres la aplicación durante este proceso.',
              progress: _exportProgress,
              duration: const Duration(seconds: 30),
            )
          : Stack(
              children: [
                // Background soft glow
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.forest.withValues(
                          alpha: isDark ? 0.08 : 0.04,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(context, l10n),
                        _buildSummarySection(context, l10n),
                        _buildPreviewSection(context, l10n),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(context, l10n),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              size: 24,
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : context.appColors.forest.withValues(alpha: 0.6),
            ),
          ),
          Text(
            l10n.performanceSummary.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: context.appColors.forest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 48), // Spacer to center the title
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            // Progress Circle using SVG-like CustomPaint
            SizedBox(
              width: 208,
              height: 208,
              child: CustomPaint(
                painter: _ProgressPainter(
                  progress: 0.75,
                  color: context.appColors.forest,
                  backgroundColor: context.appColors.forest.withValues(
                    alpha: 0.05,
                  ),
                  strokeWidthOuter: 6,
                  strokeWidthInner: 10,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _durationMinutes,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.forest,
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: _durationMinutes == '--' ? '' : 'm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.forest.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.savedLabel.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: context.appColors.forest.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                l10n.timeSavedTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.forest,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.timeSavedDescription(
                  _durationMinutes,
                  _totalTakes.toString(),
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: context.appColors.forest.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPreviewSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.previewTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.forest,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  l10n.editManually,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.forestLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: context.appColors.forest.withValues(alpha: 0.05),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isVideoInitialized && _videoController != null)
                      VideoPlayer(_videoController!)
                    else
                      Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    Container(color: Colors.black.withValues(alpha: 0.1)),
                    if (_isVideoInitialized)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: context.appColors.forest,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, AppLocalizations l10n) {
    final hasVideo = widget.finalVideoPath != null;
    final canExport =
        _isVideoInitialized && hasVideo && !_isExporting && !_exportDone;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface.withValues(alpha: 0.94),
              context.colorScheme.surface.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: VRMButton(
          label: _exportDone
              ? l10n.exported
              : (hasVideo ? l10n.exportVideo : l10n.videoNotAvailable),
          onPressed: canExport
              ? () {
                  _showSnackBar(l10n.preparingExport);
                  _exportVideo();
                }
              : null,
          isLoading: _isExporting,
          icon: _exportDone
              ? Icons.check_circle_outline
              : Icons.ios_share_rounded,
          color: _exportDone
              ? const Color(0xFF2DD4BF)
              : context.appColors.forest,
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidthOuter;
  final double strokeWidthInner;

  _ProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidthOuter,
    required this.strokeWidthInner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthOuter;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthInner
      ..strokeCap = StrokeCap.round;

    // Drawing progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

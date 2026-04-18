import 'package:flutter/material.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import '../../../core/services/ffmpeg_stitcher_service.dart';
import '../../../shared/widgets/widget_progress.dart';

class StitchProgressPage extends StatefulWidget {
  final String projectId;
  final List<String> approvedClips;

  const StitchProgressPage({
    super.key,
    required this.projectId,
    required this.approvedClips,
  });

  @override
  State<StitchProgressPage> createState() => _StitchProgressPageState();
}

class _StitchProgressPageState extends State<StitchProgressPage> {
  final FFmpegStitcherService _stitcherService = FFmpegStitcherService();
  double _progress = 0.0;
  String _status = 'Starting stitch...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startStitching();
  }

  String _mapStatusToL10n(String status, AppLocalizations l10n) {
    if (status.contains('Starting')) return l10n.stitchingStatusStarting;
    if (status.contains('Re-encoding')) return l10n.stitchingStatusReencoding;
    if (status.contains('Processing')) return l10n.stitchingStatusProcessing;
    if (status.contains('Completed')) return l10n.stitchingStatusCompleted;
    return status;
  }

  Future<void> _startStitching() async {
    try {
      final finalVideoPath = await _stitcherService.stitchVideos(
        projectId: widget.projectId,
        clipPaths: widget.approvedClips,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress.progress;
              _status = progress.status;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _status = 'Completed';
          _progress = 1.0;
        });
      }

      // Navigate to next page after a short delay
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/recording-end',
            arguments: {'finalVideoPath': finalVideoPath},
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('VOLVER'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: _progress >= 1.0,
      child: WidgetProgress(
        title: l10n.stitchingTitle.toUpperCase(),
        subtitle: _mapStatusToL10n(_status, l10n),
        description: l10n.stitchingDescription,
        progress: _progress,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import '../../../core/services/native_stitcher_service.dart';
import '../../../shared/widgets/widget_progress.dart';
import '../models/session_data.dart';

class StitchProgressPage extends StatefulWidget {
  final String projectId;
  final List<String> approvedClips;
  final SessionData? sessionData;

  const StitchProgressPage({
    super.key,
    required this.projectId,
    required this.approvedClips,
    this.sessionData,
  });

  @override
  State<StitchProgressPage> createState() => _StitchProgressPageState();
}

class _StitchProgressPageState extends State<StitchProgressPage> {
  final NativeStitcherService _stitcherService = NativeStitcherService();
  double _progress = 0.0;
  String _status = 'Starting stitch...';
  String? _errorMessage;
  bool _isRetrying = false;

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
    if (status.contains('Native stitch')) return 'Stitching...';
    if (status.contains('FFmpeg')) return 'Processing with ffmpeg...';
    if (status.contains('direct concat')) return 'Merging video files...';
    return status;
  }

  bool get _isSingleClip => widget.approvedClips.length <= 1;

  Future<void> _startStitching() async {
    setState(() {
      _errorMessage = null;
      _isRetrying = false;
      _progress = 0.0;
      _status = 'Starting stitch...';
    });

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

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/recording-end',
            arguments: {
              'finalVideoPath': finalVideoPath,
              'sessionData': widget.sessionData,
            },
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_isSingleClip)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/recording-end',
                        arguments: {
                          'finalVideoPath': widget.approvedClips.isNotEmpty
                              ? widget.approvedClips.first
                              : null,
                          'sessionData': widget.sessionData,
                        },
                      );
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('CONTINUE WITH SINGLE CLIP'),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isRetrying ? null : _startStitching,
                  child: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('RETRY'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('GO BACK'),
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

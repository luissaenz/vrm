import 'package:flutter/material.dart';
import '../../../core/services/ffmpeg_stitcher_service.dart';

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
  String _status = 'Preparing...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startStitching();
  }

  Future<void> _startStitching() async {
    try {
      final finalVideoPath = await _stitcherService.stitchVideos(
        projectId: widget.projectId,
        clipPaths: widget.approvedClips,
        onProgress: (progress) {
          setState(() {
            _progress = progress.progress;
            _status = progress.status;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = error;
          });
        },
      );

      setState(() {
        _status = 'Completed';
        _progress = 1.0;
      });

      // Navigate to next page after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/recording-end',
            arguments: {'finalVideoPath': finalVideoPath},
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _progress >= 1.0 || _errorMessage != null,
      child: Scaffold(
        body: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Stitching Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
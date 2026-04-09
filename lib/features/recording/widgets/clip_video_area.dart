import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget que muestra el área de video del clip siendo revisado.
class ClipVideoArea extends StatelessWidget {
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;

  const ClipVideoArea({
    super.key,
    required this.videoController,
    required this.isVideoInitialized,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVideoInitialized || videoController == null) {
      return const SizedBox.expand();
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoController!.value.size.width,
          height: videoController!.value.size.height,
          child: VideoPlayer(videoController!),
        ),
      ),
    );
  }
}
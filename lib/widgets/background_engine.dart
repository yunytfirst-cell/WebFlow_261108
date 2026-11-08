import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundEngine extends StatelessWidget {
  final String bgVideoPath;
  final double bgOpacity;
  final VideoPlayerController? videoPlayerController;
  final Color backgroundColor;

  const BackgroundEngine({
    super.key,
    required this.bgVideoPath,
    required this.bgOpacity,
    this.videoPlayerController,
    required this.backgroundColor,
  });

  bool _isVideoFile(String path) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.wmv', '.mkv'];
    return videoExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  @override
  Widget build(BuildContext context) {
    // [수정] 최대화 시 동영상이 사라지는 문제를 해결하기 위해 RepaintBoundary 제거 및 구조 단순화
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 기초 배경색 (알파 채널 직접 조절)
        Container(
          color: backgroundColor.withValues(alpha: bgOpacity),
        ),
        
        // 2. 사용자 설정 배경 (영상/이미지)
        if (bgVideoPath.isNotEmpty)
          _isVideoFile(bgVideoPath)
              ? (videoPlayerController != null && videoPlayerController!.value.isInitialized
                  ? ValueListenableBuilder(
                      valueListenable: videoPlayerController!,
                      builder: (context, VideoPlayerValue value, child) {
                        return Opacity(
                          opacity: bgOpacity,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: value.size.width,
                              height: value.size.height,
                              child: VideoPlayer(videoPlayerController!),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(color: Colors.transparent))
              : Opacity(
                  opacity: bgOpacity,
                  child: Image.file(
                    File(bgVideoPath),
                    fit: BoxFit.cover,
                  ),
                ),
      ],
    );
  }
}

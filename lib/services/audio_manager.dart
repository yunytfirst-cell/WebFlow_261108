import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;
  bool _isSoundOn = true;

  bool get isSoundOn => _isSoundOn;

  /// 초기화 및 상태 설정
  void init(bool initialIsSoundOn) {
    _isSoundOn = initialIsSoundOn;
  }

  /// 비디오 컨트롤러 연결 (볼륨 동기화용)
  void setVideoController(VideoPlayerController? controller) {
    _videoController = controller;
    _syncVolumes();
  }

  /// 전체 사운드 ON/OFF 토글
  void toggleSound(bool isOn) {
    _isSoundOn = isOn;
    _syncVolumes();
    if (!_isSoundOn) {
      stopAllSounds();
    }
  }

  /// 현재 재생 중인 모든 소리 즉시 정지
  void stopAllSounds() {
    _audioPlayer.stop();
  }

  /// 알람 또는 효과음 재생
  Future<void> playAlarm(String assetPath, {double volume = 1.0, Duration? limit}) async {
    if (!_isSoundOn) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath), volume: volume);
      if (limit != null) {
        Timer(limit, () => _audioPlayer.stop());
      }
    } catch (e) {
      // debugPrint("재생 에러: $e");
    }
  }

  /// 비디오 볼륨 동기화
  void _syncVolumes() {
    _videoController?.setVolume(_isSoundOn ? 1.0 : 0.0);
  }

  /// 앱 종료 시 리소스 해제
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
  }
}

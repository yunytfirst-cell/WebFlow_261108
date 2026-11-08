class ClockMarker {
  final int count;
  final double position; // 0.0 ~ 1.0 (진행률)
  final int timeSeconds; // 남은 시간 (초)

  ClockMarker({
    required this.count,
    required this.position,
    required this.timeSeconds,
  });
}

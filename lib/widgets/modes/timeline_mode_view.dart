import 'package:flutter/material.dart';
import 'dart:math' as math; // [추가] math.max 사용을 위해 필요
import '../clock_display.dart';
import '../../models/clock_marker.dart';
import '../../models/design_theme.dart'; // [추가]

class TimelineModeView extends StatelessWidget {
  final int totalSeconds;
  final int currentSeconds;
  final List<ClockMarker> markers;
  final String timeString;
  final bool isRunning;
  final double progress;
  final String glowMessage;
  final bool showMessage;
  final VoidCallback onReset;
  final AppThemeData theme; // [추가]

  const TimelineModeView({
    super.key,
    required this.totalSeconds,
    required this.currentSeconds,
    required this.markers,
    required this.timeString,
    required this.isRunning,
    required this.progress,
    required this.glowMessage,
    required this.showMessage,
    required this.onReset,
    required this.theme, // [추가]
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // InfoBar의 시각적 높이와 위치를 계승 (반응형)
        double containerHeight = MediaQuery.of(context).size.height * 0.12;
        
        return Column(
          children: [
            // 1. 상단 통합 타임라인 + 리셋 버튼 박스
            Center(
              child: Container(
                width: 700,
                height: containerHeight,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                padding: const EdgeInsets.fromLTRB(20, 5, 10, 5),
                decoration: BoxDecoration(
                  color: theme.glassColor, // [수정]
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: theme.textColor.withValues(alpha: 0.1)), // [수정]
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.2), // [수정]
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // [좌측] 타임라인 룰러 영역
                    Expanded(
                      child: _TimelineRulerInternal(
                        key: ValueKey(markers.length), // 마커 개수 변경 시 강제 리빌드 트리거
                        totalSeconds: totalSeconds,
                        currentSeconds: currentSeconds,
                        markers: markers,
                        isRunning: isRunning,
                        theme: theme, // [전달]
                      ),
                    ),
                    const SizedBox(width: 15),
                    // [우측] 리셋 버튼 영역
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.redAccent),
                      iconSize: containerHeight * 0.45,
                      onPressed: onReset,
                      tooltip: "카운터 및 타임라인 초기화",
                    ),
                  ],
                ),
              ),
            ),

            // 2. 중앙 시계 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClockDisplay(
                  timeString: timeString,
                  isRunning: isRunning,
                  progress: progress,
                  glowMessage: glowMessage,
                  showMessage: showMessage,
                  theme: theme, // [전달]
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// [내부 위젯] 타임라인 룰러 핵심 렌더링 영역
class _TimelineRulerInternal extends StatelessWidget {
  final int totalSeconds;
  final int currentSeconds;
  final List<ClockMarker> markers;
  final bool isRunning;
  final AppThemeData theme; // [추가]

  const _TimelineRulerInternal({
    super.key,
    required this.totalSeconds,
    required this.currentSeconds,
    required this.markers,
    required this.isRunning,
    required this.theme, // [추가]
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        double dotSize = (height * 0.18).clamp(8.0, 16.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 0. 시간 레이블 (양 끝 숫자)
            Positioned(
              left: 0,
              top: height * 0.05,
              child: Text(
                "${totalSeconds ~/ 60}",
                style: TextStyle(
                  color: theme.textColor.withValues(alpha: 0.3), // [수정]
                  fontSize: height * 0.15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: height * 0.05,
              child: Text(
                "0",
                style: TextStyle(
                  color: theme.textColor.withValues(alpha: 0.3), // [수정]
                  fontSize: height * 0.15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 1. 눈금 페인터 (5분 단위)
            Positioned.fill(
              child: CustomPaint(
                painter: _RulerPainterInternal(totalSeconds: totalSeconds, theme: theme), // [수정]
              ),
            ),

            // 2. 과거 클릭 마커 (빨간 수직 네온 바)
            ...markers.map((marker) {
              double progress = (1 - (marker.timeSeconds / totalSeconds)).clamp(0.0, 1.0);
              return Positioned(
                left: progress * width,
                top: height * 0.3,
                bottom: height * 0.1,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withAlpha(200),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // 3. 현재 진행 지점 (부드럽게 이동하는 파란 네온 점)
            AnimatedPositioned(
              duration: isRunning ? const Duration(seconds: 1) : Duration.zero,
              curve: Curves.linear,
              left: (1 - (currentSeconds / totalSeconds)).clamp(0.0, 1.0) * width - (dotSize / 2),
              top: (height / 2) - (dotSize / 2), // 수직 정중앙 배치
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: theme.accentColor, // [수정]
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentColor.withAlpha(255), // [수정]
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withAlpha(150),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// [내부 클래스] 타임라인 눈금 페인터
class _RulerPainterInternal extends CustomPainter {
  final int totalSeconds;
  final AppThemeData theme; // [추가]
  _RulerPainterInternal({required this.totalSeconds, required this.theme}); // [수정]

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.textColor.withValues(alpha: 0.1) // [수정]
      ..strokeWidth = 1;
    
    int intervalSec = 300; // 5분
    // [수정] intervals가 최소 1이 되도록 보장하여 제로 분할(NaN) 에러 방지
    int intervals = math.max(1, totalSeconds ~/ intervalSec);
    
    // 눈금 그리기
    for (int i = 0; i <= intervals; i++) {
      double x = (i / intervals) * size.width;
      canvas.drawLine(Offset(x, size.height * 0.4), Offset(x, size.height * 0.8), paint);
    }
    
    // 중앙 가로줄 (점이 흐르는 궤적) - 항상 0부터 size.width까지 고정
    canvas.drawLine(
      Offset(0, size.height * 0.5), 
      Offset(size.width, size.height * 0.5), 
      paint..color = theme.textColor.withValues(alpha: 0.05) // [수정]
    );

    // 바닥 가로줄 - 항상 0부터 size.width까지 고정
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), paint..color = theme.textColor.withValues(alpha: 0.15)); // [수정]
  }

  @override
  bool shouldRepaint(covariant _RulerPainterInternal oldDelegate) {
    return oldDelegate.totalSeconds != totalSeconds;
  }
}

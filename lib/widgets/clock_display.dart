import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/clock_marker.dart';
import '../models/design_theme.dart';

class ClockDisplay extends StatelessWidget {
  final String timeString;
  final bool isRunning;
  final double progress;
  final String glowMessage;
  final bool showMessage;
  final List<ClockMarker> markers;
  final AppThemeData theme;

  const ClockDisplay({
    super.key,
    required this.timeString,
    required this.isRunning,
    required this.progress,
    required this.glowMessage,
    required this.showMessage,
    this.markers = const [],
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        double availableHeight = constraints.maxHeight;
        double refSize = availableWidth < availableHeight ? availableWidth : availableHeight;
        double circleSize = (refSize * 0.88).clamp(100.0, availableHeight * 0.75);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 더욱 입체적인 클레이모피즘 배경 원형
              /*
              Container(
                width: circleSize * 0.95,
                height: circleSize * 0.95,
                /*
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent, // [수정] 배경이 보이도록 투명하게 설정
                  boxShadow: [
                    // 깊은 하단 그림자 (2배 강화)
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.5),
                      offset: const Offset(15, 15),
                      blurRadius: 30,
                    ),
                    // 밝은 상단 하이라이트 (2배 강화)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      offset: const Offset(-15, -15),
                      blurRadius: 30,
                    ),
                  ],
                  /*
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(0),
                      // Colors.white.withAlpha(0),
                      Colors.transparent,

                    ],
                  ),

                   */
                ),
                */

                /*
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.glassColor.withAlpha(0),
                        border: Border.all(
                          color: Colors.white.withAlpha(10),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                 */
              ),
*/
              // 2. 입체적인 진행 상태 게이지
              SizedBox(
                height: circleSize * 1.02,
                width: circleSize * 1.02,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: circleSize * 0.03,
                  backgroundColor: theme.textColor.withAlpha(50),
                  color: isRunning ? theme.accentColor : theme.primaryColor,
                  strokeCap: StrokeCap.round,
                ),
              ),

              // 3. 메인 시간 텍스트
              Container(
                alignment: Alignment.center,
                width: circleSize * 0.85,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontSize: circleSize * 0.22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                      color: theme.textColor.withValues(alpha: showMessage ? 0.2 : 0.8),
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: theme.shadowColor.withValues(alpha: 0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3-1. 마커 표시
              ...markers.map((marker) {
                double angle = (marker.position * 2 * math.pi) - (math.pi / 2);
                double radius = circleSize / 2;
                double x = radius * math.cos(angle);
                double y = radius * math.sin(angle);

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Container(
                    width: circleSize * 0.08,
                    height: circleSize * 0.08,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(3, 3),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      child: Text(
                        "${marker.count}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

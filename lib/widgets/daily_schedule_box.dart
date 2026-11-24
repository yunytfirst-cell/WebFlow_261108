import 'package:flutter/material.dart';
import '../models/design_theme.dart';
import '../services/daily_schedule_service.dart';

class DailyScheduleBox extends StatelessWidget {
  final List<String> schedule24h;
  final DateTime currentTime;
  final AppThemeData theme;
  final VoidCallback onClose;
  final VoidCallback? onOpenEditor;
  final double width;

  const DailyScheduleBox({
    super.key,
    required this.schedule24h,
    required this.currentTime,
    required this.theme,
    required this.onClose,
    this.onOpenEditor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final int currentHour = currentTime.hour;
    final String timeSlotLabel = DailyScheduleService.getTimeSlotLabel(
      currentHour,
    );
    final String scheduleText = DailyScheduleService.getCurrentScheduleText(
      schedule24h,
      currentTime,
    );

    // 리얼 현재시간 (HH:mm)
    final String realTimeString =
        "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";

    return Container(
      width: width,
      height: 76, // 2배 높이
      clipBehavior: Clip.antiAlias, // 왼쪽 시간 색 칸이 둥근 모서리를 따라 잘리게
      // 테두리는 왼쪽 색 칸 위에 그려야 가려지지 않는다
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2026-11-24 사용자 지시: 현재 시간은 아이콘·감싸는 박스 없이 맨 앞에 두고,
          // 박스 왼쪽 끝부터 시간 글자 끝까지를 색 칸으로 채워 표시한다.
          Container(
            color: theme.accentColor.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                realTimeString,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double boxWidth = constraints.maxWidth;
                  // 아무리 축소되어도 내부 자식이 찌그러지거나 Overflow되지 않도록 기준 폭을 설정하고 FittedBox로 축소
                  final double referenceWidth = boxWidth < 220.0
                      ? 220.0
                      : boxWidth;

                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: referenceWidth,
                      height: 64,
                      child: Row(
                        children: [
                          // 스케줄 아이콘 & 스케줄 클릭 영역
                          Expanded(
                            child: InkWell(
                              onTap: onOpenEditor,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    // 2026-11-24 사용자 지시: 시간 칸 오른쪽 스케줄 아이콘 제거
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.accentColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        timeSlotLabel,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        scheduleText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // 닫기 (X) 버튼
                          GestureDetector(
                            onTap: onClose,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: theme.textColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

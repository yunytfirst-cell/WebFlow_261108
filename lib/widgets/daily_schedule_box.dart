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
    final String timeSlotLabel = DailyScheduleService.getTimeSlotLabel(currentHour);
    final String scheduleText = DailyScheduleService.getCurrentScheduleText(schedule24h, currentTime);
    
    // 리얼 현재시간 (HH:mm)
    final String realTimeString =
        "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";

    return Container(
      width: width,
      height: 76, // 2배 높이
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double boxWidth = constraints.maxWidth;
          // 아무리 축소되어도 내부 자식이 찌그러지거나 Overflow되지 않도록 기준 폭을 설정하고 FittedBox로 축소
          final double referenceWidth = boxWidth < 300.0 ? 300.0 : boxWidth;

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
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 22,
                              color: theme.textColor.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.accentColor.withValues(alpha: 0.35),
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
                            const SizedBox(width: 8),
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
                  const SizedBox(width: 8),

                  // 리얼 현재 시간 표시 (우측)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.textColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          size: 15,
                          color: theme.textColor.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          realTimeString,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
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
    );
  }
}

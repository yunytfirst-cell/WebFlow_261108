import 'package:flutter/material.dart';
import 'clay_button.dart';
import '../models/design_theme.dart';

class SetGroup extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final bool isAlarmOn;
  final VoidCallback onToggleSound;
  final AppThemeData theme;
  final double screenMaxHeight; // 전체 화면 높이
  final double screenMaxWidth;  // [추가] 전체 화면 너비

  const SetGroup({
    super.key,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
    required this.isAlarmOn,
    required this.onToggleSound,
    required this.theme,
    required this.screenMaxHeight,
    required this.screenMaxWidth, // [추가]
  });

  @override
  Widget build(BuildContext context) {
    // [규격 설정] 버튼의 최소/최대 사이즈 제한
    const double minBtnSize = 45.0;
    const double maxBtnSize = 90.0;
    
    // 가로/세로 비율을 고려한 기준 사이즈 계산
    // 가로의 15% 또는 세로의 10% 중 작은 쪽을 선택하여 깨짐 방지
    double baseSize = (screenMaxWidth * 0.15 < screenMaxHeight * 0.10) 
        ? screenMaxWidth * 0.15 
        : screenMaxHeight * 0.10;

    // 최종 버튼 사이즈 결정 (제한 범위 적용)
    double buttonSize = baseSize.clamp(minBtnSize, maxBtnSize);
    
    // 컨테이너 높이는 버튼 크기에 비례하여 결정 (최소 65, 최대 150)
    double containerHeight = (buttonSize * 1.5).clamp(65.0, 150.0);

    return Center(
      child: Container(
        height: containerHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClayButton(
                icon: Icons.replay_circle_filled,
                baseColor: theme.backgroundColor.withAlpha(90),
                size: buttonSize * 0.8, // 보조 버튼
                isCircle: true,
                onPressed: onReset,
                tooltip: "초기화",
                textColor: theme.textColor,
              ),
              const SizedBox(width: 30),
              ClayButton(
                icon: isRunning ? Icons.pause_circle : Icons.play_circle,
                baseColor: isRunning ? theme.accentColor.withAlpha(90) : theme.primaryColor.withAlpha(90),
                size: buttonSize, // 메인 버튼
                isCircle: true,
                onPressed: onToggle,
                tooltip: isRunning ? "일시정지" : "시작",
                textColor: theme.textColor,
              ),
              const SizedBox(width: 30),
              ClayButton(
                icon: isAlarmOn ? Icons.volume_up : Icons.volume_off,
                baseColor: isAlarmOn ? theme.primaryColor.withAlpha(90) : theme.backgroundColor.withAlpha(90),
                size: buttonSize * 0.8, // 보조 버튼
                isCircle: true,
                onPressed: onToggleSound,
                tooltip: "사운드 토글",
                textColor: theme.textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

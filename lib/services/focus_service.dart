/*
[FOCUS 집중강도 연산 서비스]
- 클릭 간격이 이전보다 증가했을 때 그 시간을 누적합니다.
- 설정된 총 시간 대비 누적 시간의 비율(%)로 집중도를 산출합니다.
- 10단계 레벨과 칭호 시스템을 제공합니다.
*/

class FocusLevelInfo {
  final int level;
    final String description;


  FocusLevelInfo(this.level, this.description);
}

class FocusService {
  static final List<FocusLevelInfo> levels = [
    FocusLevelInfo(1, "Awakening : 메타인지를 처음 시작하는 단계"),
    FocusLevelInfo(2, "Observer : 자신의 생각을 관찰하기 시작"),
    FocusLevelInfo(3, "Focus Seeker : 짧게나마 집중을 유지"),
    FocusLevelInfo(4, "Mind Tracker : 생각이 흐트러지는 순간을 자주 발견"),
    FocusLevelInfo(5, "Focus Guardian : 집중력을 꾸준히 지키기 시작"),
    FocusLevelInfo(6, "Awareness Master : 메타인지가 습관으로 자리잡음"),
    FocusLevelInfo(7, "Deep Focus : 오랜 시간 현재에 머무를 수 있음"),
    FocusLevelInfo(8, "Mind Commander : 생각과 집중을 스스로 조절"),
    FocusLevelInfo(9, "Flow Master : 높은 집중 상태를 자주 유지"),
    FocusLevelInfo(10, "Meta Focus Master : 메타인지와 집중력을 모두 자유롭게 제어"),
  ];

  /// 집중 비율(0~100)을 바탕으로 현재 레벨 정보 반환
  static FocusLevelInfo getLevelInfo(double focusPercentage) {
    int index = (focusPercentage / 10).floor().clamp(0, 9);
    return levels[index];
  }

  /// 집중 강도 계산 알고리즘
  /// cumulativeIncrease: 누적된 시간 증가분 (초)
  /// totalSessionSeconds: 설정된 타이머 총 시간 (초)
  static double calculateFocusPercentage(int cumulativeIncrease, int totalSessionSeconds) {
    if (totalSessionSeconds <= 0) return 0.0;
    double percentage = (cumulativeIncrease / totalSessionSeconds) * 100;
    return percentage.clamp(0.0, 100.0);
  }
}

import 'package:flutter/material.dart';
import 'list_sidebar.dart';

/*
성공의 열쇠(끝장 리스트) 사이드바. 본체는 공용 [ListSidebar]이고,
여기서는 끝장 리스트 값([ListSidebarSpec.goal])과 🎯(메인 화면으로 보내기)만 정한다.
- 화면 오른쪽, 파랑, 항목의 '🎯' 버튼 클릭 시 메인 화면의 TopBar로 내용 전송.
*/

class GoalItem extends ListSidebarItem {
  GoalItem({super.text});
}

class GoalListSidebar extends StatelessWidget {
  final Function(String) onSelectGoal; // 선택된 목표를 TopBar로 보냄
  final Function(String) onDeleteGoal; // 삭제 알림
  final String selectedGoal; // 지금 메인 화면에 보낸 항목 요약 (그 항목의 🎯만 밝게)
  final VoidCallback onClose;

  final String initialTitle;
  final List<GoalItem> initialGoals;
  final Function(String) onTitleChanged;
  final Function(List<GoalItem>) onGoalsChanged;
  final String? initialFilePath;
  final Function(String?) onFilePathChanged;
  final Map<String, int> runRecords; // 실행 카운터 기록 (사이드바를 닫아도 유지되도록 main에서 보관)
  final VoidCallback onRunRecordsChanged;
  final VoidCallback? onBringToFront; // 패널 조작 시 다른 패널보다 위로 올림

  /// 이 리스트에서 마지막으로 불러온 폴더 (다른 리스트와 공유하지 않음)
  final String? loadDirectory;
  final Function(String?) onLoadDirectoryChanged;

  const GoalListSidebar({
    this.loadDirectory,
    required this.onLoadDirectoryChanged,
    required this.runRecords,
    required this.onRunRecordsChanged,
    this.onBringToFront,
    super.key,
    required this.onSelectGoal,
    required this.onDeleteGoal,
    this.selectedGoal = '',
    required this.onClose,
    required this.initialTitle,
    required this.initialGoals,
    required this.onTitleChanged,
    required this.onGoalsChanged,
    required this.initialFilePath,
    required this.onFilePathChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListSidebar<GoalItem>(
      spec: ListSidebarSpec.goal,
      newItem: GoalItem.new,
      loadDirectory: loadDirectory,
      onLoadDirectoryChanged: onLoadDirectoryChanged,
      runRecords: runRecords,
      onRunRecordsChanged: onRunRecordsChanged,
      onBringToFront: onBringToFront,
      onClose: onClose,
      initialTitle: initialTitle,
      initialItems: initialGoals,
      onTitleChanged: onTitleChanged,
      onItemsChanged: onGoalsChanged,
      initialFilePath: initialFilePath,
      onFilePathChanged: onFilePathChanged,
      onSelectItem: onSelectGoal,
      selectedItem: selectedGoal,
      onDeleteItem: onDeleteGoal,
    );
  }
}

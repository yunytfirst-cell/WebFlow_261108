import 'package:flutter/material.dart';
import 'list_sidebar.dart';

/*
알아차림 리스트 사이드바. 본체는 공용 [ListSidebar]이고,
여기서는 알아차림 리스트 값([ListSidebarSpec.awareness])만 정한다.
- 화면 왼쪽, 주황. 🎯로 항목을 메인 화면 목표 칸에 보낸다(2026-11-26, 끝장 리스트와 같은 칸).
- 실행 카운터·열린 파일·불러온 폴더는 끝장 리스트와 따로 관리한다.
*/

class AwarenessItem extends ListSidebarItem {
  AwarenessItem({super.text});
}

class AwarenessListSidebar extends StatelessWidget {
  final VoidCallback onClose;
  final String initialTitle;
  final List<AwarenessItem> initialItems;
  final String? initialFilePath;
  final Map<String, int> runRecords;
  final VoidCallback onRunRecordsChanged;
  final VoidCallback? onBringToFront; // 패널 조작 시 다른 패널보다 위로 올림
  final Function(String) onTitleChanged;
  final Function(List<AwarenessItem>) onItemsChanged;
  final Function(String?) onFilePathChanged;
  final Function(String) onSelectItem; // 🎯: 항목을 메인 화면으로 보냄
  final Function(String) onDeleteItem;
  final String selectedItem; // 지금 메인 화면에 보낸 이 리스트 항목 요약 (그 항목의 🎯만 밝게)

  /// 이 리스트에서 마지막으로 불러온 폴더 (다른 리스트와 공유하지 않음)
  final String? loadDirectory;
  final Function(String?) onLoadDirectoryChanged;

  const AwarenessListSidebar({
    this.loadDirectory,
    required this.onLoadDirectoryChanged,
    super.key,
    required this.onClose,
    required this.initialTitle,
    required this.initialItems,
    required this.initialFilePath,
    required this.runRecords,
    required this.onRunRecordsChanged,
    this.onBringToFront,
    required this.onTitleChanged,
    required this.onItemsChanged,
    required this.onFilePathChanged,
    required this.onSelectItem,
    required this.onDeleteItem,
    this.selectedItem = '',
  });

  @override
  Widget build(BuildContext context) {
    return ListSidebar<AwarenessItem>(
      spec: ListSidebarSpec.awareness,
      newItem: AwarenessItem.new,
      loadDirectory: loadDirectory,
      onLoadDirectoryChanged: onLoadDirectoryChanged,
      runRecords: runRecords,
      onRunRecordsChanged: onRunRecordsChanged,
      onBringToFront: onBringToFront,
      onClose: onClose,
      initialTitle: initialTitle,
      initialItems: initialItems,
      onTitleChanged: onTitleChanged,
      onItemsChanged: onItemsChanged,
      initialFilePath: initialFilePath,
      onFilePathChanged: onFilePathChanged,
      onSelectItem: onSelectItem,
      selectedItem: selectedItem,
      onDeleteItem: onDeleteItem,
    );
  }
}

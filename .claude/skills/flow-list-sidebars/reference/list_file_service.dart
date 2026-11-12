import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'run_counter_service.dart';

/// 끝장(성공의 열쇠) 리스트와 알아차림 리스트는 구조만 같고,
/// 저장 폴더와 실행 카운터 줄은 서로 독립적이다.
enum ListFileKind {
  goal(
    titleMarker: '[PJT]',
    itemMarker: 'GOAL',
    runLinePrefix: '[RUN] ',
    directoryName: 'FlowSchedules',
  ),
  awareness(
    titleMarker: '[AWARE]',
    itemMarker: 'AWARE_ITEM',
    runLinePrefix: '[AWARE_RUN] ',
    directoryName: 'FlowAwareness',
  );

  const ListFileKind({
    required this.titleMarker,
    required this.itemMarker,
    required this.runLinePrefix,
    required this.directoryName,
  });

  final String titleMarker;
  final String itemMarker;
  final String runLinePrefix;
  final String directoryName;
}

class ListFileData {
  const ListFileData({
    required this.title,
    required this.items,
    required this.runRecords,
  });

  final String? title;
  final List<String> items;
  final Map<String, int> runRecords;
}

class ListFileService {
  /// 리스트 종류별 저장 폴더 (문서 폴더 아래 FlowSchedules / FlowAwareness)
  static Future<Directory> directoryFor(ListFileKind kind) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}${kind.directoryName}',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// 파일 선택창에 넘길 시작 폴더.
  /// Windows 열기 창(GetOpenFileName)은 시작 폴더 문자열이 앱이 처음 넘긴 값과
  /// 같으면 그 값을 무시하고 "앱 전체에서 마지막으로 연 폴더"를 보여준다.
  /// 그러면 알아차림 리스트에서 연 폴더가 성공의 열쇠 불러오기에 나타나므로,
  /// 경로를 정규화하고 끝에 구분자를 붙여 항상 지정한 폴더로 열리게 한다.
  static String pickerInitialDirectory(String directory) {
    final separator = Platform.pathSeparator;
    var normalized = directory.replaceAll(RegExp(r'[/\\]+'), separator);
    if (!normalized.endsWith(separator)) normalized += separator;
    return normalized;
  }

  static String serialize({
    required ListFileKind kind,
    required String title,
    required List<String> items,
    required Map<String, int> runRecords,
  }) {
    final content = StringBuffer()
      ..writeln('${kind.titleMarker}: $title')
      ..write(
        RunCounterService.toLines(
          runRecords,
          linePrefix: kind.runLinePrefix,
        ),
      );

    for (var index = 0; index < items.length; index++) {
      content
        ..writeln('[${kind.itemMarker}:${index + 1}]')
        ..writeln(items[index])
        ..writeln('[END_${kind.itemMarker}]');
    }
    return content.toString();
  }

  static ListFileData parse(String content, {required ListFileKind kind}) {
    final items = <String>[];
    final runRecords = <String, int>{};
    String? title;
    String? markedItem;
    final legacyItem = StringBuffer();

    void addLegacyItem() {
      final text = legacyItem.toString().trim();
      if (text.isNotEmpty) items.add(text);
      legacyItem.clear();
    }

    for (final line in content.split('\n')) {
      final trimmedLine = line.trim();
      if (RegExp(r'^\[(GOAL|AWARE_ITEM):\d+\]$').hasMatch(trimmedLine)) {
        addLegacyItem();
        markedItem = '';
      } else if (RegExp(r'^\[END_(GOAL|AWARE_ITEM)\]$').hasMatch(trimmedLine) &&
          markedItem != null) {
        items.add(markedItem.trim());
        markedItem = null;
      } else if (markedItem != null) {
        markedItem = markedItem.isEmpty ? line : '$markedItem\n$line';
      } else {
        final run = RunCounterService.parseLine(
          line,
          linePrefix: kind.runLinePrefix,
        );
        if (run != null) {
          runRecords[run.key] = run.value;
        } else if (RunCounterService.isRunLine(line)) {
          // 다른 리스트의 실행 카운터 줄은 이 리스트 카운터에 섞지 않는다.
        } else if (line.startsWith('[PJT]: ') || line.startsWith('[AWARE]: ')) {
          title = line.substring(line.indexOf(']: ') + 3);
        } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
          addLegacyItem();
          legacyItem.write(line.replaceFirst(RegExp(r'^\d+\. '), ''));
        } else if (line.trim().isNotEmpty) {
          if (legacyItem.isNotEmpty) legacyItem.write('\n');
          legacyItem.write(line);
        }
      }
    }

    if (markedItem != null) {
      items.add(markedItem.trim());
    } else {
      addLegacyItem();
    }

    return ListFileData(title: title, items: items, runRecords: runRecords);
  }
}

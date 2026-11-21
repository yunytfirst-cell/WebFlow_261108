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
    this.collapsed = const [],
  });

  final String? title;
  final List<String> items;
  final Map<String, int> runRecords;

  /// 항목별 접힘 상태 (items와 같은 길이). 접힌 항목은 파일 블록에 [FOLDED] 줄이 있다.
  final List<bool> collapsed;
}

class ListFileService {
  /// 항목 블록 머리 바로 다음 줄에 두는 접힘 표시 (2026-11-21 사용자 지시:
  /// 접기·펼치기 상태를 다시 열어도 그대로 유지)
  static const foldedMarker = '[FOLDED]';

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

  /// 저장할 파일 경로를 정한다 (2026-11-21 사용자 지시).
  ///
  /// - 열린 파일이 없으면 작업 폴더 [directory]에 제목 파일명 [fileName]으로 만든다.
  /// - 열린 파일 이름이 제목 파일명과 같으면(대소문자 무시, `제목 (2).txt`처럼 번호가 붙은 것도 같음)
  ///   그 파일에 덮어쓴다.
  /// - 제목이 열린 파일 이름과 다르면 **열린 파일과 같은 폴더에 제목 이름으로 새 파일**을 만든다.
  ///   열린(기존) 파일은 건드리지 않는다.
  /// - 새로 만들 이름의 파일이 이미 있으면 덮어쓰지 않고 `제목 (2).txt`, `제목 (3).txt` … 로 만든다.
  static String saveTargetPath({
    required String? currentFilePath,
    required String directory,
    required String fileName,
    bool Function(String path)? exists,
  }) {
    final fileExists = exists ?? (String path) => File(path).existsSync();
    if (currentFilePath != null &&
        _sameTitleFile(_baseName(currentFilePath), fileName)) {
      return currentFilePath;
    }
    final folder = currentFilePath == null
        ? directory
        : currentFilePath.substring(
            0, currentFilePath.length - _baseName(currentFilePath).length - 1);
    // 열린 파일이 없을 때 경로 조합은 기존 방식('$path/$fileName')을 유지한다
    final sep = currentFilePath == null ? '/' : Platform.pathSeparator;
    var candidate = '$folder$sep$fileName';
    final stem = _stem(fileName);
    for (var n = 2; fileExists(candidate); n++) {
      candidate = '$folder$sep$stem ($n).txt';
    }
    return candidate;
  }

  static String _baseName(String path) => path.split(RegExp(r'[/\\]')).last;

  static String _stem(String fileName) => fileName.toLowerCase().endsWith('.txt')
      ? fileName.substring(0, fileName.length - 4)
      : fileName;

  /// `제목.txt`와 `제목 (3).txt`를 같은 제목의 파일로 본다 (Windows처럼 대소문자 무시).
  static bool _sameTitleFile(String existingName, String fileName) {
    final pattern = RegExp(
      '^${RegExp.escape(_stem(fileName))}' r'( \(\d+\))?\.txt$',
      caseSensitive: false,
    );
    return pattern.hasMatch(existingName);
  }

  static String serialize({
    required ListFileKind kind,
    required String title,
    required List<String> items,
    required Map<String, int> runRecords,
    List<bool> collapsed = const [],
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
      content.writeln('[${kind.itemMarker}:${index + 1}]');
      if (index < collapsed.length && collapsed[index]) {
        content.writeln(foldedMarker);
      }
      content
        ..writeln(items[index])
        ..writeln('[END_${kind.itemMarker}]');
    }
    return content.toString();
  }

  static ListFileData parse(String content, {required ListFileKind kind}) {
    final items = <String>[];
    final collapsed = <bool>[];
    var markedFolded = false;
    final runRecords = <String, int>{};
    String? title;
    String? markedItem;
    final legacyItem = StringBuffer();

    void addLegacyItem() {
      final text = legacyItem.toString().trim();
      if (text.isNotEmpty) {
        items.add(text);
        collapsed.add(false);
      }
      legacyItem.clear();
    }

    for (final line in content.split('\n')) {
      final trimmedLine = line.trim();
      if (RegExp(r'^\[(GOAL|AWARE_ITEM):\d+\]$').hasMatch(trimmedLine)) {
        addLegacyItem();
        markedItem = '';
        markedFolded = false;
      } else if (RegExp(r'^\[END_(GOAL|AWARE_ITEM)\]$').hasMatch(trimmedLine) &&
          markedItem != null) {
        items.add(markedItem.trim());
        collapsed.add(markedFolded);
        markedItem = null;
      } else if (markedItem != null &&
          markedItem.isEmpty &&
          !markedFolded &&
          trimmedLine == foldedMarker) {
        markedFolded = true;
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
      collapsed.add(markedFolded);
    } else {
      addLegacyItem();
    }

    return ListFileData(
      title: title,
      items: items,
      runRecords: runRecords,
      collapsed: collapsed,
    );
  }

  /// 파일 내용에서 접힘 표시만 바꾼다 (제목·항목·카운터는 디스크 내용 그대로).
  /// 접기/펼치기를 누를 때 저장 버튼 없이 바로 기억하되, 저장하지 않은
  /// 다른 편집이 파일에 섞이지 않게 하려는 것이다.
  /// 1) 같은 글의 항목끼리 화면 순서대로 짝짓는다.
  /// 2) 글이 달라 남은 항목(저장 전에 글을 고친 항목)은 같은 순번끼리 짝짓는다.
  /// 화면에 짝이 없는 디스크 항목은 그대로 둔다.
  static String applyFoldState(
    String content, {
    required ListFileKind kind,
    required List<({String text, bool collapsed})> screenItems,
  }) {
    final data = parse(content, kind: kind);
    final used = List<bool>.filled(screenItems.length, false);
    final collapsed = List<bool>.of(data.collapsed);
    final matched = List<bool>.filled(data.items.length, false);
    for (var i = 0; i < data.items.length; i++) {
      for (var j = 0; j < screenItems.length; j++) {
        if (!used[j] && screenItems[j].text.trim() == data.items[i]) {
          used[j] = matched[i] = true;
          collapsed[i] = screenItems[j].collapsed;
          break;
        }
      }
    }
    for (var i = 0; i < data.items.length && i < screenItems.length; i++) {
      if (!matched[i] && !used[i]) {
        used[i] = matched[i] = true;
        collapsed[i] = screenItems[i].collapsed;
      }
    }
    return serialize(
      kind: kind,
      title: data.title ?? '',
      items: data.items,
      runRecords: data.runRecords,
      collapsed: collapsed,
    );
  }
}

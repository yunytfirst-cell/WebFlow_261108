import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flow/services/list_file_service.dart';
import 'package:flow/widgets/awareness_list_sidebar.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 불러오기 창 대신 다음에 열 파일 경로를 돌려주는 가짜 파일 선택창.
/// (FilePicker()를 상속하면 같은 토큰을 쓰므로 FilePicker.platform에 넣을 수 있다)
class _FakePicker extends FilePicker {
  String? next;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final path = next!;
    return FilePickerResult([
      PlatformFile(path: path, name: path.split(RegExp(r'[/\\]')).last, size: 0),
    ]);
  }
}

/// 사용자가 말한 실제 흐름을 진짜 파일로 검사한다 (2026-11-21 사용자 지시):
/// A 파일 열기 → 접기/펼치기 (저장 안 누름) → 다른 B 파일 열기 → A 다시 열기
/// → 사용자가 접거나 펼친 상태 그대로여야 한다.
void main() {
  late Directory dir;
  late _FakePicker picker;
  late String pathA;
  late String pathB;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('flow_fold_');
    picker = _FakePicker();
    FilePicker.platform = picker;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void writeFiles(ListFileKind kind) {
    final sep = Platform.pathSeparator;
    pathA = '${dir.path}${sep}A.txt';
    pathB = '${dir.path}${sep}B.txt';
    File(pathA).writeAsStringSync(ListFileService.serialize(
      kind: kind,
      title: 'A',
      items: ['A 첫째\n둘째 줄', 'A 짧음', 'A 셋째\n둘째 줄\n셋째 줄'],
      runRecords: {},
      collapsed: [false, false, true], // 셋째는 처음에 접힌 상태
    ));
    File(pathB).writeAsStringSync(ListFileService.serialize(
      kind: kind,
      title: 'B',
      items: ['B 항목\n둘째 줄'],
      runRecords: {},
    ));
  }

  void setWide(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// 실제 파일 읽기·쓰기가 끝나도록 진짜 시간을 조금씩 흘리며 화면을 다시 그린다
  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
  }

  /// 불러오기 버튼을 눌러 [path] 파일을 연다
  Future<void> open(WidgetTester tester, String path) async {
    picker.next = path;
    await tester.tap(find.text('불러오기'));
    await settleIo(tester);
  }

  /// 접기/펼치기 버튼을 누르고, 파일 쓰기가 끝날 때까지 기다린다
  Future<void> tapTooltip(WidgetTester tester, String tooltip, int index) async {
    await tester.tap(find.byTooltip(tooltip).at(index));
    await settleIo(tester);
  }

  Future<void> runFlow(
    WidgetTester tester,
    List<bool> Function() collapsedOnScreen,
    void Function(int index, String text) editText,
  ) async {
    await open(tester, pathA);
    expect(collapsedOnScreen(), [false, false, true]);

    // 1번 접기, 3번 펼치기 (저장 버튼은 누르지 않는다)
    await tapTooltip(tester, '접기', 0); // 펼쳐진 긴 항목 중 첫째 = 1번
    await tapTooltip(tester, '펼치기', 1); // 접힌 항목은 1번·3번 → 둘째 = 3번
    expect(collapsedOnScreen(), [true, false, false]);

    // 저장하지 않은 글 수정 뒤 접기도 기억해야 한다
    editText(2, 'A 셋째(고침)\n둘째 줄\n셋째 줄');
    await tester.pump();
    await tapTooltip(tester, '접기', 0); // 펼쳐진 긴 항목은 3번뿐
    expect(collapsedOnScreen(), [true, false, true]);

    // 다른 파일을 열었다가 A를 다시 연다
    await open(tester, pathB);
    expect(collapsedOnScreen(), [false]);
    await open(tester, pathA);

    expect(collapsedOnScreen(), [true, false, true]);
    expect(find.byTooltip('펼치기'), findsNWidgets(2));
    expect(find.byTooltip('접기'), findsNothing);

    // 저장 안 한 글 수정은 파일에 들어가지 않는다
    expect(File(pathA).readAsStringSync(), isNot(contains('(고침)')));
    expect(tester.takeException(), isNull);
  }

  testWidgets('끝장 리스트: 저장 없이 접기/펼치기 → 다른 파일 → 다시 열기 = 상태 유지', (tester) async {
    setWide(tester);
    writeFiles(ListFileKind.goal);
    final goals = [GoalItem()];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GoalListSidebar(
          loadDirectory: dir.path,
          runRecords: {},
          onRunRecordsChanged: () {},
          onLoadDirectoryChanged: (_) {},
          onSelectGoal: (_) {},
          onDeleteGoal: (_) {},
          onClose: () {},
          initialTitle: '',
          initialGoals: goals,
          onTitleChanged: (_) {},
          onGoalsChanged: (_) {},
          initialFilePath: null,
          onFilePathChanged: (_) {},
        ),
      ),
    ));

    await runFlow(
      tester,
      () => goals.map((g) => g.collapsed).toList(),
      (i, text) => goals[i]
        ..controller.text = text
        ..text = text,
    );
  });

  testWidgets('알아차림 리스트: 저장 없이 접기/펼치기 → 다른 파일 → 다시 열기 = 상태 유지', (tester) async {
    setWide(tester);
    writeFiles(ListFileKind.awareness);
    final items = [AwarenessItem()];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AwarenessListSidebar(
          loadDirectory: dir.path,
          runRecords: {},
          onRunRecordsChanged: () {},
          onLoadDirectoryChanged: (_) {},
          onClose: () {},
          initialTitle: '',
          initialItems: items,
          initialFilePath: null,
          onTitleChanged: (_) {},
          onItemsChanged: (_) {},
          onFilePathChanged: (_) {},
        ),
      ),
    ));

    await runFlow(
      tester,
      () => items.map((g) => g.collapsed).toList(),
      (i, text) => items[i]
        ..controller.text = text
        ..text = text,
    );
  });
}

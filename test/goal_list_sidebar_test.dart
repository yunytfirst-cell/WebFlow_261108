import 'dart:io';

import 'package:flow/widgets/awareness_list_sidebar.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
import 'package:flow/widgets/list_sidebar.dart';
import 'package:flow/widgets/run_counter_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 리스트 파일(빈 내용) 하나를 임시 폴더에 만들고 경로를 돌려준다.
String tempListFile() {
  final dir = Directory.systemTemp.createTempSync('flow_run_');
  final file = File('${dir.path}${Platform.pathSeparator}리스트.txt')
    ..writeAsStringSync('');
  addTearDown(() => dir.deleteSync(recursive: true));
  return file.path;
}

void main() {
  // 2026-11-26 사용자 지시: 내용이 없거나 불러온 파일이 없으면 실행 누적 화살표가 동작하지 않는다 (두 리스트)
  testWidgets('두 리스트: 내용이나 파일이 없으면 실행 화살표가 멈춘다', (tester) async {
    for (final (hasFile, title, text, works) in [
      (false, '', '', false),
      (false, '제목', '내용', false),
      (true, '', '', false),
      (true, '', '내용', true),
      (true, '제목', '', true),
    ]) {
      for (final goal in [true, false]) {
        final records = <String, int>{};
        final path = hasFile ? tempListFile() : null;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: goal
                  ? GoalListSidebar(
                      runRecords: records,
                      onRunRecordsChanged: () {},
                      onLoadDirectoryChanged: (_) {},
                      onSelectGoal: (_) {},
                      onDeleteGoal: (_) {},
                      onClose: () {},
                      initialTitle: title,
                      initialGoals: [GoalItem(text: text)],
                      onTitleChanged: (_) {},
                      onGoalsChanged: (_) {},
                      initialFilePath: path,
                      onFilePathChanged: (_) {},
                    )
                  : AwarenessListSidebar(
                      runRecords: records,
                      onRunRecordsChanged: () {},
                      onLoadDirectoryChanged: (_) {},
                      onClose: () {},
                      initialTitle: title,
                      initialItems: [AwarenessItem(text: text)],
                      initialFilePath: path,
                      onTitleChanged: (_) {},
                      onItemsChanged: (_) {},
                      onFilePathChanged: (_) {},
                    ),
            ),
          ),
        );
        final upIcon = find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.keyboard_arrow_up && w.size == 20,
        );
        await tester.tap(upIcon);
        await tester.pump();
        final reason = 'goal=$goal file=$hasFile title=$title text=$text';
        expect(
          records.values.fold<int>(0, (a, b) => a + b),
          works ? 1 : 0,
          reason: reason,
        );
        expect(
          find.byTooltip(RunCounterPanel.disabledTooltip),
          works ? findsNothing : findsNWidgets(2),
          reason: reason,
        );
        // 다른 사이드바로 바꿀 때 상태가 섞이지 않도록 비운다
        await tester.pumpWidget(const SizedBox());
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('알아차림 리스트는 자신에게 전달된 실행 카운터만 변경한다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final runRecords = <String, int>{};
    final file = tempListFile();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AwarenessListSidebar(
            runRecords: runRecords,
            onRunRecordsChanged: () {},
            onLoadDirectoryChanged: (_) {},
            onClose: () {},
            initialTitle: '',
            initialItems: [AwarenessItem(text: '내용')],
            initialFilePath: file,
            onTitleChanged: (_) {},
            onItemsChanged: (_) {},
            onFilePathChanged: (_) {},
          ),
        ),
      ),
    );

    // 2026-11-24: "오늘 실행 N" 대신 "실행" 글자만 보인다
    expect(find.text('실행'), findsOneWidget);
    expect(find.text('오늘 실행'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('오늘 실행 횟수 늘리기'));
    await tester.pump();

    expect(runRecords.values.fold<int>(0, (sum, count) => sum + count), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('실행 글자만 보이고 화살표는 누적을 바꾼다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalListSidebar(
            runRecords: {},
            onRunRecordsChanged: () {},
            onLoadDirectoryChanged: (_) {},
            onSelectGoal: (_) {},
            onDeleteGoal: (_) {},
            onClose: () {},
            initialTitle: '제목',
            initialGoals: [GoalItem()],
            onTitleChanged: (_) {},
            onGoalsChanged: (_) {},
            initialFilePath: tempListFile(),
            onFilePathChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('누적 0', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final width in [768.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Width: $width');
    }

    await tester.tap(find.byTooltip('오늘 실행 횟수 늘리기'));
    await tester.pump();

    // 오늘 숫자는 보이지 않고, 화살표 결과는 누적에 반영된다
    expect(find.text('누적 1', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Widget goalSidebar(List<GoalItem> goals) => MaterialApp(
    home: Scaffold(
      body: GoalListSidebar(
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
  );

  Widget awarenessSidebar(List<AwarenessItem> items) => MaterialApp(
    home: Scaffold(
      body: AwarenessListSidebar(
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
  );

  // 순번 입력칸 (숫자 키보드 TextField)
  final numberField = find.byWidgetPredicate(
    (w) => w is TextField && w.keyboardType == TextInputType.number,
  );

  void setWide(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('끝장 리스트: 순번을 입력하고 엔터를 누르면 그 위치로 옮겨지고 순번이 다시 매겨진다', (
    tester,
  ) async {
    setWide(tester);
    final goals = [
      GoalItem(text: 'A'),
      GoalItem(text: 'B'),
      GoalItem(text: 'C'),
    ];
    await tester.pumpWidget(goalSidebar(goals));

    await tester.tap(find.byTooltip('눌러서 순번 변경').at(2)); // C의 3번
    await tester.pump();
    await tester.enterText(numberField, '1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(goals.map((g) => g.text), ['C', 'A', 'B']);
    expect(find.byTooltip('눌러서 순번 변경'), findsNWidgets(3));

    // 범위를 넘는 번호는 맨 뒤로
    await tester.tap(find.byTooltip('눌러서 순번 변경').at(0));
    await tester.pump();
    await tester.enterText(numberField, '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(goals.map((g) => g.text), ['A', 'B', 'C']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('알아차림 리스트: 순번 변경과 긴 항목 접기/펼치기', (tester) async {
    setWide(tester);
    final items = [
      AwarenessItem(text: '짧음'),
      AwarenessItem(text: '첫 줄\n둘째 줄\n셋째 줄'),
    ];
    await tester.pumpWidget(awarenessSidebar(items));

    // 짧은 항목에는 버튼이 없고, 긴 항목에만 접기 버튼이 있다
    expect(find.byTooltip('접기'), findsOneWidget);
    await tester.tap(find.byTooltip('접기'));
    await tester.pump();
    expect(items[1].collapsed, isTrue);
    expect(find.text('첫 줄 둘째 줄 셋째 줄'), findsOneWidget);
    await tester.tap(find.byTooltip('펼치기'));
    await tester.pump();
    expect(items[1].collapsed, isFalse);

    await tester.tap(find.byTooltip('눌러서 순번 변경').at(1));
    await tester.pump();
    await tester.enterText(numberField, '1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(items.first.text, startsWith('첫 줄'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('끝장 리스트: 긴 항목은 상단 버튼으로 접고 펼친다', (tester) async {
    setWide(tester);
    final goals = [GoalItem(text: '첫 줄\n둘째 줄')];
    await tester.pumpWidget(goalSidebar(goals));

    await tester.tap(find.byTooltip('접기'));
    await tester.pump();
    expect(goals.first.collapsed, isTrue);
    expect(find.byTooltip('펼치기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 2026-11-24: 오른쪽 +,-,… 묶음 대신 접기/펼치기 버튼 좌우에 바로 보이는 버튼 (두 리스트)
  testWidgets('두 리스트: 항목 버튼이 접기 버튼 좌우에 항상 보이고 more 버튼은 없다', (tester) async {
    setWide(tester);
    final goals = [GoalItem(text: 'A'), GoalItem(text: '첫 줄\n둘째 줄')];
    await tester.pumpWidget(goalSidebar(goals));
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byTooltip('위로 이동'), findsNWidgets(2));
    expect(find.byTooltip('메인 화면으로 보내기'), findsNWidgets(2));
    // 접기 버튼 왼쪽에 ↑, 오른쪽에 + 가 있다
    final foldX = tester.getCenter(find.byTooltip('접기')).dx;
    expect(tester.getCenter(find.byTooltip('위로 이동').at(1)).dx, lessThan(foldX));
    expect(
      tester.getCenter(find.byTooltip('아래에 항목 추가').at(1)).dx,
      greaterThan(foldX),
    );
    await tester.tap(find.byTooltip('아래로 이동').first);
    await tester.pump();
    expect(goals.last.text, 'A');
    await tester.tap(find.byTooltip('아래에 항목 추가').first);
    await tester.pump();
    expect(goals.length, 3);

    final items = [AwarenessItem(text: 'B'), AwarenessItem(text: 'C')];
    await tester.pumpWidget(awarenessSidebar(items));
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byTooltip('메인 화면으로 보내기'), findsNothing);
    await tester.tap(find.byTooltip('위로 이동').last);
    await tester.pump();
    expect(items.first.text, 'C');
    expect(tester.takeException(), isNull);
  });

  // 2026-11-24: 접기 칸은 항상 사각형 박스, 접을 수 있을 때만 방향 모양 (두 리스트)
  testWidgets('두 리스트: 접기 박스는 항상 보이고 방향 모양은 긴 항목에만', (tester) async {
    setWide(tester);
    Finder arrows() => find.byWidgetPredicate(
      (w) =>
          w is Icon &&
          w.size == 18 &&
          (w.icon == Icons.keyboard_arrow_up ||
              w.icon == Icons.keyboard_arrow_down),
    );
    Finder boxes() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints?.maxWidth == 24 &&
          w.constraints?.maxHeight == 20,
    );
    await tester.pumpWidget(
      goalSidebar([GoalItem(text: '짧음'), GoalItem(text: '첫 줄\n둘째 줄')]),
    );
    expect(boxes(), findsNWidgets(2));
    expect(arrows(), findsOneWidget);

    await tester.pumpWidget(
      awarenessSidebar([AwarenessItem(text: '짧음'), AwarenessItem(text: '짧음2')]),
    );
    expect(boxes(), findsNWidgets(2));
    expect(arrows(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // 2026-11-24: 실행 박스는 제목 앞(위쪽 제목 줄), 화살표는 누적 오른쪽에 세로 (두 리스트)
  testWidgets('두 리스트: 실행 박스는 제목 앞, 화살표는 누적 오른쪽 세로', (tester) async {
    setWide(tester);
    for (final (sidebar, title) in [
      (goalSidebar([GoalItem()]), '📋성공의열쇠 시스템'),
      (awarenessSidebar([AwarenessItem()]), '👁️ 알아차림 리스트'),
    ]) {
      await tester.pumpWidget(sidebar);
      // 파일이 없어 화살표가 멈춘 상태(툴팁 = 멈춘 이유). 위치만 본다.
      final arrows = find.byTooltip(RunCounterPanel.disabledTooltip);
      final up = tester.getCenter(arrows.first);
      final down = tester.getCenter(arrows.last);
      expect(
        up.dx,
        greaterThan(tester.getTopRight(find.textContaining('누적')).dx),
      );
      expect(down.dy, greaterThan(up.dy));
      expect((down.dx - up.dx).abs(), lessThan(1));
      final panel = find.byType(RunCounterPanel);
      expect(
        tester.getTopRight(panel).dx,
        lessThan(tester.getTopLeft(find.text(title)).dx),
      );
      expect(
        tester.getCenter(panel).dy,
        lessThan(tester.getTopLeft(find.text('저장')).dy),
      );
      expect(tester.getSize(panel).height, lessThan(56));
    }
    for (final width in [360.0, 768.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(awarenessSidebar([AwarenessItem()]));
      await tester.pumpWidget(goalSidebar([GoalItem()]));
      expect(tester.takeException(), isNull, reason: 'Width: $width');
    }
  });

  // 2026-11-24: 사이드바 폭이 좁으면 항목 글자·아이콘도 함께 작아진다 (두 리스트, 불러온 항목 포함)
  testWidgets('두 리스트: 좁은 폭에서 항목 글자가 작아진다', (tester) async {
    double itemFont() => tester
        .widget<TextField>(
          find
              .byWidgetPredicate(
                (w) => w is TextField && w.keyboardType != TextInputType.number,
              )
              .last,
        )
        .style!
        .fontSize!;
    for (final build in [
      () => goalSidebar([GoalItem(text: '항목')]),
      () => awarenessSidebar([AwarenessItem(text: '항목')]),
    ]) {
      setWide(tester);
      await tester.pumpWidget(build());
      expect(itemFont(), 14);
      tester.view.physicalSize = const Size(600, 900); // 사이드바 폭 288
      await tester.pumpWidget(build());
      expect(itemFont(), lessThan(14));
      expect(itemFont(), greaterThanOrEqualTo(14 * 0.7));
    }
    expect(tester.takeException(), isNull);
  });

  // 2026-11-25: 동작 버튼 오른쪽 서식 툴박스(색·크기·굵게·기울임·밑줄·가운데 줄), 두 리스트.
  // 항목 글 전체가 아니라 드래그해 선택한 글자에만 적용한다.
  testWidgets('두 리스트: 서식 툴박스는 버튼 오른쪽에 있고 선택한 글자만 바꾼다', (tester) async {
    final goals = [GoalItem(text: '항목글자')];
    final items = [AwarenessItem(text: '항목글자')];
    for (final (build, controller) in [
      (() => goalSidebar(goals), goals.first.controller),
      (() => awarenessSidebar(items), items.first.controller),
    ]) {
      setWide(tester);
      await tester.pumpWidget(build());
      // 색 목록·편집 목록은 처음엔 숨기고 아이콘 버튼 2개만 보인다
      expect(find.byTooltip('기울임'), findsNothing);
      expect(find.byTooltip('글자 색'), findsNothing);
      expect(
        tester.getCenter(find.byTooltip('글자 편집 목록 열기')).dx,
        greaterThan(tester.getCenter(find.text('폴더관리')).dx),
      );
      await tester.tap(find.byTooltip('글자 색 목록 열기'));
      await tester.tap(find.byTooltip('글자 편집 목록 열기'));
      await tester.pump();
      expect(find.byTooltip('기울임'), findsOneWidget);
      expect(find.byTooltip('글자 색'), findsWidgets);

      // 글자를 선택하기 전에는 눌러도 바뀌지 않는다
      await tester.tap(find.text('항목글자').last);
      await tester.pump();
      await tester.tap(find.byTooltip('기울임'), warnIfMissed: false);
      await tester.pump();
      expect(controller.charStyles.every((s) => s.isPlain), isTrue);

      // 가운데 두 글자(목글)만 선택
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 3,
      );
      await tester.pump();
      for (final tip in ['굵게', '기울임', '밑줄', '가운데 줄']) {
        await tester.tap(find.byTooltip(tip));
        await tester.pump();
      }
      await tester.tap(find.byTooltip('글자 색').first);
      await tester.pump();
      // 크기 A+ 한 번 = 크게(1.2). 툴박스 버튼은 입력칸 선택을 풀지 않는다
      await tester.tap(find.byTooltip('글자 크게'));
      await tester.pump();
      expect(controller.lastRange, const TextRange(start: 1, end: 3));

      final chars = controller.charStyles;
      expect(chars[0].isPlain, isTrue);
      expect(chars[3].isPlain, isTrue);
      for (final s in [chars[1], chars[2]]) {
        expect(s.bold && s.italic && s.underline && s.strike, isTrue);
        expect(s.color, 0xE6B422);
        expect(s.sizeScale, 1.2);
      }
      // 화면에도 선택 구간만 서식이 입혀져 그려진다
      final span = controller.styledSpan(const TextStyle(fontSize: 14));
      final runs = span.children!.cast<TextSpan>();
      expect(runs.map((r) => r.text).toList(), ['항', '목글', '자']);
      expect(runs[1].style!.fontStyle, FontStyle.italic);
      expect(runs[1].style!.fontSize, moreOrLessEquals(14 * 1.2));
      expect(runs[0].style!.fontStyle, isNot(FontStyle.italic));
      // 저장할 구간
      expect(controller.spans.length, 1);
      expect(
        (controller.spans.first.start, controller.spans.first.end),
        (1, 3),
      );

      // 앞에 글자를 넣으면 서식 구간도 함께 밀린다
      controller.text = '새${controller.text}';
      expect(
        (controller.spans.first.start, controller.spans.first.end),
        (2, 4),
      );

      // 다시 누르면 목록이 숨는다
      await tester.tap(find.byTooltip('글자 색 목록 닫기'));
      await tester.tap(find.byTooltip('글자 편집 목록 닫기'));
      await tester.pump();
      expect(find.byTooltip('기울임'), findsNothing);
      expect(find.byTooltip('글자 색'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  // 2026-11-26 사용자 지시: 메인 화면에 보낸 항목의 🎯는 밝게(배경 포함), 나머지는 어둡게
  testWidgets('끝장 리스트: 보낸 항목의 🎯만 밝고 나머지는 어둡다', (tester) async {
    setWide(tester);
    final goals = [GoalItem(text: 'A'), GoalItem(text: 'B')];
    var selected = '';
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: GoalListSidebar(
              runRecords: {},
              onRunRecordsChanged: () {},
              onLoadDirectoryChanged: (_) {},
              selectedGoal: selected,
              onSelectGoal: (g) =>
                  setState(() => selected = selected == g ? '' : g),
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
        ),
      ),
    );
    List<Color?> colors() => tester
        .widgetList<Icon>(find.byIcon(Icons.gps_fixed))
        .map((i) => i.color)
        .toList();

    expect(colors(), [ListSidebar.sendOffColor, ListSidebar.sendOffColor]);
    await tester.tap(find.byTooltip('메인 화면으로 보내기').at(1));
    await tester.pump();
    expect(selected, 'B');
    expect(colors(), [ListSidebar.sendOffColor, ListSidebar.sendOnColor]);
    // 다시 누르면 꺼진다
    await tester.tap(find.byTooltip('메인 화면으로 보내기').at(1));
    await tester.pump();
    expect(colors(), [ListSidebar.sendOffColor, ListSidebar.sendOffColor]);
    expect(ListSidebar.sendSummary('가나다라마바사아자차카타파\n둘째'), '가나다라마바사아자차카타...');
    expect(tester.takeException(), isNull);
  });
}

import 'package:flow/widgets/awareness_list_sidebar.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
import 'package:flow/widgets/run_counter_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('알아차림 리스트는 자신에게 전달된 실행 카운터만 변경한다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final runRecords = <String, int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AwarenessListSidebar(
            runRecords: runRecords,
            onRunRecordsChanged: () {},
            onLoadDirectoryChanged: (_) {},
            onClose: () {},
            initialTitle: '',
            initialItems: [AwarenessItem()],
            initialFilePath: null,
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
            initialTitle: '',
            initialGoals: [GoalItem()],
            onTitleChanged: (_) {},
            onGoalsChanged: (_) {},
            initialFilePath: null,
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

  // 2026-11-24: 화살표는 누적 박스 오른쪽, 오늘 실행 박스 높이는 예전(약 100)의 절반 (두 리스트)
  testWidgets('두 리스트: 실행 카운터 화살표는 누적 오른쪽, 박스는 낮다', (tester) async {
    setWide(tester);
    for (final sidebar in [
      goalSidebar([GoalItem()]),
      awarenessSidebar([AwarenessItem()]),
    ]) {
      await tester.pumpWidget(sidebar);
      final totalX = tester.getTopRight(find.textContaining('누적')).dx;
      expect(
        tester.getCenter(find.byTooltip('오늘 실행 횟수 늘리기')).dx,
        greaterThan(totalX),
      );
      expect(
        tester.getCenter(find.byTooltip('오늘 실행 횟수 줄이기')).dx,
        greaterThan(tester.getCenter(find.byTooltip('오늘 실행 횟수 늘리기')).dx),
      );
      expect(tester.getSize(find.byType(RunCounterPanel)).height, lessThan(56));
    }
    expect(tester.takeException(), isNull);
  });
}

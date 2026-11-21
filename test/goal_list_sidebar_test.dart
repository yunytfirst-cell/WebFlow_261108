import 'package:flow/widgets/awareness_list_sidebar.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
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

    expect(find.text('오늘 실행'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('오늘 실행 횟수 늘리기'));
    await tester.pump();

    expect(runRecords.values.fold<int>(0, (sum, count) => sum + count), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('오늘 실행은 한 자리로 표시되고 화살표로 변경된다', (WidgetTester tester) async {
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

    expect(find.text('0'), findsOneWidget);
    expect(find.text('00'), findsNothing);
    expect(tester.takeException(), isNull);

    for (final width in [768.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Width: $width');
    }

    await tester.tap(find.byTooltip('오늘 실행 횟수 늘리기'));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == '1' &&
            widget.style?.color == Colors.amberAccent,
      ),
      findsOneWidget,
    );
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
}

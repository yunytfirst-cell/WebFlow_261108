import 'package:flow/widgets/awareness_list_sidebar.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('알아차림 리스트도 공유 실행 카운터를 사용한다', (WidgetTester tester) async {
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
}

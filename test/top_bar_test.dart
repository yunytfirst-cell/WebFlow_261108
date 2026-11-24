import 'package:flow/models/design_theme.dart';
import 'package:flow/widgets/goal_title_display.dart';
import 'package:flow/widgets/top_bar.dart';
import 'package:flow/widgets/top_bar_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-11-24: Daily 앞 + 버튼으로 상단 컨트롤을 접고 펼친다
  testWidgets('상단 + 버튼으로 컨트롤 아이콘을 접고 펼친다', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopBar(
            selectedSubGoal: '',
            sidebarGoals: const [],
            scrollController: controller,
            maxWidth: 1280,
            maxHeight: 800,
            onClose: () {},
            onToggleDisplayMode: () {},
            currentModeName: 'focus',
            theme: AppThemeData.getTheme(AppThemeMode.values.first),
            currentTime: DateTime(2026, 11, 24, 9),
          ),
        ),
      ),
    );

    final daily = find.byTooltip('Daily 스케줄');
    // 컨트롤 행 위쪽 여백(창 위 끝에서 24 이상 떨어짐)
    expect(tester.getTopLeft(daily).dy, greaterThanOrEqualTo(TopBar.topGap));
    final theme = find.byTooltip(RegExp('^테마'));
    expect(daily, findsOneWidget);
    // + 버튼은 Daily 앞(왼쪽)
    expect(
      tester.getCenter(find.byTooltip('컨트롤 접기')).dx,
      lessThan(tester.getCenter(daily).dx),
    );
    expect(theme, findsOneWidget);

    // 목표바(티커·목표 제목)는 −/+ 버튼 왼쪽 끝 ~ 설정 아이콘 오른쪽 끝에 맞춘다
    await tester.pump();
    final toggleLeft = tester.getTopLeft(find.byTooltip('컨트롤 접기')).dx;
    final settingsRight = tester.getTopRight(find.byTooltip('설정')).dx;
    for (final bar in [
      find.byType(TopBarTicker),
      find.byType(GoalTitleDisplay),
    ]) {
      expect(
        tester.getTopLeft(bar).dx,
        moreOrLessEquals(toggleLeft, epsilon: 1),
      );
      expect(
        tester.getTopRight(bar).dx,
        moreOrLessEquals(settingsRight, epsilon: 1),
      );
    }
    await tester.tap(find.byTooltip('컨트롤 접기'));
    await tester.pump();
    expect(daily, findsNothing);
    expect(theme, findsNothing);
    expect(find.byTooltip('컨트롤 펼치기'), findsOneWidget);

    await tester.tap(find.byTooltip('컨트롤 펼치기'));
    await tester.pump();
    expect(daily, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

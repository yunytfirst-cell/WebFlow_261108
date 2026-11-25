import 'package:flow/models/design_theme.dart';
import 'package:flow/widgets/daily_schedule_box.dart';
import 'package:flow/widgets/goal_title_display.dart';
import 'package:flow/widgets/top_bar.dart';
import 'package:flow/widgets/top_bar_ticker.dart';
import 'package:flow/widgets/finish_flag_icon.dart';
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
    // 목표 표시바와 STEP(티커) 바는 크기가 같다
    final titleSize = tester.getSize(find.byType(GoalTitleDisplay));
    final tickerSize = tester.getSize(find.byType(TopBarTicker));
    expect(titleSize.width, moreOrLessEquals(tickerSize.width, epsilon: 0.5));
    expect(titleSize.height, moreOrLessEquals(tickerSize.height, epsilon: 0.5));
    // 2026-11-25 사용자 지시: STEP > 박스 글자는 목표 박스 글자의 2/3 (박스 크기는 그대로)
    expect(TopBarTicker.textScale, 2 / 3);
    // 2026-11-25 사용자 지시: "ITEM FINISH" 글자 대신 깃발 아이콘(FINISH)을 STEP 박스 가운데에
    expect(find.text('ITEM FINISH'), findsNothing);
    final flag = find.byType(FinishFlagIcon);
    expect(flag, findsOneWidget);
    expect(find.text('FINISH'), findsOneWidget);
    expect(
      tester.getCenter(flag).dx,
      moreOrLessEquals(tester.getCenter(find.byType(TopBarTicker)).dx, epsilon: 1),
    );
    expect(
      tester.getSize(flag).height,
      lessThanOrEqualTo(tester.getSize(find.byType(TopBarTicker)).height),
    );

    // 2026-11-25 사용자 지시: 아이콘 행~목표 박스 간격을 1/2로(목표 박스를 위로), STEP 박스 위치는 그대로
    final tickerRect = tester.getRect(find.byType(TopBarTicker));
    final goalRect = tester.getRect(find.byType(GoalTitleDisplay));
    final oldGoalTop = tickerRect.top - 10 - goalRect.height;
    expect(goalRect.top, lessThan(oldGoalTop - 1));
    // 옮긴 거리 = 남은 간격 → 아이콘 행 아래 끝 = 2*새 위치 - 예전 위치, 아이콘들은 그 위에 있다
    final rowBottom = 2 * goalRect.top - oldGoalTop;
    expect(
      tester.getBottomLeft(find.byTooltip('설정')).dy,
      lessThanOrEqualTo(rowBottom + 0.5),
    );
    expect(rowBottom, lessThan(goalRect.top));

    // 접어도 + 버튼은 − 버튼이 있던 자리·크기 그대로 (2026-11-24 사용자 지적)
    final toggleRect = tester.getRect(find.byTooltip('컨트롤 접기'));
    await tester.tap(find.byTooltip('컨트롤 접기'));
    await tester.pump();
    expect(daily.hitTestable(), findsNothing);
    expect(theme.hitTestable(), findsNothing);
    expect(find.byTooltip('컨트롤 펼치기'), findsOneWidget);
    expect(tester.getRect(find.byTooltip('컨트롤 펼치기')), toggleRect);

    await tester.tap(find.byTooltip('컨트롤 펼치기'));
    await tester.pump();
    expect(daily.hitTestable(), findsOneWidget);
    expect(tester.getRect(find.byTooltip('컨트롤 접기')), toggleRect);
    expect(tester.takeException(), isNull);
  });

  // 2026-11-24: Daily 스케줄 표시바도 −버튼 왼쪽 끝 ~ 설정 오른쪽 끝, 현재 시간은 왼쪽 끝
  testWidgets('Daily 스케줄 표시바 정렬과 현재 시간 위치', (tester) async {
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
            currentTime: DateTime(2026, 11, 24, 9, 5),
            showDailyScheduleBox: true,
            dailySchedule: List.filled(27, '운동'),
          ),
        ),
      ),
    );
    await tester.pump();

    final box = find.byType(DailyScheduleBox);
    expect(
      tester.getTopLeft(box).dx,
      moreOrLessEquals(
        tester.getTopLeft(find.byTooltip('컨트롤 접기')).dx,
        epsilon: 1,
      ),
    );
    expect(
      tester.getTopRight(box).dx,
      moreOrLessEquals(tester.getTopRight(find.byTooltip('설정')).dx, epsilon: 1),
    );
    final timeX = tester.getTopLeft(find.text('09:05')).dx;
    // 시계 아이콘·감싸는 박스 없음, 색 칸은 박스 왼쪽 끝에서 시작
    expect(find.byIcon(Icons.access_time_filled), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    final timeCell = find.ancestor(
      of: find.text('09:05'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.color != null,
      ),
    );
    expect(
      tester.getTopLeft(timeCell.first).dx,
      moreOrLessEquals(tester.getTopLeft(box).dx, epsilon: 0.5),
    );
    expect(
      tester.getTopRight(timeCell.first).dx,
      greaterThan(tester.getTopRight(find.text('09:05')).dx),
    );
    expect(timeX, lessThan(tester.getTopLeft(find.text('운동')).dx));
    expect(tester.takeException(), isNull);
  });
}

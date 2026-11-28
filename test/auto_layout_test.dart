import 'package:flow/models/design_theme.dart';
import 'package:flow/widgets/awareness_list_sidebar.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
import 'package:flow/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 오토레이아웃 점검 (2026-11-25 사용자 지시 "오토레이아웃 점검 skill에 포함").
/// 여러 창 크기 × 윈도우 글자 크기(100·130·160%)에서 상단바(보내기 전·후)와 두 리스트 사이드바를 그려
/// 넘침(RenderFlex overflow 등) 예외가 없는지, 주요 요소가 창 안에 있는지 본다.
/// 새 화면 요소를 만들거나 크기·배치를 바꾸면 이 테스트가 통과해야 한다(flow-skill-record 기본 원칙 9).
void main() {
  const windows = [
    Size(800, 600),
    Size(1024, 700),
    Size(1280, 800),
    Size(1920, 1080),
    Size(2560, 1440),
  ];
  const textScales = [1.0, 1.3, 1.6];

  Widget app(Size size, double scale, Widget child) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  );

  void setWindow(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }

  testWidgets('상단바: 창 크기·글자 크기가 바뀌어도 넘치지 않는다', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final goals = [GoalItem(text: '아주 긴 단계 이름 아주 긴 단계 이름 아주 긴 단계 이름\n두 번째 단계')];
    for (final size in windows) {
      for (final scale in textScales) {
        for (final selected in ['', '아주 긴 단계 이름']) {
          setWindow(tester, size);
          await tester.pumpWidget(
            app(
              size,
              scale,
              TopBar(
                selectedSubGoal: selected,
                sidebarGoals: goals,
                sidebarTitle: '아주 긴 목표 제목 아주 긴 목표 제목 아주 긴 목표 제목',
                scrollController: controller,
                maxWidth: size.width,
                maxHeight: size.height,
                onClose: () {},
                onToggleDisplayMode: () {},
                currentModeName: 'focus',
                theme: AppThemeData.getTheme(AppThemeMode.values.first),
                currentTime: DateTime(2026, 11, 25, 9),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final where = '창 $size, 글자 $scale, 보내기 ${selected.isNotEmpty}';
          expect(tester.takeException(), isNull, reason: where);
          // 컨트롤 아이콘(설정)은 창 안에 있어야 한다
          final settings = tester.getRect(find.byTooltip('설정'));
          expect(
            settings.left >= 0 && settings.right <= size.width,
            isTrue,
            reason: '$where 설정 아이콘 $settings',
          );
        }
      }
    }
    // STEP 글 마퀴 타이머가 남지 않게 화면을 비우고 시간을 흘린다
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('두 리스트 사이드바: 창 크기·글자 크기가 바뀌어도 넘치지 않는다', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in windows) {
      for (final scale in textScales) {
        setWindow(tester, size);
        final where = '창 $size, 글자 $scale';
        await tester.pumpWidget(
          app(
            size,
            scale,
            Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: GoalListSidebar(
                    runRecords: {'2026-11-25': 12},
                    onRunRecordsChanged: () {},
                    onLoadDirectoryChanged: (_) {},
                    onSelectGoal: (_) {},
                    onDeleteGoal: (_) {},
                    onClose: () {},
                    initialTitle: '긴 제목 긴 제목 긴 제목 긴 제목',
                    initialGoals: [
                      GoalItem(text: '짧은 항목'),
                      GoalItem(text: '긴 항목 ' * 20),
                    ],
                    initialFilePath: null,
                    onTitleChanged: (_) {},
                    onGoalsChanged: (_) {},
                    onFilePathChanged: (_) {},
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: AwarenessListSidebar(
                    onSelectItem: (_) {},
                    onDeleteItem: (_) {},
                    runRecords: {'2026-11-25': 3},
                    onRunRecordsChanged: () {},
                    onLoadDirectoryChanged: (_) {},
                    onClose: () {},
                    initialTitle: '긴 제목 긴 제목 긴 제목 긴 제목',
                    initialItems: [
                      AwarenessItem(text: '짧은 항목'),
                      AwarenessItem(text: '긴 항목 ' * 20),
                    ],
                    initialFilePath: null,
                    onTitleChanged: (_) {},
                    onItemsChanged: (_) {},
                    onFilePathChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: where);
        // 2026-11-28: 스크롤바는 폭 조절 드래그 영역의 반대편 가장자리에 붙는다
        // (끝장=오른쪽, 알아차림=왼쪽). 스크롤바 쪽은 Scrollbar 위의 글 방향으로 정해진다.
        final bars = find.byType(Scrollbar).evaluate().toList();
        final edges = find
            .byWidgetPredicate(
              (w) =>
                  w is MouseRegion &&
                  w.cursor == SystemMouseCursors.resizeLeftRight,
            )
            .evaluate()
            .toList();
        expect(bars.length, 2, reason: where);
        expect(edges.length, 2, reason: where);
        final barSides = <String>{};
        for (final b in bars) {
          final r = tester.getRect(find.byWidget(b.widget));
          final onLeft = Directionality.of(b) == TextDirection.rtl;
          barSides.add(onLeft ? 'left' : 'right');
          final barRect = onLeft
              ? Rect.fromLTRB(r.left, r.top, r.left + 10, r.bottom)
              : Rect.fromLTRB(r.right - 10, r.top, r.right, r.bottom);
          for (final e in edges) {
            final er = tester.getRect(find.byWidget(e.widget));
            expect(
              barRect.left < er.right && barRect.right > er.left,
              isFalse,
              reason: '$where 스크롤바 $barRect 드래그 $er',
            );
          }
        }
        expect(barSides, {'left', 'right'}, reason: where);
        // 저장 버튼·서식 툴박스 버튼이 창 안에 보인다
        for (final f in [find.text('저장'), find.byTooltip('글자 편집 목록 열기')]) {
          for (final r in f.evaluate().map(
            (e) => tester.getRect(find.byWidget(e.widget)),
          )) {
            expect(
              r.left >= 0 && r.right <= size.width,
              isTrue,
              reason: '$where $r',
            );
          }
        }
      }
    }
  });
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flow/models/design_theme.dart';
import 'package:flow/services/item_text_style.dart';
import 'package:flow/widgets/awareness_list_sidebar.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
import 'package:flow/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 리팩터링(모듈화·코드 크기·속도 정리) 전후로 화면이 픽셀까지 같은지 비교하기 위한 스냅샷.
/// 실제 윈도우 앱(실제 글꼴)으로 여러 상태를 그려 PNG로 저장한다.
///
/// 실행: flutter test integration_test/identity_snapshot_test.dart -d windows --dart-define=OUT=build/identity_before
///       (바꾼 뒤 OUT=build/identity_after 로 다시 찍고 tools/compare_snapshots.py 로 비교)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const out = String.fromEnvironment('OUT', defaultValue: 'build/identity');

  testWidgets('화면 스냅샷', (tester) async {
    // 글자 커서 깜빡임 때문에 찍을 때마다 2px 선이 달라지지 않게 커서를 고정한다
    EditableText.debugDeterministicCursor = true;
    addTearDown(() => EditableText.debugDeterministicCursor = false);
    final key = GlobalKey();
    Directory(out).createSync(recursive: true);

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
      // ignore: use_build_context_synchronously
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1.0);
      final png = (await img.toByteData(format: ui.ImageByteFormat.png))!;
      File('$out/$name.png').writeAsBytesSync(png.buffer.asUint8List());
    }

    Widget frame(Widget child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: RepaintBoundary(
              key: key,
              child: ColoredBox(color: const Color(0xFF203040), child: child),
            ),
          ),
        );

    List<GoalItem> goals() => [
          GoalItem(text: '짧은 항목'),
          GoalItem(text: '첫 줄 긴 항목입니다 첫 줄 긴 항목입니다 첫 줄 긴 항목입니다\n둘째 줄'),
          GoalItem(text: '접힌 긴 항목 접힌 긴 항목 접힌 긴 항목 접힌 긴 항목 접힌 긴 항목')..collapsed = true,
          GoalItem(text: '서식 있는 항목')
            ..controller.spans = const [
              StyleSpan(0, 2, ItemTextStyle(color: 0xE6B422, bold: true)),
              StyleSpan(3, 5, ItemTextStyle(italic: true, underline: true, strike: true, sizeScale: 1.2)),
            ],
        ];
    List<AwarenessItem> items() => [
          AwarenessItem(text: '짧은 항목'),
          AwarenessItem(text: '첫 줄 긴 항목입니다 첫 줄 긴 항목입니다 첫 줄 긴 항목입니다\n둘째 줄'),
          AwarenessItem(text: '접힌 긴 항목 접힌 긴 항목 접힌 긴 항목 접힌 긴 항목 접힌 긴 항목')..collapsed = true,
          AwarenessItem(text: '서식 있는 항목')
            ..controller.spans = const [
              StyleSpan(0, 2, ItemTextStyle(color: 0x5BC0EB, bold: true)),
              StyleSpan(3, 5, ItemTextStyle(italic: true, underline: true, strike: true, sizeScale: 0.85)),
            ],
        ];

    Widget goalSidebar(List<GoalItem> g) => Stack(children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: GoalListSidebar(
              runRecords: {'2026-11-25': 3, '2026-11-24': 2},
              onRunRecordsChanged: () {},
              onLoadDirectoryChanged: (_) {},
              onSelectGoal: (_) {},
              onDeleteGoal: (_) {},
              onClose: () {},
              initialTitle: '오늘 목표',
              initialGoals: g,
              initialFilePath: null,
              onTitleChanged: (_) {},
              onGoalsChanged: (_) {},
              onFilePathChanged: (_) {},
            ),
          ),
        ]);
    Widget awarenessSidebar(List<AwarenessItem> a) => Stack(children: [
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            child: AwarenessListSidebar(
              onSelectItem: (_) {},
              onDeleteItem: (_) {},
              runRecords: {'2026-11-25': 1},
              onRunRecordsChanged: () {},
              onLoadDirectoryChanged: (_) {},
              onClose: () {},
              initialTitle: '오늘 알아차림',
              initialItems: a,
              initialFilePath: null,
              onTitleChanged: (_) {},
              onItemsChanged: (_) {},
              onFilePathChanged: (_) {},
            ),
          ),
        ]);

    // 1) 두 사이드바 기본
    await tester.pumpWidget(frame(goalSidebar(goals())));
    await shot('goal_default');
    // 서식 대상 선택 + 툴박스 두 목록 열기 + 순번 편집칸
    await tester.tap(find.text('짧은 항목').last);
    await tester.pump();
    await tester.tap(find.byTooltip('글자 색 목록 열기'));
    await tester.tap(find.byTooltip('글자 편집 목록 열기'));
    await shot('goal_toolbox_open');
    await tester.tap(find.byTooltip('눌러서 순번 변경').first);
    await shot('goal_number_edit');

    await tester.pumpWidget(frame(const SizedBox()));
    await tester.pumpWidget(frame(awarenessSidebar(items())));
    await shot('awareness_default');
    await tester.tap(find.text('짧은 항목').last);
    await tester.pump();
    await tester.tap(find.byTooltip('글자 색 목록 열기'));
    await tester.tap(find.byTooltip('글자 편집 목록 열기'));
    await shot('awareness_toolbox_open');
    await tester.tap(find.byTooltip('눌러서 순번 변경').first);
    await shot('awareness_number_edit');

    // 2) 상단바: 보내기 전 / 보낸 뒤
    final controller = ScrollController();
    final barGoals = [GoalItem(text: '할일\n두번째 단계')];
    Widget bar(String sel) => frame(LayoutBuilder(
          builder: (context, c) => TopBar(
            selectedSubGoal: sel,
            sidebarGoals: barGoals,
            sidebarTitle: '1. 1페이지 노출',
            scrollController: controller,
            maxWidth: c.maxWidth,
            maxHeight: c.maxHeight,
            onClose: () {},
            onToggleDisplayMode: () {},
            currentModeName: 'focus',
            theme: AppThemeData.getTheme(AppThemeMode.values.first),
            currentTime: DateTime(2026, 11, 25, 9),
          ),
        ));
    await tester.pumpWidget(frame(const SizedBox()));
    await tester.pumpWidget(bar(''));
    await shot('topbar_idle');
    await tester.pumpWidget(bar('할일'));
    await shot('topbar_sent');
  });
}

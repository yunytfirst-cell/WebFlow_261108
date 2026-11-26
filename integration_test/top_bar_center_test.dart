import 'dart:io';
import 'dart:ui' as ui;

import 'package:flow/models/design_theme.dart';
import 'package:flow/widgets/finish_flag_icon.dart';
import 'package:flow/widgets/goal_list_sidebar.dart';
import 'package:flow/widgets/goal_title_display.dart';
import 'package:flow/widgets/top_bar.dart';
import 'package:flow/widgets/top_bar_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 실제 윈도우 앱(실제 글꼴, 윈도우 "텍스트 크기" 설정 그대로)에서 목표·STEP 박스의
/// 아이콘과 글자 세로 가운데가 맞는지 픽셀로 잰다
/// (2026-11-25 사용자 지적 "글자 중앙이 맞지 않는다" → "그냥 아이콘 위치만 변경").
/// 일반 `flutter test`의 글꼴(Ahem)은 위아래 대칭이라 이 차이가 보이지 않는다.
///
/// 실행: flutter test integration_test/top_bar_center_test.dart -d windows
///       (글자 크기 바꿔 보기: --dart-define=TEXT_SCALE=1.3)
/// 결과: build/top_bar_center_report.txt, build/top_bar_center.png
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('목표 과녁·STEP 깃발 가운데 = 글자 가운데', (tester) async {
    final controller = ScrollController();
    final goals = [GoalItem(text: '할일')];
    final key = GlobalKey();
    final theme = AppThemeData.getTheme(AppThemeMode.values.first);
    const forced = String.fromEnvironment('TEXT_SCALE');
    Widget bar(String sel) => MaterialApp(
          builder: forced.isEmpty
              ? null
              : (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(double.parse(forced)),
                    ),
                    child: child!,
                  ),
          home: Scaffold(
            backgroundColor: Colors.black,
            body: LayoutBuilder(
              builder: (context, c) => RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: Colors.black,
                  child: TopBar(
                    selectedSubGoal: sel,
                    sidebarGoals: goals,
                    sidebarTitle: '1. 1페이지 노출',
                    scrollController: controller,
                    maxWidth: c.maxWidth,
                    maxHeight: c.maxHeight,
                    onClose: () {},
                    onToggleDisplayMode: () {},
                    currentModeName: 'focus',
                    theme: theme,
                    currentTime: DateTime(2026, 11, 25, 9),
                  ),
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(bar(''));
    await tester.pump();
    await tester.pumpWidget(bar('할일'));
    await tester.pumpAndSettle();
    // 과녁 이미지가 그려질 때까지 기다린다
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();

    // ignore: use_build_context_synchronously
    final ctx = key.currentContext!;
    // ignore: use_build_context_synchronously
    final dpr = MediaQuery.of(ctx).devicePixelRatio;
    // ignore: use_build_context_synchronously
    final scale = MediaQuery.of(ctx).textScaler.scale(10) / 10;
    // ignore: use_build_context_synchronously
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
    final origin = boundary.localToGlobal(Offset.zero);
    final img = await boundary.toImage(pixelRatio: dpr);
    final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;

    // [x0, x1) 사이에서 조건에 맞는 픽셀이 있는 줄의 위·아래 끝 → 가운데 y
    double inkMid(Rect box, double x0, double x1, bool Function(int r, int g, int b) hit) {
      int top = -1, bottom = -1;
      final px0 = ((x0 - origin.dx) * dpr).round();
      final px1 = ((x1 - origin.dx) * dpr).round().clamp(0, img.width);
      final y0 = ((box.top - box.height * 0.3 - origin.dy) * dpr).round().clamp(0, img.height - 1);
      final y1 = ((box.bottom + box.height * 0.3 - origin.dy) * dpr).round().clamp(0, img.height - 1);
      for (var y = y0; y <= y1; y++) {
        for (var x = px0; x < px1; x++) {
          final i = (y * img.width + x) * 4;
          if (hit(data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2))) {
            if (top < 0) top = y;
            bottom = y;
            break;
          }
        }
      }
      return ((top + bottom + 1) / 2) / dpr + origin.dy;
    }

    bool bright(int r, int g, int b) => r + g + b > 150;
    // 깃발의 흰 칸·깃대만 (청록색 FINISH 글자 제외)
    bool white(int r, int g, int b) => r > 200 && g > 200 && b > 200;

    final goalBox = tester.getRect(find.byType(GoalTitleDisplay));
    final goalText = tester.getRect(find.text('1. 1페이지 노출'));
    final target = tester.getRect(find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage &&
          (w.image as AssetImage).assetName == GoalTitleDisplay.iconAsset,
    ));
    final stepBox = tester.getRect(find.byType(TopBarTicker));
    final stepText = tester.getRect(find.textContaining('STEP >').first);
    final flag = tester.getRect(find.byType(FinishFlagIcon));

    final goalTextMid = inkMid(goalBox, goalText.left, goalBox.right, bright);
    final goalIconMid = inkMid(goalBox, target.left, target.right, bright);
    final label = tester.getRect(find.text(GoalTitleDisplay.label));
    final labelMid = inkMid(goalBox, label.left, label.right, bright);
    final stepTextMid = inkMid(stepBox, stepText.left, stepBox.right - 90, bright);
    final flagsMid = inkMid(stepBox, flag.left, flag.right, white);

    final report = [
      'dpr $dpr textScale $scale',
      'goal textMid ${goalTextMid.toStringAsFixed(1)} iconMid ${goalIconMid.toStringAsFixed(1)} diff ${(goalIconMid - goalTextMid).toStringAsFixed(1)}',
      'goal labelMid ${labelMid.toStringAsFixed(1)} diff ${(labelMid - goalTextMid).toStringAsFixed(1)}',
      'step textMid ${stepTextMid.toStringAsFixed(1)} flagsMid ${flagsMid.toStringAsFixed(1)} diff ${(flagsMid - stepTextMid).toStringAsFixed(1)}',
    ].join('\n');
    // ignore: avoid_print
    print('CENTER_REPORT\n$report');
    File('build/top_bar_center_report.txt').writeAsStringSync(report);
    final png = (await img.toByteData(format: ui.ImageByteFormat.png))!;
    File('build/top_bar_center.png').writeAsBytesSync(png.buffer.asUint8List());

    expect((goalIconMid - goalTextMid).abs(), lessThan(2.0), reason: report);
    expect((flagsMid - stepTextMid).abs(), lessThan(2.0), reason: report);
    // 2026-11-26: "목표>" 글자 가운데 = 목표 글 가운데
    expect((labelMid - goalTextMid).abs(), lessThan(2.0), reason: report);
  });
}

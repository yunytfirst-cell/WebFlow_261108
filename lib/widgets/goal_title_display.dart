import 'package:flutter/material.dart';
import 'top_bar_ticker.dart';
import '../models/design_theme.dart';

/// 목표 제목 직접 입력 및 편집 전용 박스 위젯
class GoalTitleDisplay extends StatefulWidget {
  /// "목표:" 대신 보이는 과녁 아이콘 (assets/images/goal_target.png, 바깥 흰 바탕을 투명하게 만든 정사각형)
  static const String iconAsset = 'assets/images/goal_target.png';

  /// 아이콘 크기 ÷ 박스 높이 = FINISH 아이콘과 같음 (TopBarTicker.finishIconScale)
  /// 아이콘을 박스 가운데에서 아래로 내리는 양 ÷ 박스 높이 (목표 글자의 실제 세로 가운데에 맞춤)
  static const double iconDropRatio = 0.155;

  /// 과녁 아이콘 바로 뒤에 붙는 글자 (2026-11-26 사용자 지시 "목표 아이콘 다음에 목표 글자 추가")
  static const String label = '목표';

  static const double iconScale =
      0.95 * 1.5 * 2 / 3; // 2026-11-25 사용자 지시 "아이콘 지금의 2/3" → 0.95

  final String title;
  final double fontSize;
  final AppThemeData theme;
  final double width;
  final ValueChanged<String>? onTitleChanged;

  /// 끝장 리스트에서 🎯로 항목을 보냈는지 (STEP 박스와 같은 조건). false면 아이콘만 오른쪽에.
  final bool active;

  const GoalTitleDisplay({
    super.key,
    required this.title,
    required this.fontSize,
    this.active = false,
    required this.theme,
    required this.width,
    this.onTitleChanged,
  });

  @override
  State<GoalTitleDisplay> createState() => _GoalTitleDisplayState();
}

class _GoalTitleDisplayState extends State<GoalTitleDisplay> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(GoalTitleDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title && _controller.text != widget.title) {
      _controller.text = widget.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = widget.fontSize * 1.5;
    final double targetWidth = widget.width;
    final double iconSize = viewportHeight * GoalTitleDisplay.iconScale;
    final double gap = widget.fontSize * 0.4;
    final bool active = widget.active;
    final labelStyle = TextStyle(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.bold,
      height: 1.0,
      color: widget.theme.textColor,
    );
    // 아이콘 + 간격 + "목표" + 간격 이 한 묶음으로 움직인다
    final labelPainter = TextPainter(
      text: TextSpan(text: GoalTitleDisplay.label, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final double labelWidth = labelPainter.width;
    labelPainter.dispose();
    final double headWidth = iconSize + gap + labelWidth + gap;
    final double textWidth = (targetWidth - headWidth).clamp(0.0, targetWidth);

    // 폭이 바뀔 때(창 크기·처음 측정)는 바로 맞추고, 🎯 상태가 바뀔 때만 서서히 움직이도록
    // 위치 대신 진행값 t(0=오른쪽, 1=왼쪽)를 애니메이션한다.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: active ? 1.0 : 0.0),
      duration: TopBarTicker.slideDuration,
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        // 보내기 전에도 아이콘과 "목표" 글자가 함께 오른쪽 끝에 보인다
        final double iconLeft = (targetWidth - iconSize - gap - labelWidth) *
            (1 - t);
        return SizedBox(
          width: targetWidth,
          child: Container(
            width: targetWidth,
            // 2026-11-24 사용자 지시: 아래 ITEM FINISH(티커) 바와 크기·위치·글자 크기를 같게 한다.
            // 티커와 같은 높이(글자 1.5배), 좌우 여백 없이 왼쪽부터 시작한다.
            height: viewportHeight,
            padding: EdgeInsets.zero,

            // 2026-11-25 사용자 지시: 목표 글도 끝장 리스트에서 🎯를 눌러야 보인다. 누르기 전에는 과녁 아이콘만
            // 박스 오른쪽에 있고, 누르면 목표 글과 함께 천천히 왼쪽으로 움직인다(아래 STEP 박스와 같은 방식).
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 목표 글 (박스 밖으로 나간 부분은 잘라서 보이지 않게)
                Positioned.fill(
                  // 좌우만 자른다(밀려 들어오는 글을 박스 밖에서 숨김). 위아래까지 자르면
                  // 맑은 고딕 굵은 글자의 아래가 잘려 보였다(2026-11-25 사용자 지적).
                  child: ClipRect(
                    clipper: const HorizontalOnlyClipper(),
                    child: Stack(
                      children: [
                        Positioned(
                          left: iconLeft + headWidth,
                          top: 0,
                          bottom: 0,
                          width: textWidth,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextField(
                              controller: _controller,
                              onChanged: (val) {
                                widget.onTitleChanged?.call(val);
                              },
                              textAlign: TextAlign.left,
                              // 2026-11-25 사용자 지시: 아이콘과 글자를 박스 높이 가운데에 맞춘다.
                              // 기본 줄 높이(맑은 고딕 약 1.33배)는 글자가 위로 치우쳐 STEP 글처럼 1.0으로 둔다.
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                                color: widget.theme.textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: "오늘의 스케줄 입력...",
                                hintStyle: TextStyle(
                                  fontSize: widget.fontSize,
                                  height: 1.0,
                                  color: widget.theme.textColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // "목표" 글자 (아이콘 바로 뒤, 목표 입력 글과 같은 글자·세로 정렬)
                Positioned(
                  left: iconLeft + iconSize + gap,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(GoalTitleDisplay.label, style: labelStyle),
                  ),
                ),
                // 과녁 아이콘 (FINISH 아이콘과 같은 크기, 박스 위아래로 넘침)
                Positioned(
                  left: iconLeft,
                  // 2026-11-25 사용자 지시 "그냥 아이콘 위치만 변경": 실제 윈도우 앱에서 목표 글자는 박스 가운데보다
                  // 박스 높이의 약 15% 아래에 그려진다(글자 크기 100~160% 모두, integration_test로 측정).
                  // 글자는 그대로 두고 아이콘을 그만큼 내려 글자 가운데에 맞춘다.
                  top: (viewportHeight - iconSize) / 2 +
                      viewportHeight * GoalTitleDisplay.iconDropRatio,
                  width: iconSize,
                  height: iconSize,
                  child: Tooltip(
                    message: '목표',
                    child: Image.asset(
                      GoalTitleDisplay.iconAsset,
                      width: iconSize,
                      height: iconSize,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 좌우만 자르고 위아래는 넉넉히 두는 클리퍼 (글자 아래가 잘리지 않게)
class HorizontalOnlyClipper extends CustomClipper<Rect> {
  const HorizontalOnlyClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -size.height, size.width, size.height * 2);

  @override
  bool shouldReclip(HorizontalOnlyClipper oldClipper) => false;
}

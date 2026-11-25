import 'package:flutter/material.dart';
import '../models/design_theme.dart';

/// 목표 제목 직접 입력 및 편집 전용 박스 위젯
class GoalTitleDisplay extends StatefulWidget {
  /// "목표:" 대신 보이는 과녁 아이콘 (assets/images/goal_target.png, 바깥 흰 바탕을 투명하게 만든 정사각형)
  static const String iconAsset = 'assets/images/goal_target.png';

  /// 아이콘 크기 ÷ 박스 높이 = FINISH 아이콘과 같음 (TopBarTicker.finishIconScale)
  static const double iconScale = 0.95 * 1.5;

  final String title;
  final double fontSize;
  final AppThemeData theme;
  final double width;
  final ValueChanged<String>? onTitleChanged;

  const GoalTitleDisplay({
    super.key,
    required this.title,
    required this.fontSize,
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
    // print("widget.width: ${widget.width}");

    return SizedBox(
      width: targetWidth,
      child: Container(
        width: targetWidth,
        // 2026-11-24 사용자 지시: 아래 ITEM FINISH(티커) 바와 크기·위치·글자 크기를 같게 한다.
        // 티커와 같은 높이(글자 1.5배), 좌우 여백 없이 왼쪽부터 시작한다.
        height: viewportHeight,
        padding: EdgeInsets.zero,

        // decoration: BoxDecoration(
        //   color: widget.theme.backgroundColor.withValues(alpha: 0.25),
        //   borderRadius: BorderRadius.circular(10),
        //   border: Border.all(
        //     color: widget.theme.accentColor.withValues(alpha: 0.35),
        //     width: 1.2,
        //   ),
        // ),
        // alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // 2026-11-25 사용자 지시: "목표:" 글자 대신 첨부 이미지(과녁 + 1) 아이콘.
            // 아래 STEP 박스의 FINISH 아이콘과 같은 크기(박스 높이 × 0.95 × 1.5)로, 박스 위치·높이는 그대로 두고
            // 아이콘만 위아래로 넘치게 그린다.
            Tooltip(
              message: '목표',
              child: SizedBox(
                width: viewportHeight * GoalTitleDisplay.iconScale,
                height: viewportHeight,
                child: OverflowBox(
                  maxWidth: viewportHeight * GoalTitleDisplay.iconScale,
                  maxHeight: viewportHeight * GoalTitleDisplay.iconScale,
                  child: Image.asset(
                    GoalTitleDisplay.iconAsset,
                    width: viewportHeight * GoalTitleDisplay.iconScale,
                    height: viewportHeight * GoalTitleDisplay.iconScale,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            SizedBox(width: widget.fontSize * 0.4),
            Flexible(
              child: TextField(
                controller: _controller,
                onChanged: (val) {
                  widget.onTitleChanged?.call(val);
                },
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
                decoration: InputDecoration(
                  hintText: "오늘의 스케줄 입력...",
                  hintStyle: TextStyle(
                    fontSize: widget.fontSize,
                    color: widget.theme.textColor.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

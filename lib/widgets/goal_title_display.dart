import 'package:flutter/material.dart';
import '../models/design_theme.dart';

/// 목표 제목 직접 입력 및 편집 전용 박스 위젯
class GoalTitleDisplay extends StatefulWidget {
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
        height: widget.fontSize * 1.8,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "목표: ",
              style: TextStyle(
                fontSize: widget.fontSize * 0.9,
                fontWeight: FontWeight.bold,
                color: widget.theme.accentColor,
              ),
            ),
            Flexible(
              child: TextField(
                controller: _controller,
                onChanged: (val) {
                  widget.onTitleChanged?.call(val);
                },
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: widget.fontSize * 0.9,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
                decoration: InputDecoration(
                  hintText: "오늘의 스케줄 입력...",
                  hintStyle: TextStyle(
                    fontSize: widget.fontSize * 0.85,
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

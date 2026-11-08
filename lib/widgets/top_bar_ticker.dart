import 'package:flutter/material.dart';
import 'dart:async';
import '../models/design_theme.dart';

class TopBarTicker extends StatefulWidget {
  final List<Map<String, dynamic>> lines;
  final int currIndex;
  final ScrollController scrollController;
  final double rowHeight;
  final double columnWidth;
  final double fontSize;
  final AppThemeData theme;
  final bool showInitialMessage;
  final VoidCallback onResetIndex;
  final Function(int) onUpdateIndex;
  final double? maxWidth;

  const TopBarTicker({
    super.key,
    required this.lines,
    required this.currIndex,
    required this.scrollController,
    required this.rowHeight,
    required this.columnWidth,
    required this.fontSize,
    required this.theme,
    required this.showInitialMessage,
    required this.onResetIndex,
    required this.onUpdateIndex,
    this.maxWidth,
  });

  @override
  State<TopBarTicker> createState() => _TopBarTickerState();
}

class _TopBarTickerState extends State<TopBarTicker> {
  @override
  Widget build(BuildContext context) {
    // 글자 크기의 1.5배로 고정 높이 지정 (글자 아래 잘림 방지)
    final double viewportHeight = widget.fontSize * 1.5;
    final double tickerWidth = widget.maxWidth != null
        ? (widget.maxWidth! - 120).clamp(180.0, 700.0).floorToDouble()
        : widget.columnWidth;

    const double controlButtonsWidth = 85.0; // 우측 조작 버튼 영역 폭

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. 텍스트 표시 영역 (우측 버튼 영역 침범 방지 + 마퀴 스크롤)
        Container(
          height: viewportHeight,
          width: tickerWidth,
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            right: (!widget.showInitialMessage) ? controlButtonsWidth : 0,
          ),
          child: ClipRect(
            child: widget.showInitialMessage
                ? _TickerMarqueeText(
                    text: "ITEM FINISH",
                    fontSize: widget.fontSize,
                    key: const ValueKey("initial_msg"),
                    color: widget.theme.accentColor,
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: widget.lines.length,
                    itemExtent: viewportHeight,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final line = widget.lines[index];
                      bool isSelected = index == widget.currIndex;
                      String leadingNum = line['subIdx'] == null
                          ? "STEP > ${line['mainIdx']}."
                          : "STEP > ${line['mainIdx']}-${line['subIdx']}.";
                      String fullText = "$leadingNum ${line['text']}";

                      return Container(
                        height: viewportHeight,
                        alignment: Alignment.centerLeft,
                        child: isSelected
                            ? _TickerMarqueeText(
                                text: fullText,
                                fontSize: widget.fontSize,
                                key: ValueKey("${line['mainIdx']}-${line['subIdx']}"),
                                color: widget.theme.accentColor,
                              )
                            : Text(
                                fullText,
                                style: TextStyle(
                                  fontSize: widget.fontSize,
                                  height: 1.0,
                                  color: widget.theme.textColor.withValues(alpha: 0.45),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                              ),
                      );
                    },
                  ),
          ),
        ),

        // 2. 상하 이동 및 닫기 제어 영역 (우측 고정 배치, 텍스트 덮어쓰기 방지)
        if (!widget.showInitialMessage)
          Positioned(
            right: 0,
            child: SizedBox(
              width: controlButtonsWidth,
              height: viewportHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (widget.currIndex > 0) widget.onUpdateIndex(widget.currIndex - 1);
                      },
                      child: Icon(Icons.arrow_upward,
                          color: widget.theme.textColor,
                          size: widget.fontSize),
                    ),
                    SizedBox(width: widget.fontSize * 0.2),
                    InkWell(
                      onTap: () {
                        if (widget.currIndex < widget.lines.length - 1) {
                          widget.onUpdateIndex(widget.currIndex + 1);
                        }
                      },
                      child: Icon(Icons.arrow_downward,
                          color: widget.theme.textColor,
                          size: widget.fontSize),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: widget.theme.textColor,
                          size: widget.fontSize * 1.1),
                      onPressed: widget.onResetIndex,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TickerMarqueeText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;
  const _TickerMarqueeText({
    super.key,
    required this.text,
    required this.fontSize,
    this.color = Colors.greenAccent,
  });
  @override
  State<_TickerMarqueeText> createState() => _TickerMarqueeTextState();
}

class _TickerMarqueeTextState extends State<_TickerMarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _timer = Timer(const Duration(seconds: 1), _startScrolling);
  }

  void _startScrolling() async {
    if (!mounted || !_scrollController.hasClients) return;
    double maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    while (mounted) {
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 10).toInt()),
        curve: Curves.linear,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      _scrollController.jumpTo(0);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Container(
        height: widget.fontSize * 1.5, // 고정 글자 크기의 1.5배 높이로 설정하여 글자 아래 잘림 방지
        alignment: Alignment.centerLeft,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.fontSize,
            height: 1.0,
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

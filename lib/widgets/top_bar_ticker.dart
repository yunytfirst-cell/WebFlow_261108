import 'package:flutter/material.dart';

import 'finish_flag_icon.dart';
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

  /// STEP > 박스 글자 크기 = 목표 박스 글자(fontSize)의 2/3 (2026-11-25 사용자 지시)
  static const double textScale = 2 / 3;

  /// 완료(깃발) 아이콘 높이 ÷ 박스 높이 (처음 0.95 → 2026-11-25 사용자 지시로 1.5배)
  static const double finishIconScale = 0.95 * 1.5 * 2 / 3; // 2026-11-25 사용자 지시 "아이콘 지금의 2/3" → 0.95

  /// 🎯를 누르면 아이콘이 오른쪽 → 왼쪽으로 움직이는 시간 ("서서히")
  static const Duration slideDuration = Duration(milliseconds: 900);

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
    // 2026-11-25 사용자 지시: STEP > 박스 안 글자는 위 목표 박스 글자의 2/3 크기.
    // 박스 높이(viewportHeight)는 fontSize 기준 그대로 두어 박스 위치·크기는 바뀌지 않는다.
    final double textSize = widget.fontSize * TopBarTicker.textScale;
    final double tickerWidth = widget.maxWidth != null
        ? (widget.maxWidth! - 120).clamp(180.0, 700.0).floorToDouble()
        : widget.columnWidth;

    const double controlButtonsWidth = 85.0; // 우측 조작 버튼 영역 폭

    // 2026-11-25 사용자 지시: 끝장 리스트에서 🎯(메인 화면으로 보내기)를 누르기 전에는 FINISH 아이콘이 박스 오른쪽에 있고,
    // 누르면 STEP 글과 함께 천천히 왼쪽으로 움직인다(글은 아이콘 바로 오른쪽에 붙어 따라온다).
    final bool active = !widget.showInitialMessage;
    final double iconH = viewportHeight * TopBarTicker.finishIconScale;
    final double iconW = FinishFlagIcon.widthFor(iconH);
    final double gap = widget.fontSize * 0.4;
    final double textWidth =
        (tickerWidth - iconW - gap - controlButtonsWidth).clamp(0.0, tickerWidth);

    // 폭이 바뀔 때(창 크기·처음 측정)는 바로 맞추고, 🎯 상태가 바뀔 때만 서서히 움직이도록
    // 위치 대신 진행값 t(0=오른쪽, 1=왼쪽)를 애니메이션한다.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: active ? 1.0 : 0.0),
      duration: TopBarTicker.slideDuration,
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
    final double iconLeft = (tickerWidth - iconW) * (1 - t);
    return SizedBox(
      width: tickerWidth,
      height: viewportHeight,
      child: Stack(
      // 아이콘은 박스보다 커서 위로 넘쳐 보이게 둔다
      clipBehavior: Clip.none,
      children: [
        // 1. STEP 글 (박스 밖으로 나간 부분은 잘라서 보이지 않게)
        Positioned.fill(
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: iconLeft + iconW + gap,
                  top: 0,
                  bottom: 0,
                  width: textWidth,
                  child: ListView.builder(
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
                                fontSize: textSize,
                                key: ValueKey("${line['mainIdx']}-${line['subIdx']}"),
                                color: widget.theme.accentColor,
                              )
                            : Text(
                                fullText,
                                style: TextStyle(
                                  fontSize: textSize,
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
              ],
            ),
          ),
        ),

        // FINISH 아이콘 (첨부 이미지: 엇갈린 체크 깃발 + FINISH, 박스 높이 × 0.95).
        // 2026-11-25 사용자 지시: 아이콘과 글자는 박스 높이 가운데에 맞춘다.
        Positioned(
          left: iconLeft,
          top: (viewportHeight - iconH) / 2,
          width: iconW,
          height: iconH,
          child: FinishFlagIcon(
            key: const ValueKey("initial_msg"),
            height: iconH,
            poleColor: widget.theme.textColor,
            textColor: widget.theme.accentColor,
          ),
        ),

        // 2. 상하 이동 및 닫기 제어 영역 (우측 고정 배치, 텍스트 덮어쓰기 방지)
        if (!widget.showInitialMessage)
          Positioned(
            right: 0,
            top: 0,
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
      ),
    );
      },
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

import 'package:flutter/material.dart';
import 'flip_clock.dart';
import '../services/focus_service.dart';
import '../models/design_theme.dart';

class InfoBar extends StatefulWidget {
  final int counter;
  final double metaPoint; 
  final double focusPercentage;
  final VoidCallback onReset;
  final AppThemeData theme;

  const InfoBar({
    super.key,
    required this.counter,
    this.metaPoint = 60.0,
    this.focusPercentage = 0.0,
    required this.onReset,
    required this.theme,
  });

  @override
  State<InfoBar> createState() => _InfoBarState();
}

class _InfoBarState extends State<InfoBar> {
  bool _isMetaMode = true; // 현재 모드 상태 (META or FOCUS)

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenH = MediaQuery.of(context).size.height;
        double screenW = MediaQuery.of(context).size.width;

        // 화면 크기에 맞춘 컴팩트 반응형 높이 및 너비 계산 (오버플로우 방지)
        double targetHeight = (screenH * 0.12).clamp(55.0, 95.0);
        double targetWidth = (screenW * 0.9).clamp(280.0, 680.0);

        return Center(
          child: Container(
            width: targetWidth,
            height: targetHeight,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. 토글형 정보 영역 (좌측)
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => setState(() => _isMetaMode = !_isMetaMode),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _isMetaMode 
                          ? _buildMetaInfo(targetHeight) 
                          : _buildFocusInfo(targetHeight),
                      ),
                    ),
                  ),
                ),

                // 2. 중앙 3자리 플립 카운터
                Expanded(
                  flex: 5,
                  child: LayoutBuilder(
                    builder: (context, clockConstraints) {
                      double availableW = (clockConstraints.maxWidth - 20).clamp(50.0, 400.0);
                      double boxWidth = availableW / 3;
                      double boxHeight = (clockConstraints.maxHeight * 0.85).clamp(35.0, 85.0);
                      return Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: FlipClock(
                            value: widget.counter,
                            width: boxWidth,
                            height: boxHeight,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. 우측 리셋 버튼
                Expanded(
                  flex: 2,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: IconButton(
                        icon: const Icon(Icons.refresh, size: 30, color: Colors.redAccent),
                        onPressed: widget.onReset,
                        tooltip: "카운터 초기화",
                      ),
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

  /// META 모드 UI 구성
  Widget _buildMetaInfo(double height) {
    double titleSize = (height * 0.28).clamp(11.0, 18.0);
    double valueSize = (height * 0.32).clamp(13.0, 22.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "META",
          softWrap: false,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            color: widget.theme.primaryColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.metaPoint.toStringAsFixed(1),
          softWrap: false,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
            fontFamily: 'noto_sans',
          ),
        ),
      ],
    );
  }

  /// FOCUS 모드 UI 구성
  Widget _buildFocusInfo(double height) {
    final info = FocusService.getLevelInfo(widget.focusPercentage);
    double titleSize = (height * 0.25).clamp(10.0, 16.0);
    double valueSize = (height * 0.30).clamp(12.0, 20.0);

    return Tooltip(
      message: info.description,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "FOCUS",
            softWrap: false,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              color: widget.theme.accentColor.withValues(alpha: 0.7),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Lv.${info.level}",
            softWrap: false,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
              color: widget.theme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/item_text_style.dart';

/// 끝장·알아차림 리스트 상단 오른쪽의 글자 서식 툴박스 (2026-11-25 사용자 지시, 첨부 이미지 2개 참조).
/// 위: 색 칸 줄(노랑·초록·분홍·보라·하늘·회색·진회색=기본 흰색, 고른 칸에 ✓)
/// 아래: 어두운 둥근 판에 B · I · U · ab(가운데 줄) · 글자 크기(메뉴).
/// [style]이 null이면(서식을 바꿀 항목을 아직 누르지 않음) 흐리게 보이고 눌리지 않는다.
class TextFormatToolbox extends StatelessWidget {
  const TextFormatToolbox({
    super.key,
    required this.style,
    required this.onChanged,
    this.scale = 1.0,
  });

  final ItemTextStyle? style;
  final ValueChanged<ItemTextStyle> onChanged;
  final double scale;

  static const _defaultSwatch = Color(0xFF444444);

  @override
  Widget build(BuildContext context) {
    final enabled = style != null;
    final current = style ?? ItemTextStyle.plain;
    final double cell = 22 * scale;
    final double icon = 18 * scale;

    Widget swatch(int? rgb) {
      final selected = enabled && current.color == rgb;
      final fill = rgb == null ? _defaultSwatch : Color(0xFF000000 | rgb);
      return Tooltip(
        message: rgb == null ? '기본 색(흰색)' : '글자 색',
        child: InkWell(
          onTap: enabled
              ? () => onChanged(current.copyWith(color: () => rgb))
              : null,
          child: Container(
            width: cell,
            height: cell,
            color: fill,
            alignment: Alignment.center,
            child: selected
                ? Icon(Icons.check, size: cell * 0.7, color: Colors.black87)
                : null,
          ),
        ),
      );
    }

    Widget toggle(String tooltip, Widget child, bool on, ItemTextStyle next) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: enabled ? () => onChanged(next) : null,
          child: Container(
            width: 26 * scale,
            height: 24 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: child,
          ),
        ),
      );
    }

    final textColor = Colors.white70;
    final letter = TextStyle(
      fontSize: 15 * scale,
      color: textColor,
      height: 1.0,
    );

    final box = Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final rgb in ItemTextStyle.palette) swatch(rgb),
              swatch(null),
            ],
          ),
          SizedBox(height: 4 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 4 * scale,
              vertical: 2 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                toggle(
                  '굵게',
                  Text(
                    'B',
                    style: letter.copyWith(fontWeight: FontWeight.w900),
                  ),
                  current.bold,
                  current.copyWith(bold: !current.bold),
                ),
                toggle(
                  '기울임',
                  Icon(Icons.format_italic, size: icon, color: textColor),
                  current.italic,
                  current.copyWith(italic: !current.italic),
                ),
                toggle(
                  '밑줄',
                  Icon(Icons.format_underlined, size: icon, color: textColor),
                  current.underline,
                  current.copyWith(underline: !current.underline),
                ),
                toggle(
                  '가운데 줄',
                  Icon(
                    Icons.format_strikethrough,
                    size: icon,
                    color: textColor,
                  ),
                  current.strike,
                  current.copyWith(strike: !current.strike),
                ),
                PopupMenuButton<double>(
                  tooltip: '글자 크기',
                  enabled: enabled,
                  padding: EdgeInsets.zero,
                  color: const Color(0xFF2B2B2B),
                  onSelected: (v) => onChanged(current.copyWith(sizeScale: v)),
                  itemBuilder: (context) => [
                    for (var i = 0; i < ItemTextStyle.sizeSteps.length; i++)
                      CheckedPopupMenuItem<double>(
                        value: ItemTextStyle.sizeSteps[i],
                        checked:
                            current.sizeScale == ItemTextStyle.sizeSteps[i],
                        child: Text(
                          ItemTextStyle.sizeLabels[i],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                  child: Container(
                    width: 26 * scale,
                    height: 24 * scale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current.sizeScale != 1.0
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.format_size,
                      size: icon,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (enabled) return box;
    return Tooltip(message: '서식을 바꿀 항목을 먼저 누르세요', child: box);
  }
}

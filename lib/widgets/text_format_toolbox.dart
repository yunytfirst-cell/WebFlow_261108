import 'package:flutter/material.dart';

import '../services/item_text_style.dart';

/// 끝장·알아차림 리스트 상단 오른쪽의 글자 서식 툴박스 (2026-11-25 사용자 지시, 첨부 이미지 2개 참조).
/// 위: 색 칸 줄(노랑·초록·분홍·보라·하늘·회색·진회색=기본 흰색, 고른 칸에 ✓)
/// 아래: 어두운 둥근 판에 B · I · U · ab(가운데 줄) · 글자 크기(메뉴).
/// [style]이 null이면(서식을 바꿀 항목을 아직 누르지 않음) 흐리게 보이고 눌리지 않는다.
/// 2026-11-25 사용자 지시 "컬러 리스트, 글자 편집 리스트 아이콘 버튼을 만들어서 숨겨라":
/// 평소에는 아이콘 버튼 2개(🎨 글자 색 목록, T 글자 편집 목록)만 보이고, 누르면 그 목록이 아래에 펼쳐진다.
/// 다시 누르면 숨는다. 두 목록은 따로 열고 닫는다(처음엔 둘 다 숨김).
class TextFormatToolbox extends StatefulWidget {
  const TextFormatToolbox({
    super.key,
    required this.style,
    required this.onChanged,
    this.scale = 1.0,
  });

  final ItemTextStyle? style;
  final ValueChanged<ItemTextStyle> onChanged;
  final double scale;

  @override
  State<TextFormatToolbox> createState() => _TextFormatToolboxState();
}

class _TextFormatToolboxState extends State<TextFormatToolbox> {
  static const _defaultSwatch = Color(0xFF444444);

  bool _showColors = false;
  bool _showFormat = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final onChanged = widget.onChanged;
    final scale = widget.scale;
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

    // 목록을 열고 닫는 아이콘 버튼 (항목을 고르지 않아도 열고 닫을 수 있다)
    Widget opener({
      required IconData iconData,
      required String name,
      required bool open,
      required VoidCallback onTap,
      Color? tint,
    }) {
      return Tooltip(
        message: open ? '$name 닫기' : '$name 열기',
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: 30 * scale,
            height: 26 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: open
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: open ? Colors.white38 : Colors.white12),
            ),
            child: Icon(iconData, size: icon, color: tint ?? textColor),
          ),
        ),
      );
    }

    Widget disabledHint(Widget panel) {
      final dimmed = Opacity(opacity: enabled ? 1.0 : 0.45, child: panel);
      if (enabled) return dimmed;
      return Tooltip(message: '서식을 바꿀 항목을 먼저 누르세요', child: dimmed);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            opener(
              iconData: Icons.palette_outlined,
              name: '글자 색 목록',
              open: _showColors,
              // 고른 항목의 지금 색을 아이콘에 보여준다
              tint: enabled && current.color != null
                  ? Color(0xFF000000 | current.color!)
                  : null,
              onTap: () => setState(() => _showColors = !_showColors),
            ),
            SizedBox(width: 6 * scale),
            opener(
              iconData: Icons.text_format,
              name: '글자 편집 목록',
              open: _showFormat,
              onTap: () => setState(() => _showFormat = !_showFormat),
            ),
          ],
        ),
        if (_showColors) ...[
          SizedBox(height: 4 * scale),
          disabledHint(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final rgb in ItemTextStyle.palette) swatch(rgb),
                swatch(null),
              ],
            ),
          ),
        ],
        if (_showFormat) ...[
          SizedBox(height: 4 * scale),
          disabledHint(
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
                    onSelected: (v) =>
                        onChanged(current.copyWith(sizeScale: v)),
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
          ),
        ],
      ],
    );
  }
}

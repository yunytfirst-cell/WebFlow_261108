import 'package:flutter/material.dart';

import '../services/item_text_style.dart';

/// 글자마다 서식을 기억하는 입력칸 컨트롤러 (2026-11-25 사용자 지시
/// "리스트 박스 안 글자 전체가 아니라, 선택된 글자만 글자 색·글자 편집 기능 적용").
/// - [charStyles]는 항상 글 길이와 같다. 글을 고치면 바뀐 부분만 늘리고 줄인다
///   (새로 친 글자는 바로 앞 글자의 서식을 이어받는다).
/// - 서식 툴박스를 누르면 입력칸 포커스가 빠지며 선택이 풀릴 수 있어서,
///   마지막으로 드래그해 고른 구간을 [lastRange]로 기억해 두고 그 구간에 적용한다.
class StyledTextController extends TextEditingController {
  StyledTextController({super.text}) {
    _chars = List.filled(text.length, ItemTextStyle.plain, growable: true);
  }

  late List<ItemTextStyle> _chars;
  TextRange? _lastRange;

  List<ItemTextStyle> get charStyles => List.unmodifiable(_chars);

  /// 파일에 저장할 서식 구간
  List<StyleSpan> get spans => spansFromCharStyles(_chars);

  /// 불러온 서식 구간을 입힌다 (글을 먼저 넣은 뒤 부른다)
  set spans(List<StyleSpan> value) {
    _chars = charStylesFromSpans(value, text.length).toList(growable: true);
    notifyListeners();
  }

  /// 서식을 적용할 구간: 지금 선택이 있으면 그것, 없으면 마지막으로 고른 구간
  TextRange? get lastRange {
    final sel = selection;
    if (sel.isValid && !sel.isCollapsed) {
      return TextRange(start: sel.start, end: sel.end);
    }
    return _lastRange;
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = value.text;
    final newText = newValue.text;
    if (oldText != newText) {
      _spliceStyles(oldText, newText);
      _lastRange = null;
    }
    final sel = newValue.selection;
    if (sel.isValid) {
      // 새로 드래그해 고르면 기억, 커서만 옮기면 잊는다.
      // 포커스가 빠질 때(선택이 -1로 바뀜)는 기억을 그대로 둔다.
      _lastRange = sel.isCollapsed
          ? null
          : TextRange(start: sel.start, end: sel.end);
    }
    super.value = newValue;
  }

  void _spliceStyles(String oldText, String newText) {
    if (_chars.length != oldText.length) {
      _chars = List.filled(oldText.length, ItemTextStyle.plain, growable: true);
    }
    var prefix = 0;
    final maxPrefix = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (prefix < maxPrefix &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    final removedEnd = oldText.length - suffix;
    final insertedCount = newText.length - suffix - prefix;
    // 바뀐 자리의 앞 글자 서식을 이어받는다 (맨 앞이면 지워진 첫 글자, 없으면 기본)
    final inherit = prefix > 0
        ? _chars[prefix - 1]
        : (removedEnd > prefix ? _chars[prefix] : ItemTextStyle.plain);
    _chars.replaceRange(
      prefix,
      removedEnd,
      List.filled(insertedCount, inherit),
    );
  }

  /// 구간의 첫 글자 서식 (툴박스에 지금 상태로 보여줌). 구간이 없으면 null.
  ItemTextStyle? styleAtRange() {
    final range = lastRange;
    if (range == null || range.start >= _chars.length) return null;
    return _chars[range.start];
  }

  /// 고른 구간의 글자들에만 서식 변경을 적용한다
  bool applyToRange(ItemTextStyle Function(ItemTextStyle) edit) {
    final range = lastRange;
    if (range == null) return false;
    final end = range.end.clamp(0, _chars.length);
    for (var k = range.start.clamp(0, end); k < end; k++) {
      _chars[k] = edit(_chars[k]);
    }
    notifyListeners();
    return true;
  }

  /// 서식을 입힌 글 (접힌 상태 표시, 한 줄 넘는지 계산에도 쓴다)
  TextSpan styledSpan(TextStyle base, {String? displayText}) {
    final shown = displayText ?? text;
    return TextSpan(style: base, children: _runs(shown, base, null));
  }

  List<InlineSpan> _runs(String shown, TextStyle base, TextRange? composing) {
    final children = <InlineSpan>[];
    // 서식이 바뀌는 곳과 한글 조합 중 구간 경계에서 나눈다
    final cuts = <int>{0, shown.length};
    for (var k = 1; k < shown.length && k < _chars.length; k++) {
      if (_chars[k] != _chars[k - 1]) cuts.add(k);
    }
    if (composing != null) {
      cuts.add(composing.start.clamp(0, shown.length));
      cuts.add(composing.end.clamp(0, shown.length));
    }
    final points = cuts.toList()..sort();
    for (var c = 0; c + 1 < points.length; c++) {
      final a = points[c], b = points[c + 1];
      if (a == b) continue;
      final charStyle = a < _chars.length ? _chars[a] : ItemTextStyle.plain;
      var style = charStyle.apply(base);
      if (composing != null && a >= composing.start && b <= composing.end) {
        style = style.merge(
          const TextStyle(decoration: TextDecoration.underline),
        );
      }
      children.add(TextSpan(text: shown.substring(a, b), style: style));
    }
    return children;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : null;
    return TextSpan(style: base, children: _runs(text, base, composing));
  }
}

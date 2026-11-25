import 'package:flutter/painting.dart';

/// 리스트 항목 글자 서식 한 벌 (2026-11-25 사용자 지시: 끝장·알아차림 리스트 서식 툴박스).
/// 2026-11-25 사용자 지시 "글자 전체가 아니라 선택한 글자만": 항목의 글자 구간마다 서식을 둔다([StyleSpan]).
/// 파일에는 항목 블록 머리 다음 줄에 `[SPAN] 0-5 color=E6B422;size=1.2;bold;italic;underline;strike`
/// (시작-끝 글자 위치, 끝은 포함 안 함)를 구간마다 한 줄씩 쓴다. 서식 없는 항목은 줄이 없어 예전 파일과 같다.
/// 예전 `[STYLE] …` 줄(항목 전체 서식, v1.4.0~1.4.1)도 읽어서 항목 전체 구간으로 바꾼다.
class ItemTextStyle {
  const ItemTextStyle({
    this.color,
    this.sizeScale = 1.0,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
  });

  static const marker = '[STYLE]';

  /// 글자 색 RGB (null = 기본 흰색)
  final int? color;

  /// 기본 글자 크기에 곱하는 배율
  final double sizeScale;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  static const plain = ItemTextStyle();

  /// 툴박스 색 칸 (첨부 이미지 순서: 노랑·초록·분홍·보라·하늘·회색). 마지막 칸(진회색)은 기본 흰색.
  static const palette = <int>[
    0xE6B422,
    0x5CB85C,
    0xE88AC4,
    0xA97FE0,
    0x5BC0EB,
    0x9E9E9E,
  ];

  /// 글자 크기 단계 (툴박스 크기 메뉴)
  static const sizeSteps = <double>[0.85, 1.0, 1.2, 1.5];
  static const sizeLabels = <String>['작게', '보통', '크게', '아주 크게'];

  /// 크기 단계를 [delta]칸 옮긴다 (툴박스 A−/A+). 목록에 없는 값이면 보통에서 시작한다.
  static double stepSize(double current, int delta) {
    var i = sizeSteps.indexOf(current);
    if (i < 0) i = sizeSteps.indexOf(1.0);
    return sizeSteps[(i + delta).clamp(0, sizeSteps.length - 1)];
  }

  bool get isPlain =>
      color == null &&
      sizeScale == 1.0 &&
      !bold &&
      !italic &&
      !underline &&
      !strike;

  ItemTextStyle copyWith({
    int? Function()? color,
    double? sizeScale,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
  }) => ItemTextStyle(
    color: color != null ? color() : this.color,
    sizeScale: sizeScale ?? this.sizeScale,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    strike: strike ?? this.strike,
  );

  /// 기본 글자 스타일(흰색·기본 크기)에 이 서식을 입힌다.
  TextStyle apply(TextStyle base) => base.copyWith(
    color: color == null ? base.color : Color(0xFF000000 | color!),
    fontSize: base.fontSize == null ? null : base.fontSize! * sizeScale,
    fontWeight: bold ? FontWeight.bold : base.fontWeight,
    fontStyle: italic ? FontStyle.italic : base.fontStyle,
    decoration: TextDecoration.combine([
      if (underline) TextDecoration.underline,
      if (strike) TextDecoration.lineThrough,
    ]),
    decorationColor: color == null ? base.color : Color(0xFF000000 | color!),
  );

  /// 파일에 쓰는 속성 부분 (`color=E6B422;bold` …)
  String toAttrs() {
    final parts = <String>[
      if (color != null)
        'color=${color!.toRadixString(16).padLeft(6, '0').toUpperCase()}',
      if (sizeScale != 1.0) 'size=$sizeScale',
      if (bold) 'bold',
      if (italic) 'italic',
      if (underline) 'underline',
      if (strike) 'strike',
    ];
    return parts.join(';');
  }

  String toLine() => '$marker ${toAttrs()}';

  /// `[STYLE] ...` 줄을 읽는다. 서식 줄이 아니면 null.
  static ItemTextStyle? parseLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith(marker)) return null;
    return parseAttrs(trimmed.substring(marker.length));
  }

  static ItemTextStyle parseAttrs(String attrs) {
    int? color;
    var size = 1.0;
    var bold = false, italic = false, underline = false, strike = false;
    for (final raw in attrs.split(';')) {
      final part = raw.trim();
      if (part.startsWith('color=')) {
        color = int.tryParse(part.substring(6), radix: 16);
      } else if (part.startsWith('size=')) {
        size = double.tryParse(part.substring(5)) ?? 1.0;
      } else if (part == 'bold') {
        bold = true;
      } else if (part == 'italic') {
        italic = true;
      } else if (part == 'underline') {
        underline = true;
      } else if (part == 'strike') {
        strike = true;
      }
    }
    return ItemTextStyle(
      color: color,
      sizeScale: size.clamp(0.5, 3.0),
      bold: bold,
      italic: italic,
      underline: underline,
      strike: strike,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ItemTextStyle &&
      other.color == color &&
      other.sizeScale == sizeScale &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.strike == strike;

  @override
  int get hashCode =>
      Object.hash(color, sizeScale, bold, italic, underline, strike);
}

/// 항목 글 안의 서식 구간 [start, end) (Dart 문자열 위치 기준)
class StyleSpan {
  const StyleSpan(this.start, this.end, this.style);

  static const marker = '[SPAN]';

  final int start;
  final int end;
  final ItemTextStyle style;

  String toLine() => '$marker $start-$end ${style.toAttrs()}';

  static final _pattern = RegExp(r'^\[SPAN\] (\d+)-(\d+)(?: (.*))?$');

  static StyleSpan? parseLine(String line) {
    final m = _pattern.firstMatch(line.trim());
    if (m == null) return null;
    return StyleSpan(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      ItemTextStyle.parseAttrs(m.group(3) ?? ''),
    );
  }

  StyleSpan shift(int delta) => StyleSpan(start + delta, end + delta, style);

  @override
  bool operator ==(Object other) =>
      other is StyleSpan &&
      other.start == start &&
      other.end == end &&
      other.style == style;

  @override
  int get hashCode => Object.hash(start, end, style);

  @override
  String toString() => toLine();
}

/// 글자별 서식 목록 → 같은 서식이 이어지는 구간들 (기본 서식 구간은 뺀다)
List<StyleSpan> spansFromCharStyles(List<ItemTextStyle> chars) {
  final spans = <StyleSpan>[];
  var i = 0;
  while (i < chars.length) {
    var j = i + 1;
    while (j < chars.length && chars[j] == chars[i]) {
      j++;
    }
    if (!chars[i].isPlain) spans.add(StyleSpan(i, j, chars[i]));
    i = j;
  }
  return spans;
}

/// 구간들 → 글자별 서식 목록 (글 길이 [length]에 맞춰 자른다)
List<ItemTextStyle> charStylesFromSpans(List<StyleSpan> spans, int length) {
  final chars = List<ItemTextStyle>.filled(length, ItemTextStyle.plain);
  for (final span in spans) {
    for (
      var k = span.start.clamp(0, length);
      k < span.end.clamp(0, length);
      k++
    ) {
      chars[k] = span.style;
    }
  }
  return chars;
}

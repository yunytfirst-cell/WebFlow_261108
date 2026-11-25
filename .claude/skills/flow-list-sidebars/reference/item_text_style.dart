import 'package:flutter/painting.dart';

/// 리스트 항목 하나의 글자 서식 (2026-11-25 사용자 지시: 끝장·알아차림 리스트 서식 툴박스).
/// 파일에는 항목 블록 머리 바로 다음 줄에 `[STYLE] color=E6B422;size=1.2;bold;italic;underline;strike`로 저장한다.
/// 기본 서식(흰색·보통 크기·꾸밈 없음)이면 줄을 쓰지 않아 예전 파일과 같다.
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

  String toLine() {
    final parts = <String>[
      if (color != null)
        'color=${color!.toRadixString(16).padLeft(6, '0').toUpperCase()}',
      if (sizeScale != 1.0) 'size=$sizeScale',
      if (bold) 'bold',
      if (italic) 'italic',
      if (underline) 'underline',
      if (strike) 'strike',
    ];
    return '$marker ${parts.join(';')}';
  }

  /// `[STYLE] ...` 줄을 읽는다. 서식 줄이 아니면 null.
  static ItemTextStyle? parseLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith(marker)) return null;
    int? color;
    var size = 1.0;
    var bold = false, italic = false, underline = false, strike = false;
    for (final raw in trimmed.substring(marker.length).split(';')) {
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

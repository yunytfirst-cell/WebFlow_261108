import 'package:flutter/material.dart';

class MemoNode {
  String id;
  Offset position;
  double width;
  double height;
  String text;

  MemoNode({
    required this.id,
    required this.position,
    this.width = 200.0,
    this.height = 120.0,
    this.text = "",
  });

  // [수정] 쉼표 대신 '|' 구분자 사용 및 줄바꿈 처리
  String toTxtRow() {
    // 저장 시 텍스트 내의 실제 줄바꿈을 특수문자( \n )로 치환하여 한 줄로 만듭니다.
    String escapedText = text.replaceAll('\n', '\\n');
    return '$id|$width|$height|${position.dx}|${position.dy}|$escapedText';
  }
}

class BoardData {
  String id;
  String title;
  List<MemoNode> nodes;
  String? filePath;

  BoardData({required this.id, required this.title, required this.nodes, this.filePath});
}
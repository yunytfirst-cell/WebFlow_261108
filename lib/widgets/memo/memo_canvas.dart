import 'package:flutter/material.dart';
import 'memo_node.dart';
import 'memo_node_widget.dart';

class MemoCanvas extends StatefulWidget {
  final List<MemoNode> nodes;
  final VoidCallback onNodesChanged;

  const MemoCanvas({
    super.key,
    required this.nodes,
    required this.onNodesChanged,
  });

  @override
  State<MemoCanvas> createState() => _MemoCanvasState();
}

class _MemoCanvasState extends State<MemoCanvas> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF252525), // 캔버스 배경색
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 연결선(CustomPaint/ArrowPainter) 부위가 완전히 삭제되었습니다.
              ...widget.nodes.map((node) => MemoNodeWidget(
                key: ValueKey(node.id),
                node: node,
                onPanUpdate: (details) => _handleMove(node, details, constraints),
                onResize: (direction, details) => _handleResize(node, direction, details, constraints),
                // 에러 원인이었던 onConnectStart 라인을 삭제했습니다.
                onChanged: (value) {
                  setState(() {}); // 텍스트 변경 시 UI 갱신
                  widget.onNodesChanged();
                },
                onDelete: (id) {
                  setState(() {
                    widget.nodes.removeWhere((n) => n.id == id);
                  });
                  widget.onNodesChanged();
                },
              )),
            ],
          );
        },
      ),
    );
  }

  // 메모장 이동 로직 (보드 내 제한 포함)
  void _handleMove(MemoNode node, DragUpdateDetails d, BoxConstraints c) {
    setState(() {
      node.position = Offset(
        (node.position.dx + d.delta.dx).clamp(0, c.maxWidth - node.width),
        (node.position.dy + d.delta.dy).clamp(0, c.maxHeight - node.height),
      );
    });
    widget.onNodesChanged();
  }

  // 메모장 크기 조절 로직 (보드 내 제한 포함)
  void _handleResize(MemoNode node, String dir, DragUpdateDetails d, BoxConstraints c) {
    setState(() {
      double newX = node.position.dx;
      double newY = node.position.dy;
      double newW = node.width;
      double newH = node.height;

      if (dir.contains('r')) newW = (newW + d.delta.dx).clamp(100, c.maxWidth - node.position.dx);
      if (dir.contains('b')) newH = (newH + d.delta.dy).clamp(50, c.maxHeight - node.position.dy);
      if (dir.contains('l')) {
        double delta = d.delta.dx.clamp(-node.position.dx, newW - 100);
        newX += delta;
        newW -= delta;
      }
      if (dir.contains('t')) {
        double delta = d.delta.dy.clamp(-node.position.dy, newH - 50);
        newY += delta;
        newH -= delta;
      }

      node.position = Offset(newX, newY);
      node.width = newW;
      node.height = newH;
    });
    widget.onNodesChanged();
  }
}
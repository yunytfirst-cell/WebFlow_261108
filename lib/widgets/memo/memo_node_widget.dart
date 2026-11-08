import 'package:flutter/material.dart';
import 'memo_node.dart';

class MemoNodeWidget extends StatefulWidget {
  final MemoNode node;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(String, DragUpdateDetails) onResize;
  final Function(String) onChanged;
  final Function(String) onDelete;

  const MemoNodeWidget({
    super.key,
    required this.node,
    required this.onPanUpdate,
    required this.onResize,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<MemoNodeWidget> createState() => _MemoNodeWidgetState();
}

class _MemoNodeWidgetState extends State<MemoNodeWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 한글 조합 유지를 위해 컨트롤러를 initState에서 1회만 생성
    _controller = TextEditingController(text: widget.node.text);
  }

  @override
  void didUpdateWidget(MemoNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부(불러오기 등)에서 텍스트가 변경된 경우만 컨트롤러 갱신
    if (oldWidget.node.text != widget.node.text && _controller.text != widget.node.text) {
      _controller.text = widget.node.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.node.position.dx,
      top: widget.node.position.dy,
      width: widget.node.width,
      height: widget.node.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 메모장 본체
          GestureDetector(
            onPanUpdate: widget.onPanUpdate,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 10), // 상단 여백 최소화
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top, // 좌측 상단 정렬
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          widget.node.text = value;
                          widget.onChanged(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 8방향 리사이즈 핸들
          _buildResizeHandle(Alignment.topLeft, "tl"),
          _buildResizeHandle(Alignment.topCenter, "tc"),
          _buildResizeHandle(Alignment.topRight, "tr"),
          _buildResizeHandle(Alignment.centerLeft, "cl"),
          _buildResizeHandle(Alignment.centerRight, "cr"),
          _buildResizeHandle(Alignment.bottomLeft, "bl"),
          _buildResizeHandle(Alignment.bottomCenter, "bc"),
          _buildResizeHandle(Alignment.bottomRight, "br"),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => widget.onDelete(widget.node.id),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.close, size: 14, color: Colors.white38),
          ),
        ),
      ],
    );
  }

  Widget _buildResizeHandle(Alignment align, String direction) {
    return Align(
      alignment: align,
      child: GestureDetector(
        onPanUpdate: (details) => widget.onResize(direction, details),
        child: Container(
          width: 15,
          height: 15,
          color: Colors.transparent,
        ),
      ),
    );
  }
}
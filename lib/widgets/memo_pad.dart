import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// 메모 데이터 모델
class MemoNode {
  String id;
  Offset position;
  String text;
  double width;
  double height;

  MemoNode({
    required this.id,
    required this.position,
    this.text = "",
    this.width = 250,
    this.height = 180,
  });

  String toTxtLine() {
    String escapedText = text.replaceAll('\n', '\\n');
    return '$id|${position.dx}|${position.dy}|$width|$height|$escapedText';
  }
}

class MemoPad extends StatefulWidget {
  const MemoPad({super.key});

  @override
  State<MemoPad> createState() => _MemoPadState();
}

class _MemoPadState extends State<MemoPad> {
  List<MemoNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<File> _getStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/memo_data.txt');
  }

  Future<void> _saveData() async {
    final file = await _getStorageFile();
    StringBuffer buffer = StringBuffer();
    for (var node in _nodes) {
      buffer.writeln(node.toTxtLine());
    }
    await file.writeAsString(buffer.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("데이터가 저장되었습니다."), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _loadData() async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final lines = await file.readAsLines();
        setState(() {
          _nodes = lines.map((line) {
            final p = line.split('|');
            if (p.length >= 6) {
              return MemoNode(
                id: p[0],
                position: Offset(double.parse(p[1]), double.parse(p[2])),
                width: double.parse(p[3]),
                height: double.parse(p[4]),
                text: p[5].replaceAll('\\n', '\n'),
              );
            }
            return MemoNode(id: p[0], position: const Offset(50, 50));
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 실패: $e");
    }
  }

  void _addNewMemo() {
    setState(() {
      _nodes.add(MemoNode(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        position: const Offset(100, 100),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width * 0.95,
          height: MediaQuery
              .of(context)
              .size
              .height * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _buildTopMenu(),
              Expanded(
                child: ClipRect(
                  child: Container(
                    color: const Color(0xFF222222),
                    child: Stack(
                      children: [
                        ..._nodes.map((node) =>
                            _MemoNodeWidget(
                              key: ValueKey(node.id),
                              node: node,
                              onDelete: () =>
                                  setState(() => _nodes.remove(node)),
                              onChanged: () => setState(() {}),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("DRAG & 8-WAY RESIZE MEMO", style: TextStyle(
              color: Colors.white70, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(onPressed: _addNewMemo,
                  icon: const Icon(Icons.add, color: Colors.greenAccent)),
              IconButton(onPressed: _saveData,
                  icon: const Icon(Icons.save, color: Colors.blueAccent)),
              IconButton(onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.redAccent)),
            ],
          )
        ],
      ),
    );
  }
}

class _MemoNodeWidget extends StatefulWidget {
  final MemoNode node;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _MemoNodeWidget(
      {super.key, required this.node, required this.onDelete, required this.onChanged});

  @override
  State<_MemoNodeWidget> createState() => _MemoNodeWidgetState();
}

class _MemoNodeWidgetState extends State<_MemoNodeWidget> {
  late TextEditingController _controller;

  // [인식 크기 설정] 테두리 인식 영역을 30px로 설정 (사용하기 가장 적당한 크기)
  final double hitArea = 30.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.node.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.node.position.dx - hitArea,
      top: widget.node.position.dy - hitArea,
      width: widget.node.width + (hitArea * 2),
      height: widget.node.height + (hitArea * 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 메모장 본체 (내부에 노란색 상단 드래그 바 포함)
          Positioned(
            left: hitArea,
            top: hitArea,
            width: widget.node.width,
            height: widget.node.height,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  // [수정] 상단 노란색 드래그 바 (이동 전용)
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        widget.node.position += details.delta;
                        widget.onChanged();
                      });
                    },
                    child: Container(
                      height: 28,
                      color: Colors.yellow,
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.drag_handle, size: 18,
                              color: Colors.black87)),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: widget.onDelete,
                              child: const Icon(Icons.cancel, size: 20,
                                  color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 텍스트 영역
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText: "메모를 입력하세요...",
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                      onChanged: (val) => widget.node.text = val,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 8방향 리사이즈 핸들 (본체 위에 겹쳐서 마우스 인식) ---

          // 상단 (↕)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeUpDown,
            top: hitArea - 15,
            left: hitArea + 20,
            width: widget.node.width - 40,
            height: 30,
            onResize: (dx, dy) {
              widget.node.position += Offset(0, dy);
              widget.node.height -= dy;
            },
          ),
          // 하단 (↕)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeUpDown,
            top: hitArea + widget.node.height - 15,
            left: hitArea + 20,
            width: widget.node.width - 40,
            height: 30,
            onResize: (dx, dy) => widget.node.height += dy,
          ),
          // 좌측 (↔)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeLeftRight,
            top: hitArea + 20,
            left: hitArea - 15,
            width: 30,
            height: widget.node.height - 40,
            onResize: (dx, dy) {
              widget.node.position += Offset(dx, 0);
              widget.node.width -= dx;
            },
          ),
          // 우측 (↔)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeLeftRight,
            top: hitArea + 20,
            left: hitArea + widget.node.width - 15,
            width: 30,
            height: widget.node.height - 40,
            onResize: (dx, dy) => widget.node.width += dx,
          ),
          // 좌측 상단 (⤡)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeUpLeft,
            top: hitArea - 15,
            left: hitArea - 15,
            width: 40,
            height: 40,
            onResize: (dx, dy) {
              widget.node.position += Offset(dx, dy);
              widget.node.width -= dx;
              widget.node.height -= dy;
            },
          ),
          // 우측 상단 (⤢)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeUpRight,
            top: hitArea - 15,
            left: hitArea + widget.node.width - 25,
            width: 40,
            height: 40,
            onResize: (dx, dy) {
              widget.node.position += Offset(0, dy);
              widget.node.width += dx;
              widget.node.height -= dy;
            },
          ),
          // 좌측 하단 (⤢)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeDownLeft,
            top: hitArea + widget.node.height - 25,
            left: hitArea - 15,
            width: 40,
            height: 40,
            onResize: (dx, dy) {
              widget.node.position += Offset(dx, 0);
              widget.node.width -= dx;
              widget.node.height += dy;
            },
          ),
          // 우측 하단 (⤡)
          _buildResizeHandle(
            cursor: SystemMouseCursors.resizeDownRight,
            top: hitArea + widget.node.height - 25,
            left: hitArea + widget.node.width - 25,
            width: 40,
            height: 40,
            onResize: (dx, dy) {
              widget.node.width += dx;
              widget.node.height += dy;
            },
          ),
        ],
      ),
    );
  }

  // 핸들 생성 헬퍼 함수
  Widget _buildResizeHandle({
    required MouseCursor cursor,
    required double top,
    required double left,
    required double width,
    required double height,
    required Function(double dx, double dy) onResize,
  }) {
    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            setState(() {
              onResize(details.delta.dx, details.delta.dy);
              // 최소 크기 제한
              if (widget.node.width < 150) widget.node.width = 150;
              if (widget.node.height < 100) widget.node.height = 100;
              widget.onChanged();
            });
          },
          child: Container(color: Colors.transparent), // 투명하지만 영역 차지
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'memo_node.dart';
import 'memo_canvas.dart';

class MemoBoard extends StatefulWidget {
  const MemoBoard({super.key});

  @override
  State<MemoBoard> createState() => _MemoBoardState();
}

class _MemoBoardState extends State<MemoBoard> {
  final List<BoardData> _boards = [];
  int _activeBoardIndex = 0;
  Offset _nextSpawnPos = const Offset(50, 50);

  @override
  void initState() {
    super.initState();
    _addNewBoard(); // 초기 빈 보드 생성
  }

  // --- [수정] TXT 파일로 저장 (수동 저장 전용) ---
  Future<void> _saveToTxt(BoardData board) async {
    if (board.filePath == null) {
      await _handleSaveAs();
      return;
    }

    try {
      final file = File(board.filePath!);
      StringBuffer content = StringBuffer();

      // 보드 제목 저장
      content.writeln("BOARD_TITLE|${board.title}");
      // 헤더 저장 (순서 고정: ID, 너비, 높이, X, Y, 텍스트)
      content.writeln("ID|WIDTH|HEIGHT|X|Y|TEXT");

      for (var node in board.nodes) {
        // 줄바꿈 보존을 위해 \n을 특수 기호로 치환
        String escapedText = node.text.replaceAll('\n', '\\n');
        content.writeln("${node.id}|${node.width}|${node.height}|${node.position.dx}|${node.position.dy}|$escapedText");
      }

      await file.writeAsString(content.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${board.title} 저장 완료!"), duration: const Duration(seconds: 1))
        );
      }
    } catch (e) {
      debugPrint("저장 실패: $e");
    }
  }

  // --- 다른 이름으로 저장 (최초 저장 시 호출됨) ---
  Future<void> _handleSaveAs() async {
    BoardData currentBoard = _boards[_activeBoardIndex];

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '보드 저장 위치 선택',
      fileName: '${currentBoard.title}.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (outputFile != null) {
      setState(() {
        currentBoard.filePath = outputFile;
      });
      await _saveToTxt(currentBoard);
    }
  }

  // --- [수정] TXT 파일 불러오기 ---
  Future<void> _loadFromTxt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final lines = await file.readAsLines();

      if (lines.isEmpty) return;

      String title = "불러온 보드";
      List<MemoNode> loadedNodes = [];

      for (var line in lines) {
        if (line.startsWith("BOARD_TITLE|")) {
          title = line.split('|')[1];
          continue;
        }

        List<String> p = line.split('|');
        // 헤더 제외, 정확히 6개 데이터가 있는 행만 파싱
        if (p.length == 6 && p[0] != "ID") {
          loadedNodes.add(MemoNode(
            id: p[0],
            width: double.parse(p[1]),
            height: double.parse(p[2]),
            position: Offset(double.parse(p[3]), double.parse(p[4])),
            text: p[5].replaceAll('\\n', '\n'), // 치환된 줄바꿈 복원
          ));
        }
      }

      setState(() {
        _boards.add(BoardData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          nodes: loadedNodes,
          filePath: file.path,
        ));
        _activeBoardIndex = _boards.length - 1;
      });
    }
  }

  void _addNewBoard() {
    setState(() {
      _boards.add(BoardData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "보드 ${_boards.length + 1}",
        nodes: [],
      ));
      _activeBoardIndex = _boards.length - 1;
      _nextSpawnPos = const Offset(50, 50);
    });
  }

  void _addNewMemo() {
    setState(() {
      _boards[_activeBoardIndex].nodes.add(MemoNode(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: _nextSpawnPos,
      ));
      _nextSpawnPos += const Offset(30, 30);
      if (_nextSpawnPos.dx > 400 || _nextSpawnPos.dy > 400) {
        _nextSpawnPos = const Offset(50, 50);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_boards.isEmpty) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: MemoCanvas(
                nodes: _boards[_activeBoardIndex].nodes,
                onNodesChanged: () {
                  setState(() {}); // UI만 갱신
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    // 수정된 코드: 화면이 줄어들어도 아이콘이 깨지지 않도록 최소 너비 제한(ConstrainedBox) 설정
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: SingleChildScrollView( // 화면이 좁아지면 가로 스크롤 허용
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 550), // 툴바가 깨지지 않는 최소 너비 강제
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("FLOW MULTI-CANVAS",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: _addNewMemo, icon: const Icon(Icons.add, color: Colors.yellowAccent), tooltip: "새 메모"),
                  IconButton(onPressed: _addNewBoard, icon: const Icon(Icons.add_to_photos, color: Colors.greenAccent), tooltip: "새 보드"),
                  IconButton(onPressed: _loadFromTxt, icon: const Icon(Icons.folder_open, color: Colors.orangeAccent), tooltip: "열기"),
                  IconButton(
                      onPressed: () => _saveToTxt(_boards[_activeBoardIndex]),
                      icon: const Icon(Icons.save, color: Colors.blueAccent),
                      tooltip: "저장"
                  ),
                  const SizedBox(width: 10),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.redAccent)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    // 수정된 코드: 높이를 고정하고 내부 요소가 넘치지 않도록 관리
    return Container(
      height: 40,
      width: double.infinity,
      color: Colors.black26, // 탭 바 영역 구분
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          bool isActive = _activeBoardIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _activeBoardIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? Colors.blueAccent.withValues(alpha: 0.8) : Colors.white10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // 텍스트 길이에 맞춤
                children: [
                  Icon(
                    _boards[index].filePath != null ? Icons.save : Icons.save_outlined,
                    size: 12, color: Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Text(_boards[index].title,
                      style: TextStyle(color: isActive ? Colors.white : Colors.white60, fontSize: 12)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_boards.length > 1) {
                        _boards.removeAt(index);
                        if (_activeBoardIndex >= _boards.length) _activeBoardIndex = _boards.length - 1;
                      }
                    }),
                    child: const Icon(Icons.close, size: 14, color: Colors.white38),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

  }
}
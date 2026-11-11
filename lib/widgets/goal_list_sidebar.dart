import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // [신규] 파일 선택을 위해 필요
import '../services/list_file_service.dart';
import 'run_counter_panel.dart';

/*
[신규 파일 설명]
1. (디자인) 배경 이미지와 일치하는 투명한 바탕에 수평 그라데이션 버블 아이템 배치.
2. (기능) '+' 버튼으로 항목 추가, '-' 버튼으로 해당 항목 삭제.
3. (연동) 항목의 '🎯' 버튼 클릭 시 메인 화면의 TopBar 하단 텍스트로 내용 전송.
*/

class GoalItem {
  String text;
  final Key id; // 각 항목의 고유 식별자
  final TextEditingController controller; // 텍스트 꼬임 방지

  GoalItem({this.text = ""})
    : id = UniqueKey(),
      controller = TextEditingController(text: text);
}

class GoalListSidebar extends StatefulWidget {
  final Function(String) onSelectGoal; // 선택된 목표를 TopBar로 보냄
  final Function(String) onDeleteGoal; // [신규] 삭제 콜백 추가
  final VoidCallback onClose; // [신규] 닫기 기능을 위한 콜백 추가

  final String initialTitle;
  final List<GoalItem> initialGoals;
  final Function(String) onTitleChanged;
  final Function(List<GoalItem>) onGoalsChanged;
  final String? initialFilePath;
  final Function(String?) onFilePathChanged;
  final Map<String, int> runRecords; // 실행 카운터 기록 (사이드바를 닫아도 유지되도록 main에서 보관)
  final VoidCallback onRunRecordsChanged;
  final VoidCallback? onBringToFront; // 패널 조작 시 다른 패널보다 위로 올림

  const GoalListSidebar({
    required this.runRecords,
    required this.onRunRecordsChanged,
    this.onBringToFront,
    super.key,
    required this.onSelectGoal,
    required this.onDeleteGoal, // [신규] 필수 인자 추가
    required this.onClose, // [신규] 필수 인자로 추가
    required this.initialTitle, // 추가
    required this.initialGoals, // 추가
    required this.onTitleChanged, // 추가
    required this.onGoalsChanged, // 추가
    required this.initialFilePath,
    required this.onFilePathChanged,
  });

  @override
  State<GoalListSidebar> createState() => _GoalListSidebarState();
}

class _GoalListSidebarState extends State<GoalListSidebar> {
  late TextEditingController _titleController;
  late List<GoalItem> _goals;
  int? _activeActionIndex;
  String? _currentFilePath;

  // [변경] 고정 픽셀 대신 화면 대비 비율로 관리하여 창 크기 조절 시 자동 대응
  double _widthRatio = 0.48;

  // 실행 카운터: 현재 열린 txt 파일의 날짜별 기록 ([RUN] 줄). 저장 버튼을 눌러야 파일에 기록된다.
  Map<String, int> get _runRecords => widget.runRecords;

  // 파일 저장 경로 가져오기
  Future<String> get _localPath async {
    return (await ListFileService.sharedDirectory()).path;
  }

  // [신규] 현재 화면의 모든 내용을 비우고 새로 시작하는 기능 (기존 데이터 삭제 아님)
  void _clearAll() {
    setState(() {
      _titleController.clear();
      // 기존 리스트의 컨트롤러들을 메모리에서 해제
      for (var goal in _goals) {
        goal.controller.dispose();
      }
      // 초기 상태(비어있는 항목 1개)로 리셋
      _goals = [GoalItem()];
      _activeActionIndex = null;
      _currentFilePath = null;
      _runRecords.clear();
    });
    widget.onRunRecordsChanged();
    widget.onFilePathChanged(null);
    // 부모 위젯(main.dart)의 상태도 동기화
    widget.onTitleChanged("");
    widget.onGoalsChanged(_goals);
    widget.onSelectGoal(""); // 메인 화면에 떠있는 리스트 제거
  }

  ({String fileName, List<String> invalidCharacters}) _safeFileName(
    String title,
  ) {
    final invalidCharacters = <String>[];
    var fileName = title.trim();
    fileName = fileName.replaceAllMapped(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), (
      match,
    ) {
      final character = match.group(0)!;
      invalidCharacters.add(_displayCharacter(character));
      return ' x';
    });

    if (RegExp(r'[. ]+$').hasMatch(fileName)) {
      invalidCharacters.add('파일명 끝의 점(.) 또는 공백');
      fileName = fileName.replaceFirst(RegExp(r'[. ]+$'), ' x');
    }

    if (fileName.toLowerCase().endsWith('.txt')) {
      fileName = fileName.substring(0, fileName.length - 4).trimRight();
    }

    final baseName = fileName.toLowerCase();
    const reservedNames = {
      'con',
      'prn',
      'aux',
      'nul',
      'com1',
      'com2',
      'com3',
      'com4',
      'com5',
      'com6',
      'com7',
      'com8',
      'com9',
      'lpt1',
      'lpt2',
      'lpt3',
      'lpt4',
      'lpt5',
      'lpt6',
      'lpt7',
      'lpt8',
      'lpt9',
    };
    if (fileName.isEmpty || reservedNames.contains(baseName)) {
      if (reservedNames.contains(baseName)) {
        invalidCharacters.add('Windows 예약 파일명 "$fileName"');
      }
      fileName = '미정_스케줄';
    }

    return (
      fileName: '${fileName.isEmpty ? '미정_스케줄' : fileName}.txt',
      invalidCharacters: invalidCharacters,
    );
  }

  String _displayCharacter(String character) {
    switch (character) {
      case '\n':
        return r'\n (줄바꿈)';
      case '\r':
        return r'\r (캐리지 리턴)';
      case '\t':
        return r'\t (탭)';
      default:
        return character;
    }
  }

  void _syncGoalTexts() {
    for (final goal in _goals) {
      goal.text = goal.controller.text;
    }
    widget.onGoalsChanged(_goals);
  }

  Future<void> _showSaveFailureDialog({
    required String path,
    required List<String> invalidCharacters,
    required Object error,
  }) async {
    if (!mounted) return;
    final characterText = invalidCharacters.isEmpty
        ? '파일명에 문제가 없는 경우 저장 폴더 권한 또는 파일 사용 여부를 확인해 주세요.'
        : invalidCharacters.toSet().join(', ');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장 실패'),
        content: SelectableText(
          '저장 위치:\n$path\n\n문제 문자:\n$characterText\n\n오류:\n$error',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveSuccessDialog({
    required String path,
    required String fileName,
    required List<String> invalidCharacters,
  }) async {
    if (!mounted) return;
    final conversionText = invalidCharacters.isEmpty
        ? '변환된 문자가 없습니다.'
        : invalidCharacters.toSet().join(', ');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장 완료'),
        content: SelectableText(
          '파일명:\n$fileName\n\n저장 위치:\n$path\n\n자동 변환된 문자:\n$conversionText',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openStorageFolder(path);
            },
            child: const Text('저장 폴더 열기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // [신규] 파일 저장 기능
  Future<void> _saveToFile() async {
    var savePath = '';
    var invalidCharacters = <String>[];
    try {
      _syncGoalTexts();
      final path = await _localPath;
      final result = _safeFileName(_titleController.text);
      final fileName = result.fileName;
      invalidCharacters = result.invalidCharacters;
      final targetPath = _currentFilePath ?? '$path/$fileName';
      final file = File(targetPath);
      savePath = file.path;
      final content = ListFileService.serialize(
        kind: ListFileKind.goal,
        title: _titleController.text,
        items: _goals.map((goal) => goal.controller.text).toList(),
        runRecords: _runRecords,
      );

      await file.writeAsString(content, flush: true);
      _currentFilePath = file.path;
      widget.onFilePathChanged(file.path);
      widget.onGoalsChanged(_goals);
      if (mounted) {
        await _showSaveSuccessDialog(
          path: file.path,
          fileName: file.path.split(RegExp(r'[/\\]')).last,
          invalidCharacters: invalidCharacters,
        );
      }
    } on FileSystemException catch (error) {
      debugPrint("끝장 리스트 저장 실패: $error");
      await _showSaveFailureDialog(
        path: savePath,
        invalidCharacters: invalidCharacters,
        error: error,
      );
    }
  }

  // 2. 불러오기 기능 (파일 선택 후 앱에 반영)
  Future<void> _loadFromFile() async {
    final path = await _localPath;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: path,
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    final selectedPath = result?.files.single.path;
    if (selectedPath != null) {
      final file = File(selectedPath);
      final data = ListFileService.parse(await file.readAsString());

      setState(() {
        _goals.clear();
        _runRecords.clear();
        _runRecords.addAll(data.runRecords);
        if (data.title != null) _titleController.text = data.title!;
        for (final goalText in data.items) {
          _goals.add(GoalItem(text: goalText)..controller.text = goalText);
        }

        if (_goals.isEmpty) _goals.add(GoalItem());
        _currentFilePath = file.path;
        widget.onFilePathChanged(file.path);
      });
      widget.onRunRecordsChanged();
      widget.onSelectGoal("");
    }
  }

  // 3. 폴더관리 기능 (윈도우 탐색기 열기)
  Future<void> _openStorageFolder([String? filePath]) async {
    final folderPath = filePath == null
        ? await _localPath
        : Directory(filePath).parent.path;
    await Process.run('explorer.exe', [folderPath.replaceAll('/', '\\')]);
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _goals = widget.initialGoals;
    _currentFilePath = widget.initialFilePath;

    _titleController.addListener(() {
      widget.onTitleChanged(_titleController.text);
    });
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _goals.removeAt(index);
        _goals.insert(index - 1, item);
        _activeActionIndex = index - 1;
      });
    }
  }

  void _moveDown(int index) {
    if (index < _goals.length - 1) {
      setState(() {
        final item = _goals.removeAt(index);
        _goals.insert(index + 1, item);
        _activeActionIndex = index + 1;
      });
    }
  }

  // ResizableContainer(
  //   direction: Axis.horizontal, // 가로 크기 조절
  //     children: [
  //       ResizableChild(
  //       size: const ResizableSize.ratio(0.3), // 초기 크기 30%
  //       child: Container(color: Colors.blue),
  //       ),
  //       ResizableChild(
  //       child: Container(color: Colors.green),
  //       ),
  //     ],
  // )

  @override
  Widget build(BuildContext context) {
    double screenW = MediaQuery.of(context).size.width;
    double screenH = MediaQuery.of(context).size.height;

    // 기본 폭은 화면의 48%(두 패널이 나란히 보이는 크기)이고,
    // 드래그하면 화면 끝까지 확장할 수 있다. 최소 폭은 기존 기준을 유지한다.
    final double defaultPanelWidth = screenW * 0.48;
    final double minPanelWidth = defaultPanelWidth < 160.0
        ? defaultPanelWidth
        : 160.0;
    final double maxPanelWidth = screenW;
    double currentWidth = (screenW * _widthRatio).clamp(
      minPanelWidth,
      maxPanelWidth,
    );

    double minSide = screenW < screenH ? screenW : screenH;
    double responsiveFontSize = (minSide * 0.03).clamp(11.0, 18.0);

    return Listener(
      onPointerDown: (_) => widget.onBringToFront?.call(),
      child: Align(
        alignment: Alignment.centerRight, // 💡 화면의 우측에 고정
        child: SizedBox(
          width: currentWidth,
          height: double.infinity,
          child: Stack(
            children: [
              // 1. 사이드바 메인 컨테이너 (우측 끝 고정)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: currentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(220),
                    border: const Border(
                      left: BorderSide(color: Colors.white12, width: 1.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "📋성공의열쇠 시스템",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: responsiveFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: TextField(
                          controller: _titleController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveFontSize.clamp(12.0, 16.0),
                          ),
                          decoration: InputDecoration(
                            hintText: "오늘의 스케줄",
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: responsiveFontSize.clamp(11.0, 14.0),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white.withAlpha(10),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildActionButton(
                              Icons.note_add,
                              "새로만들기",
                              _clearAll,
                              Colors.purpleAccent,
                            ),
                            _buildActionButton(
                              Icons.save,
                              "저장",
                              _saveToFile,
                              Colors.blueAccent,
                            ),
                            _buildActionButton(
                              Icons.file_open,
                              "불러오기",
                              _loadFromFile,
                              Colors.greenAccent,
                            ),
                            _buildActionButton(
                              Icons.folder,
                              "폴더관리",
                              _openStorageFolder,
                              Colors.orangeAccent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      RunCounterPanel(
                        runRecords: _runRecords,
                        onRecordsChanged: widget.onRunRecordsChanged,
                      ),
                      const Divider(
                        color: Colors.white24,
                        indent: 20,
                        endIndent: 20,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _goals.length,
                          itemBuilder: (context, index) {
                            return _buildBubbleItem(index, _goals[index].id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. 좌측 드래그 조작 영역 (드래그 시 좌측 방향으로만 폭이 조절됨)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 15,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) => widget.onBringToFront?.call(),
                    onHorizontalDragUpdate: ((details) {
                      setState(() {
                        // 마우스를 왼쪽(-dx)으로 끌면 폭이 늘어나고, 오른쪽(+dx)으로 끌면 줄어듦
                        double newWidth = (currentWidth - details.delta.dx)
                            .clamp(minPanelWidth, maxPanelWidth);
                        _widthRatio = newWidth / screenW;
                      });
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBubbleItem(int index, Key key) {
    final goal = _goals[index];
    final bool isExpanded = _activeActionIndex == index;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.withAlpha(40),
            Colors.blueAccent.withAlpha(40),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isExpanded ? Colors.blueAccent.withAlpha(100) : Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white24,
            child: Text(
              "${index + 1}",
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: goal.controller,
              onChanged: (val) {
                goal.text = val;
                widget.onGoalsChanged(_goals);
              },
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "할 일 입력...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          isExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _iconBtn(
                          Icons.arrow_upward,
                          Colors.orangeAccent,
                          () => _moveUp(index),
                        ),
                        _iconBtn(
                          Icons.arrow_downward,
                          Colors.orangeAccent,
                          () => _moveDown(index),
                        ),
                        _iconBtn(
                          Icons.gps_fixed,
                          Colors.greenAccent,
                          () => _sendToMain(goal),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _iconBtn(
                          Icons.add_circle_outline,
                          Colors.blueAccent,
                          () => _addItem(index),
                        ),
                        _iconBtn(
                          Icons.remove_circle_outline,
                          Colors.white38,
                          () => _handleDelete(index),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _activeActionIndex = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => setState(() => _activeActionIndex = index),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: color, size: 18),
      onPressed: onPressed,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    );
  }

  void _sendToMain(GoalItem goal) {
    if (goal.text.trim().isNotEmpty) {
      String firstLine = goal.text.trim().split('\n').first;
      String finalSummary = firstLine.length > 12
          ? "${firstLine.substring(0, 12)}..."
          : firstLine;
      widget.onSelectGoal(finalSummary);
      setState(() => _activeActionIndex = null);
    }
  }

  void _addItem(int index) {
    setState(() {
      _goals.insert(index + 1, GoalItem());
      _activeActionIndex = null;
    });
  }

  void _handleDelete(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_goals.length > 1) {
            _goals[index].controller.dispose();
            _goals.removeAt(index);
          } else {
            _goals[0].controller.clear();
            _goals[0].text = "";
          }
          _activeActionIndex = null;
        });
        widget.onDeleteGoal("deleted");
      }
    });
  }
}

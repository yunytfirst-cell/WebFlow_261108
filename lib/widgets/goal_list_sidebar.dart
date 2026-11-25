import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 순번 입력칸 숫자만 허용
import 'package:file_picker/file_picker.dart'; // [신규] 파일 선택을 위해 필요
import '../services/list_file_service.dart';
import '../services/item_text_style.dart';
import 'run_counter_panel.dart';
import 'text_format_toolbox.dart';

/*
[신규 파일 설명]
1. (디자인) 배경 이미지와 일치하는 투명한 바탕에 수평 그라데이션 버블 아이템 배치.
2. (기능) '+' 버튼으로 항목 추가, '-' 버튼으로 해당 항목 삭제.
3. (연동) 항목의 '🎯' 버튼 클릭 시 메인 화면의 TopBar 하단 텍스트로 내용 전송.
*/

class GoalItem {
  String text;
  bool collapsed = false; // 긴 항목 접기 상태 (파일 항목 블록의 [FOLDED] 줄로 저장)
  ItemTextStyle style = ItemTextStyle.plain; // 글자 서식 (파일 항목 블록의 [STYLE] 줄로 저장)
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

  /// 이 리스트에서 마지막으로 불러온 폴더 (다른 리스트와 공유하지 않음)
  final String? loadDirectory;
  final Function(String?) onLoadDirectoryChanged;

  const GoalListSidebar({
    this.loadDirectory,
    required this.onLoadDirectoryChanged,
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

  // 순번 직접 변경: 번호를 눌러 새 순번을 입력하고 엔터/포커스 이동/저장 시 그 위치로 옮긴다
  int? _numberEditIndex;
  // 서식 툴박스가 바꿀 항목 (마지막으로 누른 항목). 순번이 바뀌어도 따라가도록 객체로 기억한다.
  GoalItem? _styleTarget;

  // 2026-11-24 사용자 지시 "텍스트 및 아이콘 오토레이아웃": 사이드바 폭에 따라 글자·아이콘 크기를 함께 줄인다.
  // 폭 480 이상이면 1.0, 좁아질수록 비례해서 최소 0.7까지. build에서 폭을 계산할 때 갱신한다.
  double _uiScale = 1.0;
  double _sz(double base) => base * _uiScale;
  final TextEditingController _numberController = TextEditingController();
  final FocusNode _numberFocus = FocusNode();
  String? _currentFilePath;

  // [변경] 고정 픽셀 대신 화면 대비 비율로 관리하여 창 크기 조절 시 자동 대응
  double _widthRatio = 0.48;

  // 실행 카운터: 현재 열린 txt 파일의 날짜별 기록 ([RUN] 줄). 저장 버튼을 눌러야 파일에 기록된다.
  Map<String, int> get _runRecords => widget.runRecords;

  // 이 리스트의 작업 폴더: 마지막으로 불러온 폴더, 없으면 기본 폴더(FlowSchedules)
  Future<String> get _localPath async {
    final loadDirectory = widget.loadDirectory;
    if (loadDirectory != null && await Directory(loadDirectory).exists()) {
      return loadDirectory;
    }
    return (await ListFileService.directoryFor(ListFileKind.goal)).path;
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
      _numberEditIndex = null;
      _styleTarget = null;
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
    String? keptPath,
  }) async {
    if (!mounted) return;
    final conversionText = invalidCharacters.isEmpty
        ? '변환된 문자가 없습니다.'
        : invalidCharacters.toSet().join(', ');
    // 제목이 바뀌어 새 파일로 저장했으면 기존 파일이 그대로 있다고 알린다
    final keptText = keptPath == null
        ? ''
        : '\n\n제목이 바뀌어 새 파일로 저장했습니다.\n기존 파일은 그대로 있습니다:\n$keptPath';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장 완료'),
        content: SelectableText(
          '파일명:\n$fileName\n\n저장 위치:\n$path\n\n자동 변환된 문자:\n$conversionText$keptText',
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
      _applyNumberEdit(); // 순번 입력 중에 저장을 눌러도 순번을 먼저 반영
      _syncGoalTexts();
      final path = await _localPath;
      final result = _safeFileName(_titleController.text);
      final fileName = result.fileName;
      invalidCharacters = result.invalidCharacters;
      // 제목이 열린 파일 이름과 다르면 같은 폴더에 제목 이름으로 새 파일을 만들고 기존 파일은 둔다
      final previousPath = _currentFilePath;
      final file = File(
        ListFileService.saveTargetPath(
          currentFilePath: previousPath,
          directory: path,
          fileName: fileName,
        ),
      );
      final keptPath = previousPath != null && previousPath != file.path
          ? previousPath
          : null;
      savePath = file.path;
      final content = ListFileService.serialize(
        kind: ListFileKind.goal,
        title: _titleController.text,
        items: _goals.map((goal) => goal.controller.text).toList(),
        collapsed: _goals.map((goal) => goal.collapsed).toList(),
        styles: _goals.map((goal) => goal.style).toList(),
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
          keptPath: keptPath,
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

  /// 접기·펼치기 상태를 바꾸고, 열린 파일이 있으면 그 파일의 접힘 표시도 바로 고친다.
  /// 저장 버튼을 누르지 않고 앱을 닫았다 다시 열어도 사용자가 정한 상태가 유지된다.
  /// 디스크의 제목·항목·카운터는 그대로 두고 접힘 표시만 바꾼다(저장 안 한 편집은 섞지 않음).
  Future<void> _foldWrite = Future.value();

  void _setCollapsed(GoalItem goal, bool collapsed) {
    setState(() => goal.collapsed = collapsed);
    final path = _currentFilePath;
    if (path == null) return;
    final screenItems = [
      for (final it in _goals)
        (text: it.controller.text, collapsed: it.collapsed),
    ];
    // 여러 번 빨리 눌러도 파일 쓰기가 겹치지 않게 순서대로 실행한다
    _foldWrite = _foldWrite.then((_) async {
      try {
        final file = File(path);
        if (!await file.exists()) return;
        final updated = ListFileService.applyFoldState(
          await file.readAsString(),
          kind: ListFileKind.goal,
          screenItems: screenItems,
        );
        await file.writeAsString(updated, flush: true);
      } on FileSystemException catch (error) {
        debugPrint("끝장 리스트 접기 상태 저장 실패: $error");
      }
    });
  }

  // 2. 불러오기 기능 (파일 선택 후 앱에 반영)
  Future<void> _loadFromFile() async {
    final path = await _localPath;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: ListFileService.pickerInitialDirectory(path),
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    final selectedPath = result?.files.single.path;
    if (selectedPath != null) {
      final file = File(selectedPath);
      final data = ListFileService.parse(
        await file.readAsString(),
        kind: ListFileKind.goal,
      );

      setState(() {
        _goals.clear();
        _styleTarget = null;
        _runRecords.clear();
        _runRecords.addAll(data.runRecords);
        if (data.title != null) _titleController.text = data.title!;
        for (var i = 0; i < data.items.length; i++) {
          final goalText = data.items[i];
          _goals.add(
            GoalItem(text: goalText)
              ..controller.text = goalText
              ..collapsed = data.collapsed[i]
              ..style = data.styles[i],
          );
        }

        if (_goals.isEmpty) _goals.add(GoalItem());
        _currentFilePath = file.path;
        widget.onFilePathChanged(file.path);
      });
      widget.onLoadDirectoryChanged(file.parent.path);
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
  void dispose() {
    // 리스너를 먼저 떼어 dispose 중 포커스 해제로 setState가 불리지 않게 한다
    _numberFocus.removeListener(_onNumberFocusChanged);
    _numberFocus.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _onNumberFocusChanged() {
    if (!_numberFocus.hasFocus) _applyNumberEdit();
  }

  void _startNumberEdit(int index) {
    setState(() {
      _numberEditIndex = index;
      _numberController.text = '${index + 1}';
      _numberController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _numberController.text.length,
      );
    });
  }

  /// 입력한 순번 위치로 항목을 옮기고 나머지 순번은 자동으로 밀린다.
  /// 범위를 벗어나면 맨 앞(1) 또는 맨 뒤로, 숫자가 아니면 그대로 둔다.
  void _applyNumberEdit() {
    final from = _numberEditIndex;
    if (from == null || !mounted) return;
    final target = int.tryParse(_numberController.text.trim());
    setState(() {
      _numberEditIndex = null;
      _styleTarget = null;
      if (target != null && from < _goals.length) {
        final to = (target - 1).clamp(0, _goals.length - 1);
        if (to != from) {
          final moved = _goals.removeAt(from);
          _goals.insert(to, moved);
        }
      }
    });
    widget.onGoalsChanged(_goals);
  }

  @override
  void initState() {
    super.initState();
    _numberFocus.addListener(_onNumberFocusChanged);
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
      });
    }
  }

  void _moveDown(int index) {
    if (index < _goals.length - 1) {
      setState(() {
        final item = _goals.removeAt(index);
        _goals.insert(index + 1, item);
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
    _uiScale = (currentWidth / 480).clamp(0.7, 1.0);

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
                            // 2026-11-24 사용자 지시: 실행·누적 박스를 제목 아이콘 바로 앞에 둔다.
                            // 둘을 한 FittedBox로 묶어 폭이 좁으면 함께 줄어든다(오토 레이아웃).
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RunCounterPanel(
                                        runRecords: _runRecords,
                                        onRecordsChanged:
                                            widget.onRunRecordsChanged,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "📋성공의열쇠 시스템",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: responsiveFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
                            fontSize: _sz(responsiveFontSize.clamp(12.0, 16.0)),
                          ),
                          decoration: InputDecoration(
                            hintText: "오늘의 스케줄",
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: _sz(
                                responsiveFontSize.clamp(11.0, 14.0),
                              ),
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
                        // 2026-11-25 사용자 지시: 동작 버튼 오른쪽에 글자 서식 툴박스
                        child: Row(
                          children: [
                            Expanded(
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
                            const SizedBox(width: 8),
                            SizedBox(
                              // 툴박스 폭은 사이드바의 30% 이하 (동작 버튼 4개가 한 줄에 남도록)
                              width: (160 * _uiScale).clamp(
                                0.0,
                                (currentWidth - 20) * 0.3,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: TextFormatToolbox(
                                  style: _styleTarget?.style,
                                  scale: _uiScale,
                                  onChanged: (next) => setState(
                                    () => _styleTarget?.style = next,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
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
      icon: Icon(icon, size: _sz(14), color: Colors.white),
      label: Text(
        label,
        style: TextStyle(fontSize: _sz(12), color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(horizontal: _sz(12), vertical: _sz(8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBubbleItem(int index, Key key) {
    final goal = _goals[index];

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
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
        // 서식 툴박스가 바꿀 항목은 테두리를 강조한다
        border: Border.all(
          color: identical(goal, _styleTarget)
              ? Colors.blueAccent.withValues(alpha: 0.6)
              : Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNumberBadge(index),
          const SizedBox(width: 10),
          Expanded(child: _buildItemText(goal, index)),
        ],
      ),
    );
  }

  // 순번 표시: 누르면 숫자 입력칸으로 바뀐다
  Widget _buildNumberBadge(int index) {
    if (_numberEditIndex == index) {
      return SizedBox(
        width: _sz(40),
        child: TextField(
          controller: _numberController,
          focusNode: _numberFocus,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: _sz(12), color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            filled: true,
            fillColor: Colors.white24,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
          onSubmitted: (_) => _applyNumberEdit(),
        ),
      );
    }
    return Tooltip(
      message: '눌러서 순번 변경',
      child: InkWell(
        onTap: () => _startNumberEdit(index),
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: _sz(12),
          backgroundColor: Colors.white24,
          child: Text(
            "${index + 1}",
            style: TextStyle(fontSize: _sz(12), color: Colors.white),
          ),
        ),
      ),
    );
  }

  // 항목 내용: 위 도구 줄(왼쪽 ↑↓🎯 · 가운데 접기/펼치기 · 오른쪽 +−) 아래에 글을 둔다 (2026-11-24)
  Widget _buildItemText(GoalItem goal, int index) {
    // 불러온 항목 글자도 사이드바 폭에 맞춰 함께 줄어든다
    final textStyle = goal.style.apply(
      TextStyle(color: Colors.white, fontSize: _sz(14)),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: goal.controller.text, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: constraints.maxWidth);
        final isLong = painter.didExceedMaxLines;
        painter.dispose();
        final collapsed = isLong && goal.collapsed;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItemToolbar(goal, index, isLong),
            if (collapsed)
              // 접힌 상태: 첫 줄만 보이고, 누르면 펼쳐서 편집한다
              GestureDetector(
                onTap: () {
                  setState(() => _styleTarget = goal);
                  _setCollapsed(goal, false);
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    goal.controller.text.replaceAll('\n', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              )
            else
              TextField(
                controller: goal.controller,
                onTap: () => setState(() => _styleTarget = goal),
                onChanged: (val) {
                  // 입력 중 한 줄을 넘으면 접기 버튼이 나타나도록 다시 그린다
                  setState(() => goal.text = val);
                  widget.onGoalsChanged(_goals);
                },
                maxLines: null,
                style: textStyle,
                decoration: const InputDecoration(
                  hintText: "할 일 입력...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
          ],
        );
      },
    );
  }

  // 항목 위 도구 줄 (2026-11-24 사용자 지시: 오른쪽 +,-,… 묶음을 없애고 접기/펼치기 버튼 좌우에 배치).
  // 가운데 칸은 폭을 고정해 긴 항목이 아니어도 버튼 위치가 같고, 좁으면 양쪽 묶음만 줄어든다.
  Widget _buildItemToolbar(GoalItem goal, int index, bool isLong) {
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBtn(
                  Icons.arrow_upward,
                  Colors.orangeAccent,
                  () => _moveUp(index),
                  '위로 이동',
                ),
                _iconBtn(
                  Icons.arrow_downward,
                  Colors.orangeAccent,
                  () => _moveDown(index),
                  '아래로 이동',
                ),
                _iconBtn(
                  Icons.gps_fixed,
                  Colors.greenAccent,
                  () => _sendToMain(goal),
                  '메인 화면으로 보내기',
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 50, child: Center(child: _buildFoldBox(goal, isLong))),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBtn(
                  Icons.add_circle_outline,
                  Colors.blueAccent,
                  () => _addItem(index),
                  '아래에 항목 추가',
                ),
                _iconBtn(
                  Icons.remove_circle_outline,
                  Colors.white38,
                  () => _handleDelete(index),
                  '항목 삭제',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 접기/펼치기 칸 (2026-11-24 사용자 지시): 접을 수 있든 없든 항상 색이 있는 사각형 테두리 박스를 보이고,
  // 접을 수 있는(한 줄을 넘는) 항목일 때만 박스 안에 방향 모양(^ 접기 / v 펼치기)을 넣고 눌린다.
  Widget _buildFoldBox(GoalItem goal, bool isLong) {
    const color = Colors.blueAccent;
    final box = Container(
      width: _sz(24),
      height: _sz(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLong ? 0.25 : 0.08),
        border: Border.all(
          color: color.withValues(alpha: isLong ? 0.9 : 0.35),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isLong
          ? Icon(
              goal.collapsed
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              size: _sz(18),
              color: Colors.white,
            )
          : null,
    );
    if (!isLong) return box;
    return Tooltip(
      message: goal.collapsed ? '펼치기' : '접기',
      child: InkWell(
        onTap: () => _setCollapsed(goal, !goal.collapsed),
        borderRadius: BorderRadius.circular(4),
        child: box,
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return IconButton(
      icon: Icon(icon, color: color, size: _sz(18)),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  void _sendToMain(GoalItem goal) {
    if (goal.text.trim().isNotEmpty) {
      String firstLine = goal.text.trim().split('\n').first;
      String finalSummary = firstLine.length > 12
          ? "${firstLine.substring(0, 12)}..."
          : firstLine;
      widget.onSelectGoal(finalSummary);
    }
  }

  void _addItem(int index) {
    setState(() {
      _goals.insert(index + 1, GoalItem());
    });
  }

  void _handleDelete(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_goals.length > 1) {
            if (identical(_goals[index], _styleTarget)) _styleTarget = null;
            _goals[index].controller.dispose();
            _goals.removeAt(index);
          } else {
            _goals[0].controller.clear();
            _goals[0].text = "";
          }
        });
        widget.onDeleteGoal("deleted");
      }
    });
  }
}

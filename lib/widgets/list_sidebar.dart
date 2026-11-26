import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 순번 입력칸 숫자만 허용
import 'package:file_picker/file_picker.dart';
import '../services/list_file_service.dart';
import 'run_counter_panel.dart';
import 'styled_text_controller.dart';
import 'text_format_toolbox.dart';

/*
끝장 리스트(성공의 열쇠)와 알아차림 리스트가 함께 쓰는 사이드바 본체.
2026-11-25 사용자 지시 "모듈화·코드 크기 최적화·실행 속도 최적화로 다시 만들되 결과는 완전히 동일":
두 파일에 거의 같은 코드가 약 1,000줄씩 복사되어 있던 것을 이 파일 하나로 합쳤다.
- 리스트마다 다른 값(위치·색·문구·기본 파일명·파일 종류·🎯 유무)은 [ListSidebarSpec]에 둔다.
- 상태(항목·카운터·열린 파일·불러온 폴더)는 위젯마다 따로라 두 리스트가 서로 섞이지 않는다
  (flow-list-sidebars §1 "절대 공유하지 않는 것").
- 바깥에서 쓰는 이름(GoalListSidebar·AwarenessListSidebar·GoalItem·AwarenessItem)은 그대로다.
*/

/// 리스트 항목 한 개 (두 리스트 공통)
class ListSidebarItem {
  String text;
  bool collapsed = false; // 긴 항목 접기 상태 (파일 항목 블록의 [FOLDED] 줄로 저장)
  final Key id; // 각 항목의 고유 식별자
  // 글자마다 서식을 기억한다 (파일 항목 블록의 [SPAN] 줄로 저장)
  final StyledTextController controller; // 텍스트 꼬임 방지

  ListSidebarItem({this.text = ""})
    : id = UniqueKey(),
      controller = StyledTextController(text: text);
}

/// 리스트마다 다른 화면 값 (flow-list-sidebars §1 표)
class ListSidebarSpec {
  const ListSidebarSpec({
    required this.kind,
    required this.title,
    required this.titleHint,
    required this.itemHint,
    required this.defaultFileName,
    required this.logName,
    required this.accent,
    required this.panelAlpha,
    required this.dockRight,
  });

  /// 파일 형식·저장 폴더
  final ListFileKind kind;

  /// 패널 제목, 제목 입력칸 힌트, 항목 입력칸 힌트
  final String title;
  final String titleHint;
  final String itemHint;

  /// 제목이 비었거나 예약어일 때 쓰는 파일명
  final String defaultFileName;

  /// 오류 로그에 쓰는 리스트 이름
  final String logName;

  /// 제목 글자·항목 그라데이션·선택 테두리·순번 입력칸·접기 박스 색
  final Color accent;

  /// 패널 바탕(검정) 불투명도
  final int panelAlpha;

  /// true: 화면 오른쪽에 붙고 왼쪽 가장자리를 끌어 폭 조절(끝장 리스트)
  /// false: 화면 왼쪽에 붙고 오른쪽 가장자리를 끌어 폭 조절(알아차림 리스트)
  final bool dockRight;

  static const goal = ListSidebarSpec(
    kind: ListFileKind.goal,
    title: "📋성공의열쇠 시스템",
    titleHint: "오늘의 스케줄",
    itemHint: "할 일 입력...",
    defaultFileName: '미정_스케줄',
    logName: '끝장 리스트',
    accent: Colors.blueAccent,
    panelAlpha: 220,
    dockRight: true,
  );

  static const awareness = ListSidebarSpec(
    kind: ListFileKind.awareness,
    title: "👁️ 알아차림 리스트",
    titleHint: "오늘의 알아차림",
    itemHint: "내용 입력...",
    defaultFileName: '미정_알아차림',
    logName: '알아차림 리스트',
    accent: Colors.orangeAccent,
    panelAlpha: 200,
    dockRight: false,
  );
}

class ListSidebar<T extends ListSidebarItem> extends StatefulWidget {
  const ListSidebar({
    super.key,
    required this.spec,
    required this.newItem,
    this.loadDirectory,
    required this.onLoadDirectoryChanged,
    required this.runRecords,
    required this.onRunRecordsChanged,
    this.onBringToFront,
    required this.onClose,
    required this.initialTitle,
    required this.initialItems,
    required this.onTitleChanged,
    required this.onItemsChanged,
    required this.initialFilePath,
    required this.onFilePathChanged,
    this.onSelectItem,
    this.onDeleteItem,
  });

  final ListSidebarSpec spec;

  /// 빈 항목 만들기 (GoalItem.new / AwarenessItem.new)
  final T Function({String text}) newItem;

  final VoidCallback onClose;
  final String initialTitle;
  final List<T> initialItems;
  final Function(String) onTitleChanged;
  final Function(List<T>) onItemsChanged;
  final String? initialFilePath;
  final Function(String?) onFilePathChanged;
  final Map<String, int> runRecords; // 실행 카운터 기록 (사이드바를 닫아도 유지되도록 main에서 보관)
  final VoidCallback onRunRecordsChanged;
  final VoidCallback? onBringToFront; // 패널 조작 시 다른 패널보다 위로 올림

  /// 이 리스트에서 마지막으로 불러온 폴더 (다른 리스트와 공유하지 않음)
  final String? loadDirectory;
  final Function(String?) onLoadDirectoryChanged;

  /// 🎯 메인 화면으로 보내기 (끝장 리스트만). null이면 🎯 버튼이 없다.
  final Function(String)? onSelectItem;

  /// 항목 삭제 알림 (끝장 리스트만)
  final Function(String)? onDeleteItem;

  @override
  State<ListSidebar<T>> createState() => _ListSidebarState<T>();
}

class _ListSidebarState<T extends ListSidebarItem>
    extends State<ListSidebar<T>> {
  late TextEditingController _titleController;
  late List<T> _items;

  ListSidebarSpec get _spec => widget.spec;

  // 순번 직접 변경: 번호를 눌러 새 순번을 입력하고 엔터/포커스 이동/저장 시 그 위치로 옮긴다
  int? _numberEditIndex;
  static final Listenable _noTarget = ValueNotifier<int>(0);
  // 서식 툴박스가 바꿀 항목 (마지막으로 누른 항목). 순번이 바뀌어도 따라가도록 객체로 기억한다.
  T? _styleTarget;

  // 2026-11-24 사용자 지시 "텍스트 및 아이콘 오토레이아웃": 사이드바 폭에 따라 글자·아이콘 크기를 함께 줄인다.
  // 폭 480 이상이면 1.0, 좁아질수록 비례해서 최소 0.7까지. build에서 폭을 계산할 때 갱신한다.
  double _uiScale = 1.0;
  double _sz(double base) => base * _uiScale;
  final TextEditingController _numberController = TextEditingController();
  final FocusNode _numberFocus = FocusNode();
  String? _currentFilePath;

  // 고정 픽셀 대신 화면 대비 비율로 관리하여 창 크기 조절 시 자동 대응
  double _widthRatio = 0.48;

  // 이 리스트의 작업 폴더: 마지막으로 불러온 폴더, 없으면 기본 폴더(FlowSchedules / FlowAwareness)
  Future<String> get _localPath async {
    final loadDirectory = widget.loadDirectory;
    if (loadDirectory != null && await Directory(loadDirectory).exists()) {
      return loadDirectory;
    }
    return (await ListFileService.directoryFor(_spec.kind)).path;
  }

  // 현재 화면의 모든 내용을 비우고 새로 시작하는 기능 (기존 데이터 삭제 아님)
  void _clearAll() {
    setState(() {
      _titleController.clear();
      // 기존 리스트의 컨트롤러들을 메모리에서 해제
      for (final item in _items) {
        item.controller.dispose();
      }
      // 초기 상태(비어있는 항목 1개)로 리셋
      _items = [widget.newItem()];
      _numberEditIndex = null;
      _styleTarget = null;
      _currentFilePath = null;
      _savedDate = null;
      widget.runRecords.clear();
    });
    widget.onRunRecordsChanged();
    widget.onFilePathChanged(null);
    // 부모 위젯(main.dart)의 상태도 동기화
    widget.onTitleChanged("");
    widget.onItemsChanged(_items);
    widget.onSelectItem?.call(""); // 메인 화면에 떠있는 리스트 제거
  }

  // Windows 예약 파일명 (확장자 앞 이름이 이것이면 저장할 수 없다)
  static const _reservedNames = {
    'con', 'prn', 'aux', 'nul', //
    'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9',
    'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
  };

  ({String fileName, List<String> invalidCharacters}) _safeFileName(
    String title,
  ) {
    final invalidCharacters = <String>[];
    var fileName = title.trim();
    fileName = fileName.replaceAllMapped(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), (
      match,
    ) {
      invalidCharacters.add(_displayCharacter(match.group(0)!));
      return ' x';
    });

    if (RegExp(r'[. ]+$').hasMatch(fileName)) {
      invalidCharacters.add('파일명 끝의 점(.) 또는 공백');
      fileName = fileName.replaceFirst(RegExp(r'[. ]+$'), ' x');
    }

    if (fileName.toLowerCase().endsWith('.txt')) {
      fileName = fileName.substring(0, fileName.length - 4).trimRight();
    }

    final reserved = _reservedNames.contains(fileName.toLowerCase());
    if (fileName.isEmpty || reserved) {
      if (reserved) {
        invalidCharacters.add('Windows 예약 파일명 "$fileName"');
      }
      fileName = _spec.defaultFileName;
    }

    return (fileName: '$fileName.txt', invalidCharacters: invalidCharacters);
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

  void _syncItemTexts() {
    for (final item in _items) {
      item.text = item.controller.text;
    }
    widget.onItemsChanged(_items);
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

  // 파일 저장 기능
  Future<void> _saveToFile() async {
    var savePath = '';
    var invalidCharacters = <String>[];
    try {
      _applyNumberEdit(); // 순번 입력 중에 저장을 눌러도 순번을 먼저 반영
      _syncItemTexts();
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
        kind: _spec.kind,
        title: _titleController.text,
        items: _items.map((item) => item.controller.text).toList(),
        collapsed: _items.map((item) => item.collapsed).toList(),
        spans: _items.map((item) => item.controller.spans).toList(),
        runRecords: widget.runRecords,
      );

      await file.writeAsString(content, flush: true);
      _currentFilePath = file.path;
      // 2026-11-26 사용자 지시: 저장하면 실행 박스의 날짜가 오늘로 바뀐다
      if (mounted) setState(() => _savedDate = DateTime.now());
      widget.onFilePathChanged(file.path);
      widget.onItemsChanged(_items);
      if (mounted) {
        await _showSaveSuccessDialog(
          path: file.path,
          fileName: file.path.split(RegExp(r'[/\\]')).last,
          invalidCharacters: invalidCharacters,
          keptPath: keptPath,
        );
      }
    } on FileSystemException catch (error) {
      debugPrint("${_spec.logName} 저장 실패: $error");
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

  /// 실행 박스에 보이는 저장 날짜 = 열린 파일의 마지막 저장(수정) 시각 (2026-11-26 사용자 지시).
  /// 파일 형식을 바꾸지 않아 예전 파일도 그대로 날짜가 보인다.
  DateTime? _savedDate;

  static DateTime? _fileSavedDate(String? path) {
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file.lastModifiedSync() : null;
  }

  void _setCollapsed(T item, bool collapsed) {
    setState(() => item.collapsed = collapsed);
    final path = _currentFilePath;
    if (path == null) return;
    final screenItems = [
      for (final it in _items)
        (text: it.controller.text, collapsed: it.collapsed),
    ];
    // 여러 번 빨리 눌러도 파일 쓰기가 겹치지 않게 순서대로 실행한다
    _foldWrite = _foldWrite.then((_) async {
      try {
        final file = File(path);
        if (!await file.exists()) return;
        final updated = ListFileService.applyFoldState(
          await file.readAsString(),
          kind: _spec.kind,
          screenItems: screenItems,
        );
        // 접기·펼치기는 저장이 아니므로 실행 박스 날짜(파일 수정 시각)를 그대로 둔다
        final savedAt = await file.lastModified();
        await file.writeAsString(updated, flush: true);
        await file.setLastModified(savedAt);
      } on FileSystemException catch (error) {
        debugPrint("${_spec.logName} 접기 상태 저장 실패: $error");
      }
    });
  }

  // 불러오기 기능 (파일 선택 후 앱에 반영)
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
        kind: _spec.kind,
      );
      final savedDate = await file.lastModified();

      setState(() {
        _items.clear();
        _styleTarget = null;
        widget.runRecords
          ..clear()
          ..addAll(data.runRecords);
        if (data.title != null) _titleController.text = data.title!;
        for (var i = 0; i < data.items.length; i++) {
          final itemText = data.items[i];
          _items.add(
            widget.newItem(text: itemText)
              ..controller.text = itemText
              ..collapsed = data.collapsed[i]
              ..controller.spans = data.spans[i],
          );
        }

        if (_items.isEmpty) _items.add(widget.newItem());
        _currentFilePath = file.path;
        _savedDate = savedDate;
        widget.onFilePathChanged(file.path);
        widget.onItemsChanged(_items);
      });
      widget.onLoadDirectoryChanged(file.parent.path);
      widget.onRunRecordsChanged();
      widget.onSelectItem?.call("");
    }
  }

  // 폴더관리 기능 (윈도우 탐색기 열기)
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
      if (target != null && from < _items.length) {
        final to = (target - 1).clamp(0, _items.length - 1);
        if (to != from) {
          final moved = _items.removeAt(from);
          _items.insert(to, moved);
        }
      }
    });
    widget.onItemsChanged(_items);
  }

  @override
  void initState() {
    super.initState();
    _numberFocus.addListener(_onNumberFocusChanged);
    _titleController = TextEditingController(text: widget.initialTitle);
    _items = widget.initialItems;
    _currentFilePath = widget.initialFilePath;
    _savedDate = _fileSavedDate(_currentFilePath);

    _titleController.addListener(() {
      widget.onTitleChanged(_titleController.text);
    });
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _items.removeAt(index);
        _items.insert(index - 1, item);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _items.length - 1) {
      setState(() {
        final item = _items.removeAt(index);
        _items.insert(index + 1, item);
      });
    }
  }

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

    final dockRight = _spec.dockRight;
    const edgeSide = BorderSide(color: Colors.white12, width: 1.5);
    final closeButton = IconButton(
      icon: const Icon(Icons.close, color: Colors.white70),
      onPressed: widget.onClose,
    );
    // 2026-11-24 사용자 지시: 실행·누적 박스를 제목 아이콘 바로 앞에 둔다.
    // 둘을 한 FittedBox로 묶어 폭이 좁으면 함께 줄어든다(오토 레이아웃).
    final titleGroup = Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RunCounterPanel(
                savedDate: _savedDate,
                runRecords: widget.runRecords,
                onRecordsChanged: widget.onRunRecordsChanged,
              ),
              const SizedBox(width: 10),
              Text(
                _spec.title,
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
    );

    return Listener(
      onPointerDown: (_) => widget.onBringToFront?.call(),
      child: Align(
        // 끝장 리스트는 화면 오른쪽, 알아차림 리스트는 왼쪽에 고정
        alignment: dockRight ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: currentWidth,
          height: double.infinity,
          child: Stack(
            children: [
              // 1. 사이드바 메인 컨테이너 (붙은 쪽 끝 고정)
              Positioned(
                right: dockRight ? 0 : null,
                left: dockRight ? null : 0,
                top: 0,
                bottom: 0,
                width: currentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(_spec.panelAlpha),
                    border: dockRight
                        ? const Border(left: edgeSide)
                        : const Border(right: edgeSide),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          // 닫기(X)는 화면 바깥쪽 끝에 둔다
                          children: dockRight
                              ? [titleGroup, closeButton]
                              : [closeButton, titleGroup],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: TextField(
                          controller: _titleController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            color: _spec.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: _sz(responsiveFontSize.clamp(12.0, 16.0)),
                          ),
                          decoration: InputDecoration(
                            hintText: _spec.titleHint,
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
                                // 툴박스를 눌러도 항목 입력칸의 포커스·선택이 풀리지 않게 한다
                                child: TextFieldTapRegion(
                                  child: ListenableBuilder(
                                    // 글자 선택이 바뀌면 툴박스 상태(켜짐·지금 서식)를 다시 그린다
                                    listenable:
                                        _styleTarget?.controller ?? _noTarget,
                                    builder: (context, _) => TextFormatToolbox(
                                      style: _styleTarget?.controller
                                          .styleAtRange(),
                                      scale: _uiScale,
                                      onChanged: (edit) {
                                        final changed =
                                            _styleTarget?.controller
                                                .applyToRange(edit) ??
                                            false;
                                        if (changed) setState(() {});
                                      },
                                    ),
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
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return _buildBubbleItem(index, _items[index].id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. 안쪽 가장자리 드래그 조작 영역 (화면 안쪽으로 끌면 폭이 늘어남)
              Positioned(
                left: dockRight ? 0 : null,
                right: dockRight ? null : 0,
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
                        // 오른쪽 패널은 왼쪽(-dx)으로, 왼쪽 패널은 오른쪽(+dx)으로 끌면 폭이 늘어남
                        final grow = dockRight
                            ? -details.delta.dx
                            : details.delta.dx;
                        double newWidth = (currentWidth + grow).clamp(
                          minPanelWidth,
                          maxPanelWidth,
                        );
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
    final item = _items[index];

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.withAlpha(40), _spec.accent.withAlpha(40)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        // 서식 툴박스가 바꿀 항목은 테두리를 강조한다
        border: Border.all(
          color: identical(item, _styleTarget)
              ? _spec.accent.withValues(alpha: 0.6)
              : Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNumberBadge(index),
          const SizedBox(width: 10),
          Expanded(child: _buildItemText(item, index)),
        ],
      ),
    );
  }

  // 순번 표시: 누르면 숫자 입력칸으로 바뀐다
  Widget _buildNumberBadge(int index) {
    if (_numberEditIndex == index) {
      final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _spec.accent),
      );
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
            border: border,
            focusedBorder: border,
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

  // 항목 내용: 위 도구 줄(왼쪽 ↑↓(🎯) · 가운데 접기/펼치기 · 오른쪽 +−) 아래에 글을 둔다 (2026-11-24)
  Widget _buildItemText(T item, int index) {
    // 불러온 항목 글자도 사이드바 폭에 맞춰 함께 줄어든다
    // 글자별 서식은 컨트롤러가 입힌다 (선택한 글자만 바뀜)
    final textStyle = TextStyle(color: Colors.white, fontSize: _sz(14));
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: item.controller.styledSpan(textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: constraints.maxWidth);
        final isLong = painter.didExceedMaxLines;
        painter.dispose();
        final collapsed = isLong && item.collapsed;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItemToolbar(item, index, isLong),
            if (collapsed)
              // 접힌 상태: 첫 줄만 보이고, 누르면 펼쳐서 편집한다
              GestureDetector(
                onTap: () {
                  setState(() => _styleTarget = item);
                  _setCollapsed(item, false);
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Text.rich(
                    item.controller.styledSpan(
                      textStyle,
                      displayText: item.controller.text.replaceAll('\n', ' '),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            else
              // 포커스를 받으면(클릭·드래그 선택) 서식 툴박스 대상이 된다
              Focus(
                onFocusChange: (focused) {
                  if (focused && !identical(_styleTarget, item)) {
                    setState(() => _styleTarget = item);
                  }
                },
                child: TextField(
                  controller: item.controller,
                  onTap: () => setState(() => _styleTarget = item),
                  onChanged: (val) {
                    // 입력 중 한 줄을 넘으면 접기 버튼이 나타나도록 다시 그린다
                    setState(() => item.text = val);
                    widget.onItemsChanged(_items);
                  },
                  maxLines: null,
                  style: textStyle,
                  decoration: InputDecoration(
                    hintText: _spec.itemHint,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 항목 위 도구 줄 (2026-11-24 사용자 지시: 오른쪽 +,-,… 묶음을 없애고 접기/펼치기 버튼 좌우에 배치).
  // 가운데 칸은 폭을 고정해 긴 항목이 아니어도 버튼 위치가 같고, 좁으면 양쪽 묶음만 줄어든다.
  Widget _buildItemToolbar(T item, int index, bool isLong) {
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
                // 🎯 메인 화면으로 보내기는 끝장 리스트에만 있다
                if (widget.onSelectItem != null)
                  _iconBtn(
                    Icons.gps_fixed,
                    Colors.greenAccent,
                    () => _sendToMain(item),
                    '메인 화면으로 보내기',
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: 50, child: Center(child: _buildFoldBox(item, isLong))),
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
  Widget _buildFoldBox(T item, bool isLong) {
    final color = _spec.accent;
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
              item.collapsed
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              size: _sz(18),
              color: Colors.white,
            )
          : null,
    );
    if (!isLong) return box;
    return Tooltip(
      message: item.collapsed ? '펼치기' : '접기',
      child: InkWell(
        onTap: () => _setCollapsed(item, !item.collapsed),
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

  void _sendToMain(T item) {
    if (item.text.trim().isNotEmpty) {
      String firstLine = item.text.trim().split('\n').first;
      String finalSummary = firstLine.length > 12
          ? "${firstLine.substring(0, 12)}..."
          : firstLine;
      widget.onSelectItem?.call(finalSummary);
    }
  }

  void _addItem(int index) {
    setState(() {
      _items.insert(index + 1, widget.newItem());
    });
    widget.onItemsChanged(_items);
  }

  void _handleDelete(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_items.length > 1) {
            if (identical(_items[index], _styleTarget)) _styleTarget = null;
            _items[index].controller.dispose();
            _items.removeAt(index);
          } else {
            _items[0].controller.clear();
            _items[0].text = "";
          }
        });
        widget.onItemsChanged(_items);
        widget.onDeleteItem?.call("deleted");
      }
    });
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/list_file_service.dart';
import 'run_counter_panel.dart';

/*
[AwarenessListSidebar]
1. GoalListSidebar와 동일한 구조를 가짐.
2. '알아차림' 리스트를 관리하며, 메인 화면 전송 기능은 제외됨.
3. 파일 저장 및 불러오기 기능 포함.
*/

class AwarenessItem {
  String text;
  final Key id;
  final TextEditingController controller;

  AwarenessItem({this.text = ""})
    : id = UniqueKey(),
      controller = TextEditingController(text: text);
}

class AwarenessListSidebar extends StatefulWidget {
  final VoidCallback onClose;
  final String initialTitle;
  final List<AwarenessItem> initialItems;
  final String? initialFilePath;
  final Map<String, int> runRecords;
  final VoidCallback onRunRecordsChanged;
  final VoidCallback? onBringToFront; // 패널 조작 시 다른 패널보다 위로 올림
  final Function(String) onTitleChanged;
  final Function(List<AwarenessItem>) onItemsChanged;
  final Function(String?) onFilePathChanged;

  const AwarenessListSidebar({
    super.key,
    required this.onClose,
    required this.initialTitle,
    required this.initialItems,
    required this.initialFilePath,
    required this.runRecords,
    required this.onRunRecordsChanged,
    this.onBringToFront,
    required this.onTitleChanged,
    required this.onItemsChanged,
    required this.onFilePathChanged,
  });

  @override
  State<AwarenessListSidebar> createState() => _AwarenessListSidebarState();
}

class _AwarenessListSidebarState extends State<AwarenessListSidebar> {
  late TextEditingController _titleController;
  late List<AwarenessItem> _items;
  int? _activeActionIndex;
  String? _currentFilePath;
  double _widthRatio = 0.48;

  Future<String> get _localPath async {
    return (await ListFileService.sharedDirectory()).path;
  }

  void _clearAll() {
    setState(() {
      _titleController.clear();
      for (var item in _items) {
        item.controller.dispose();
      }
      _items = [AwarenessItem()];
      _activeActionIndex = null;
      _currentFilePath = null;
      widget.runRecords.clear();
    });
    widget.onRunRecordsChanged();
    widget.onTitleChanged("");
    widget.onItemsChanged(_items);
    widget.onFilePathChanged(null);
  }

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
    if (fileName.isEmpty || reservedNames.contains(fileName.toLowerCase())) {
      if (reservedNames.contains(fileName.toLowerCase())) {
        invalidCharacters.add('Windows 예약 파일명 "$fileName"');
      }
      fileName = '미정_알아차림';
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

  Future<void> _saveToFile() async {
    var savePath = '';
    var invalidCharacters = <String>[];
    try {
      _syncItemTexts();
      final path = await _localPath;
      final result = _safeFileName(_titleController.text);
      invalidCharacters = result.invalidCharacters;
      final fileName = result.fileName;
      final file = File(_currentFilePath ?? '$path/$fileName');
      savePath = file.path;
      final content = ListFileService.serialize(
        kind: ListFileKind.awareness,
        title: _titleController.text,
        items: _items.map((item) => item.controller.text).toList(),
        runRecords: widget.runRecords,
      );

      await file.writeAsString(content, flush: true);
      _currentFilePath = file.path;
      widget.onFilePathChanged(file.path);
      if (mounted) {
        await _showSaveSuccessDialog(
          path: file.path,
          fileName: file.path.split(RegExp(r'[/\\]')).last,
          invalidCharacters: invalidCharacters,
        );
      }
    } on FileSystemException catch (error) {
      debugPrint("알아차림 리스트 저장 실패: $error");
      await _showSaveFailureDialog(
        path: savePath,
        invalidCharacters: invalidCharacters,
        error: error,
      );
    }
  }

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
        _items.clear();
        widget.runRecords
          ..clear()
          ..addAll(data.runRecords);
        if (data.title != null) _titleController.text = data.title!;

        for (final itemText in data.items) {
          _items.add(AwarenessItem(text: itemText)..controller.text = itemText);
        }

        if (_items.isEmpty) _items.add(AwarenessItem());
        _currentFilePath = file.path;
        widget.onFilePathChanged(file.path);
        widget.onItemsChanged(_items);
      });
      widget.onRunRecordsChanged();
    }
  }

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
    _items = widget.initialItems;
    _currentFilePath = widget.initialFilePath;
    _titleController.addListener(() {
      widget.onTitleChanged(_titleController.text);
    });
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _items.removeAt(index);
        _items.insert(index - 1, item);
        _activeActionIndex = index - 1;
      });
    }
  }

  void _moveDown(int index) {
    if (index < _items.length - 1) {
      setState(() {
        final item = _items.removeAt(index);
        _items.insert(index + 1, item);
        _activeActionIndex = index + 1;
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

    double minSide = screenW < screenH ? screenW : screenH;
    double responsiveFontSize = (minSide * 0.03).clamp(11.0, 18.0);

    return Listener(
      onPointerDown: (_) => widget.onBringToFront?.call(),
      child: Align(
        alignment: Alignment.centerLeft, // 💡 화면의 좌측에 고정
        child: SizedBox(
          width: currentWidth,
          height: double.infinity,
          child: Stack(
            children: [
              // 1. 사이드바 메인 컨테이너 (좌측 끝 고정)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: currentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    border: const Border(
                      right: BorderSide(color: Colors.white12, width: 1.5),
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
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              onPressed: widget.onClose,
                            ),
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "👁️ 알아차림 리스트",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: responsiveFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
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
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveFontSize.clamp(12.0, 16.0),
                          ),
                          decoration: InputDecoration(
                            hintText: "오늘의 알아차림",
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
                        runRecords: widget.runRecords,
                        onRecordsChanged: widget.onRunRecordsChanged,
                      ),
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

              // 2. 우측 드래그 조작 영역 (드래그 시 좌우 방향으로 폭이 조절됨)
              Positioned(
                right: 0,
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
                        // 마우스를 오른쪽(+dx)으로 끌면 폭이 늘어나고, 왼쪽(-dx)으로 끌면 줄어듦
                        double newWidth = (currentWidth + details.delta.dx)
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
    final item = _items[index];
    final bool isExpanded = _activeActionIndex == index;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.withAlpha(40),
            Colors.orangeAccent.withAlpha(40),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isExpanded
              ? Colors.orangeAccent.withAlpha(100)
              : Colors.white10,
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
              controller: item.controller,
              onChanged: (val) {
                item.text = val;
                widget.onItemsChanged(_items);
              },
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "내용 입력...",
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

  void _addItem(int index) {
    setState(() {
      _items.insert(index + 1, AwarenessItem());
      _activeActionIndex = null;
    });
    widget.onItemsChanged(_items);
  }

  void _handleDelete(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_items.length > 1) {
            _items[index].controller.dispose();
            _items.removeAt(index);
          } else {
            _items[0].controller.clear();
            _items[0].text = "";
          }
          _activeActionIndex = null;
        });
        widget.onItemsChanged(_items);
      }
    });
  }
}

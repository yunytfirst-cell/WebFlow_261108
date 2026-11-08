import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:path/path.dart' as p; 
import 'package:flutter/services.dart';
import 'settings/transparency_slider.dart';

class SettingsDialog extends StatefulWidget {
  final int initialMaxSeconds;
  final String initialGlowMessage;
  final bool initialIsAlarmOn;
  final String initialBgVideoPath;
  final double initialPlaybackSpeed;
  final double initialBgOpacity;
  final double initialUiOpacity;
  final LogicalKeyboardKey? initialTargetKey;
  
  final Function({
    int? newSeconds, 
    String? newMessage, 
    bool? newAlarm, 
    String? newPath, 
    double? newSpeed, 
    double? newBgOpacity, 
    double? newUiOpacity,
    LogicalKeyboardKey? newKey
  }) onApply;

  const SettingsDialog({
    super.key,
    required this.initialMaxSeconds,
    required this.initialGlowMessage,
    required this.initialIsAlarmOn,
    required this.initialBgVideoPath,
    required this.initialPlaybackSpeed,
    required this.initialBgOpacity,
    required this.initialUiOpacity,
    required this.initialTargetKey,
    required this.onApply,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _hourController;
  late TextEditingController _minController;
  late TextEditingController _secController;
  late TextEditingController _messageController;
  late bool _isAlarmOn;
  late String _bgVideoPath;
  late double _playbackSpeed;
  late double _bgOpacity;
  late double _uiOpacity;
  LogicalKeyboardKey? _tempTargetKey;
  final FocusNode _keyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(text: (widget.initialMaxSeconds ~/ 3600).toString());
    _minController = TextEditingController(text: ((widget.initialMaxSeconds % 3600) ~/ 60).toString());
    _secController = TextEditingController(text: (widget.initialMaxSeconds % 60).toString());
    _messageController = TextEditingController(text: widget.initialGlowMessage);
    _isAlarmOn = widget.initialIsAlarmOn;
    _bgVideoPath = widget.initialBgVideoPath;
    _playbackSpeed = widget.initialPlaybackSpeed;
    _bgOpacity = widget.initialBgOpacity;
    _uiOpacity = widget.initialUiOpacity;
    _tempTargetKey = widget.initialTargetKey;
    _keyFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minController.dispose();
    _secController.dispose();
    _messageController.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("⚙️ 개별 설정 관리", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackgroundTransparencySlider(
                title: "앱 배경 투명도 (바탕화면 투과)",
                currentOpacity: _bgOpacity,
                onChanged: (val) {
                  setState(() => _bgOpacity = val);
                  widget.onApply(newBgOpacity: val);
                },
              ),
              const SizedBox(height: 15),
              BackgroundTransparencySlider(
                title: "UI 요소 투명도 (숫자/버튼 등)",
                currentOpacity: _uiOpacity,
                onChanged: (val) {
                  setState(() => _uiOpacity = val);
                  widget.onApply(newUiOpacity: val);
                },
              ),
              const SizedBox(height: 25),

              _buildSection("타이머 시간 설정 (시:분:초)", [
                Expanded(child: _buildField(_hourController, "시")),
                _colon(),
                Expanded(child: _buildField(_minController, "분")),
                _colon(),
                Expanded(child: _buildField(_secController, "초")),
                const SizedBox(width: 10),
                _reflectBtn("시간 반영", () {
                  int total = (int.tryParse(_hourController.text) ?? 0) * 3600 + (int.tryParse(_minController.text) ?? 0) * 60 + (int.tryParse(_secController.text) ?? 0);
                  widget.onApply(newSeconds: total > 0 ? total : widget.initialMaxSeconds);
                }),
              ]),

              _buildSection("표시 메시지 설정", [
                Expanded(child: _buildField(_messageController, "메시지 내용")),
                const SizedBox(width: 10),
                _reflectBtn("문구 반영", () => widget.onApply(newMessage: _messageController.text)),
              ]),

              _buildSection("PC 배경 파일 선택", [
                ElevatedButton.icon(onPressed: _pickBgFile, icon: const Icon(Icons.folder_open, size: 16), label: const Text("파일 찾기"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700])),
                const SizedBox(width: 8),
                if (_bgVideoPath.isNotEmpty) IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20), onPressed: () => setState(() => _bgVideoPath = "")),
                const Spacer(),
                _reflectBtn("배경 반영", () => widget.onApply(newPath: _bgVideoPath)),
              ]),
              
              if (_bgVideoPath.isNotEmpty) ...[
                Padding(padding: const EdgeInsets.only(top: 5), child: Text("📂 ${p.basename(_bgVideoPath)}", style: const TextStyle(color: Colors.blueAccent, fontSize: 11))),
                const SizedBox(height: 10),
                _buildSection("동영상 재생 속도", [
                  _speedBtn("느리게", 0.5), const SizedBox(width: 8), _speedBtn("보통", 1.0), const SizedBox(width: 8), _speedBtn("빠르게", 2.0),
                  const Spacer(),
                  _reflectBtn("속도 반영", () => widget.onApply(newSpeed: _playbackSpeed)),
                ]),
              ],

              _buildSection("카운터 단축키 설정", [
                Expanded(child: GestureDetector(
                  onTap: () { FocusScope.of(context).unfocus(); _keyFocusNode.requestFocus(); },
                  child: KeyboardListener(
                    focusNode: _keyFocusNode,
                    onKeyEvent: (event) { if (event is KeyDownEvent) setState(() => _tempTargetKey = event.logicalKey); },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5), border: Border.all(color: _keyFocusNode.hasFocus ? Colors.blueAccent : Colors.white10)),
                      child: Text(_tempTargetKey?.keyLabel ?? "미설정", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
                )),
                const SizedBox(width: 10),
                _reflectBtn("키 반영", () => widget.onApply(newKey: _tempTargetKey)),
              ]),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("알람 소리 및 영상 음소거", style: TextStyle(color: Colors.white, fontSize: 14)),
                    Switch(value: _isAlarmOn, onChanged: (val) { setState(() => _isAlarmOn = val); widget.onApply(newAlarm: val); }, activeThumbColor: Colors.greenAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("닫기", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildSection(String label, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Row(children: children),
    const SizedBox(height: 25),
  ]);

  Widget _colon() => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(":", style: TextStyle(color: Colors.white54)));
  Widget _buildField(TextEditingController ctrl, String hint) => TextField(controller: ctrl, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: hint, isDense: true, enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12))));
  Widget _speedBtn(String label, double speed) => InkWell(onTap: () => setState(() => _playbackSpeed = speed), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _playbackSpeed == speed ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(5), border: Border.all(color: _playbackSpeed == speed ? Colors.blueAccent : Colors.white10)), child: Text(label, style: TextStyle(color: _playbackSpeed == speed ? Colors.white : Colors.white54, fontSize: 11))));
  Widget _reflectBtn(String label, VoidCallback onPressed) => ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withValues(alpha: 0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10), elevation: 0, side: const BorderSide(color: Colors.blueAccent, width: 0.5)), child: Text(label, style: const TextStyle(fontSize: 11)));

  Future<void> _pickBgFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['mp4', 'mov', 'avi', 'jpg', 'jpeg', 'png']);
    if (result != null && result.files.single.path != null) {
      String originalPath = result.files.single.path!;
      final directory = await getApplicationSupportDirectory();
      final bgFolder = Directory('${directory.path}/bg_media');
      if (!await bgFolder.exists()) await bgFolder.create(recursive: true);
      String fileName = p.basename(originalPath);
      String newPath = '${bgFolder.path}/$fileName';
      await File(originalPath).copy(newPath);
      setState(() => _bgVideoPath = newPath);
    }
  }
}

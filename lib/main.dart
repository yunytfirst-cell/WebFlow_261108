import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'widgets/top_bar.dart';
import 'widgets/info_bar.dart';
import 'widgets/set_group.dart';
import 'widgets/goal_list_sidebar.dart';
import 'widgets/awareness_list_sidebar.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/background_engine.dart';
import 'widgets/daily_schedule_dialog.dart';

import 'models/display_mode.dart';
import 'models/clock_marker.dart';
import 'widgets/modes/normal_mode_view.dart';
import 'widgets/modes/info_bar_mode_view.dart';
import 'widgets/modes/timeline_mode_view.dart';
import 'widgets/modes/slim_mode_view.dart';

import 'services/meta_service.dart';
import 'services/audio_manager.dart';
import 'services/daily_schedule_service.dart';
import 'package:video_player/video_player.dart';
import 'models/design_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(650, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      minimumSize: Size(300, 500),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setHasShadow(false);
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: ThemeData(
        brightness: Brightness.dark,
        canvasColor: Colors.transparent,
        scaffoldBackgroundColor: Colors.transparent,
        cardColor: Colors.transparent,
        dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent),
      ),
      home: const MainArea(),
    );
  }
}

class MainArea extends StatefulWidget {
  const MainArea({super.key});
  @override
  State<MainArea> createState() => _MainAreaState();
}

class _MainAreaState extends State<MainArea> with WindowListener {
  final ValueNotifier<int> _currentSecondsNotifier = ValueNotifier<int>(3600);
  final ValueNotifier<int> _counterNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> _metaPointNotifier = ValueNotifier<double>(60.0);
  final ValueNotifier<double> _focusPercentageNotifier = ValueNotifier<double>(
    0.0,
  );
  final ValueNotifier<bool> _isRunningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showMessageNotifier = ValueNotifier<bool>(false);

  int _maxSeconds = 3600;
  Timer? _timer;
  Timer? _clockTimer;
  String _glowMessage = "내가 1조부자가 않이라니, 이상하다.";
  bool _isAlarmOn = true;
  final AudioManager _audioManager = AudioManager();

  bool _showSidebar = false;
  bool _showAwarenessSidebar = false;
  // 두 사이드바가 겹칠 때 마지막으로 조작한 패널을 위에 그린다.
  bool _awarenessSidebarOnTop = false;
  String _selectedSubGoal = "";
  bool _showOverlay = false;
  String _overlayText = "";
  String _sidebarTitle = "";
  String? _sidebarFilePath;
  List<GoalItem> _sidebarGoals = [GoalItem()];
  final Map<String, int> _sidebarRunRecords = {}; // 끝장 리스트 실행 카운터 기록
  final Map<String, int> _awarenessRunRecords = {}; // 알아차림 리스트 실행 카운터 기록 (끝장 리스트와 별개)
  String _awarenessTitle = "";
  String? _awarenessFilePath;
  // 불러오기 폴더는 리스트별로 따로 기억한다 (서로 공유하지 않음)
  String? _goalLoadDirectory;
  String? _awarenessLoadDirectory;
  List<AwarenessItem> _awarenessItems = [AwarenessItem()];

  // Daily Schedule 상태
  bool _showDailyScheduleBox = false;
  List<String> _dailySchedule = List.filled(27, "");
  DateTime _currentTime = DateTime.now();

  String _bgVideoPath = "";
  double _playbackSpeed = 1.0;
  double _bgOpacity = 1.0;
  double _uiOpacity = 1.0;
  VideoPlayerController? _videoPlayerController;
  bool _isMaximized = false;

  LogicalKeyboardKey? _targetKey;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _subGoalScrollController = ScrollController();
  Timer? _messageTimer;
  DisplayMode _currentMode = DisplayMode.normal;
  List<ClockMarker> _clickMarkers = [];
  int _sessionStartTimeInSeconds = 0;
  AppThemeMode _currentThemeMode = AppThemeMode.dark;
  AppThemeData get _currentTheme => AppThemeData.getTheme(_currentThemeMode);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
    }
    _audioManager.init(_isAlarmOn);
    _currentSecondsNotifier.value = _maxSeconds;
    _startTimer();
    _startClockTimer();
    _updateBackground();
    _loadInitialMetaPoint();
    _loadDailySchedule();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    _timer?.cancel();
    _clockTimer?.cancel();
    _audioManager.dispose();
    _focusNode.dispose();
    _subGoalScrollController.dispose();
    _messageTimer?.cancel();
    _currentSecondsNotifier.dispose();
    _counterNotifier.dispose();
    _metaPointNotifier.dispose();
    _focusPercentageNotifier.dispose();
    _isRunningNotifier.dispose();
    _showMessageNotifier.dispose();
    super.dispose();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _loadDailySchedule() async {
    final list = await DailyScheduleService.loadSchedule();
    if (mounted) {
      setState(() {
        _dailySchedule = list;
      });
    }
  }

  void _openDailyScheduleDialog() async {
    final list = await DailyScheduleService.loadSchedule();
    if (!mounted) return;
    setState(() {
      _dailySchedule = list;
      _showDailyScheduleBox = true; // Daily 아이콘 누르면 상단 스케줄 박스도 자동 표시
    });
    showDialog(
      context: context,
      builder: (context) => DailyScheduleDialog(
        initialSchedule: _dailySchedule,
        theme: _currentTheme,
        onSave: (updatedList) {
          setState(() {
            _dailySchedule = updatedList;
            _showDailyScheduleBox = true;
          });
        },
      ),
    ).then((_) => _focusNode.requestFocus());
  }

  void _enforceTransparency() {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS))
      return;
    for (int delay in [100, 300, 800]) {
      Future.delayed(Duration(milliseconds: delay), () async {
        if (!mounted) return;
        await windowManager.setBackgroundColor(Colors.transparent);
        await windowManager.setHasShadow(false);
        setState(() {});
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
    _enforceTransparency();
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
    _enforceTransparency();
  }

  @override
  void onWindowResized() {
    _enforceTransparency();
  }

  @override
  void onWindowRestore() {
    setState(() => _isMaximized = false);
    _enforceTransparency();
  }

  void _loadInitialMetaPoint() async {
    final history = await MetaService.loadTodayHistory();
    if (mounted)
      _metaPointNotifier.value = MetaService.calculateCurrentPoint(history);
  }

  void _updateBackground() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    if (_bgVideoPath.isNotEmpty) {
      File file = File(_bgVideoPath);
      if (await file.exists() && _isVideoFile(_bgVideoPath)) {
        final vController = VideoPlayerController.file(file);
        try {
          await vController.initialize();
          await vController.setLooping(true);
          await vController.setVolume(_isAlarmOn ? 1.0 : 0.0);
          await vController.setPlaybackSpeed(_playbackSpeed);
          if (mounted) {
            setState(() {
              _videoPlayerController = vController;
            });
            await vController.play();
          }
        } catch (e) {
          debugPrint("로드 에러: $e");
        }
      }
    }
  }

  bool _isVideoFile(String path) => [
    '.mp4',
    '.mov',
    '.avi',
    '.wmv',
    '.mkv',
  ].any((ext) => path.toLowerCase().endsWith(ext));

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_isRunningNotifier.value && _currentSecondsNotifier.value > 0) {
        _currentSecondsNotifier.value--;
        if (_currentSecondsNotifier.value == 300)
          _audioManager.playAlarm("1test.mp3");
      } else if (_isRunningNotifier.value) {
        _isRunningNotifier.value = false;
        _audioManager.playAlarm("1test.mp3");
        _finalizeAndSync();
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _finalizeAndSync() async {
    await MetaService.finalizeSession(
      _counterNotifier.value,
      _metaPointNotifier.value,
    );
    final results = await MetaService.recalculateToday();
    if (mounted) {
      _metaPointNotifier.value = results['meta'] ?? 60.0;
      _focusPercentageNotifier.value =
          ((results['focusIncrease'] ?? 0.0) / _maxSeconds * 100).clamp(
            0.0,
            100.0,
          );
    }
  }

  void _incrementCounter() {
    if (!_isRunningNotifier.value) return;
    final newMarker = ClockMarker(
      count: _counterNotifier.value + 1,
      position: (_maxSeconds - _currentSecondsNotifier.value) / _maxSeconds,
      timeSeconds: _currentSecondsNotifier.value,
    );
    setState(() => _clickMarkers = [..._clickMarkers, newMarker]);
    if (_counterNotifier.value < 999) _counterNotifier.value++;
    MetaService.saveDailyLog(_counterNotifier.value, "XP", 0).then((_) async {
      final h = await MetaService.loadTodayHistory();
      if (mounted)
        _metaPointNotifier.value = MetaService.calculateCurrentPoint(h);
    });
    if (_glowMessage.isNotEmpty) {
      _showMessageNotifier.value = true;
      _messageTimer?.cancel();
      _messageTimer = Timer(
        const Duration(seconds: 2),
        () => _showMessageNotifier.value = false,
      );
    }
  }

  void _showTimeEditDialog() {
    bool wasRunning = _isRunningNotifier.value;
    _isRunningNotifier.value = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SettingsDialog(
        initialMaxSeconds: _maxSeconds,
        initialGlowMessage: _glowMessage,
        initialIsAlarmOn: _isAlarmOn,
        initialBgVideoPath: _bgVideoPath,
        initialPlaybackSpeed: _playbackSpeed,
        initialBgOpacity: _bgOpacity,
        initialUiOpacity: _uiOpacity,
        initialTargetKey: _targetKey,
        onApply:
            ({
              newSeconds,
              newMessage,
              newAlarm,
              newPath,
              newSpeed,
              newBgOpacity,
              newUiOpacity,
              newKey,
            }) {
              setState(() {
                if (newSeconds != null) {
                  _maxSeconds = newSeconds;
                  _currentSecondsNotifier.value = _maxSeconds;
                }
                if (newMessage != null) _glowMessage = newMessage;
                if (newAlarm != null) {
                  _isAlarmOn = newAlarm;
                  _audioManager.toggleSound(_isAlarmOn);
                }
                if (newPath != null) {
                  _bgVideoPath = newPath;
                  _updateBackground();
                }
                if (newSpeed != null) {
                  _playbackSpeed = newSpeed;
                  if (_videoPlayerController != null)
                    _videoPlayerController!.setPlaybackSpeed(newSpeed);
                }
                if (newBgOpacity != null) _bgOpacity = newBgOpacity;
                if (newUiOpacity != null) _uiOpacity = newUiOpacity;
                if (newKey != null) _targetKey = newKey;
                _isRunningNotifier.value = wasRunning;
              });
            },
      ),
    ).then((_) => _focusNode.requestFocus());
  }

  void _openVirtualNotepad() async {
    if (kIsWeb || !Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모바일에서는 시스템 메모장 실행이 제한됩니다.")),
      );
      return;
    }
    try {
      await Process.start('notepad.exe', []);
    } catch (e) {
      debugPrint("실행 에러: $e");
    }
  }

  void _toggleVideoSound() {
    setState(() {
      _isAlarmOn = !_isAlarmOn;
      _audioManager.toggleSound(_isAlarmOn);
      if (_videoPlayerController != null)
        _videoPlayerController!.setVolume(_isAlarmOn ? 1.0 : 0.0);
    });
  }

  void _resetTimer() {
    _currentSecondsNotifier.value = _maxSeconds;
    _isRunningNotifier.value = false;
    setState(() => _clickMarkers = []);
    _finalizeAndSync();
  }

  void _resetCounter() {
    _counterNotifier.value = 0;
    setState(() => _clickMarkers = []);
    _finalizeAndSync();
  }

  void _toggleDisplayMode() {
    setState(() {
      _currentMode = DisplayMode
          .values[(_currentMode.index + 1) % DisplayMode.values.length];
      if (_currentMode == DisplayMode.slim)
        _sessionStartTimeInSeconds = _currentSecondsNotifier.value;
    });
  }

  void _toggleTheme() {
    setState(
      () => _currentThemeMode = AppThemeMode
          .values[(_currentThemeMode.index + 1) % AppThemeMode.values.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double aspectRatio =
        MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    final Size screenSize = MediaQuery.of(context).size;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == _targetKey) {
          _incrementCounter();
          setState(() {
            _overlayText = _glowMessage.isNotEmpty
                ? _glowMessage
                : _targetKey!.keyLabel.toUpperCase();
            _showOverlay = true;
          });
          Future.delayed(
            const Duration(milliseconds: 800),
            () => setState(() => _showOverlay = false),
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                BackgroundEngine(
                  key: ValueKey("bg_${_isMaximized}_$_bgVideoPath"),
                  bgVideoPath: _bgVideoPath,
                  bgOpacity: _bgOpacity,
                  videoPlayerController: _videoPlayerController,
                  backgroundColor: _currentTheme.backgroundColor,
                ),
                SafeArea(
                  child: Column(
                    children: [
                      SizedBox(
                        height:
                            ((screenSize.height * 0.24).clamp(85.0, 160.0) +
                            (_showDailyScheduleBox ? 112.0 : 0.0)),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _buildModeContent(constraints),
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _currentSecondsNotifier,
                        builder: (context, seconds, _) =>
                            ValueListenableBuilder<bool>(
                              valueListenable: _isRunningNotifier,
                              builder: (context, isRunning, _) {
                                if (_currentMode == DisplayMode.slim &&
                                    (_sessionStartTimeInSeconds - seconds >=
                                        60) &&
                                    isRunning) {
                                  return const SizedBox.shrink();
                                }
                                return SetGroup(
                                  isRunning: isRunning,
                                  onToggle: () {
                                    if (seconds <= 0) {
                                      _currentSecondsNotifier.value =
                                          _maxSeconds;
                                      setState(() => _clickMarkers = []);
                                    }
                                    _isRunningNotifier.value =
                                        !_isRunningNotifier.value;
                                    if (!_isRunningNotifier.value)
                                      _finalizeAndSync();
                                  },
                                  onReset: _resetTimer,
                                  isAlarmOn: _isAlarmOn,
                                  onToggleSound: _toggleVideoSound,
                                  theme: _currentTheme,
                                  screenMaxHeight: constraints.maxHeight,
                                  screenMaxWidth: constraints.maxWidth,
                                );
                              },
                            ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.02),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: TopBar(
                      onDailyPressed: _openDailyScheduleDialog,
                      onMemoPressed: _openVirtualNotepad,
                      onToggleSiderbar: () => setState(() {
                        _showSidebar = !_showSidebar;
                        if (_showSidebar) {
                          _awarenessSidebarOnTop = false;
                        }
                      }),
                      onToggleAwarenessSidebar: () => setState(() {
                        _showAwarenessSidebar = !_showAwarenessSidebar;
                        if (_showAwarenessSidebar) {
                          _awarenessSidebarOnTop = true;
                        }
                      }),
                      onSettingsPressed: _showTimeEditDialog,
                      onToggleTheme: _toggleTheme,
                      selectedSubGoal: _selectedSubGoal,
                      sidebarGoals: _sidebarGoals,
                      scrollController: _subGoalScrollController,
                      maxWidth: screenSize.width,
                      maxHeight: screenSize.height,
                      onClose: () => setState(() => _selectedSubGoal = ""),
                      onToggleDisplayMode: _toggleDisplayMode,
                      currentModeName: _currentMode.name,
                      theme: _currentTheme,
                      sidebarTitle: _sidebarTitle,
                      showDailyScheduleBox: _showDailyScheduleBox,
                      dailySchedule: _dailySchedule,
                      currentTime: _currentTime,
                      onCloseDailyScheduleBox: () =>
                          setState(() => _showDailyScheduleBox = false),
                      onOpenDailyScheduleEditor: _openDailyScheduleDialog,
                    ),
                  ),
                ),
                // 겹칠 때 마지막으로 조작한 패널이 위에 보이도록 나중에 그린다.
                if (_awarenessSidebarOnTop) ...[
                  if (_showSidebar) _buildGoalSidebar(),
                  if (_showAwarenessSidebar) _buildAwarenessSidebar(),
                ] else ...[
                  if (_showAwarenessSidebar) _buildAwarenessSidebar(),
                  if (_showSidebar) _buildGoalSidebar(),
                ],
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 4000),
                      opacity: _showOverlay ? 1.0 : 0.0,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          _overlayText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: aspectRatio * 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              const Shadow(blurRadius: 10, color: Colors.black),
                              Shadow(
                                blurRadius: 30,
                                color: Colors.blueAccent.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoalSidebar() {
    // 순서가 바뀌어도 패널 상태(입력 중인 내용)가 유지되도록 고정 key를 쓴다.
    return Positioned(
      key: const ValueKey('goalSidebar'),
      top: 0,
      right: 0,
      bottom: 0,
      child: GoalListSidebar(
        onBringToFront: () {
          if (_awarenessSidebarOnTop) {
            setState(() => _awarenessSidebarOnTop = false);
          }
        },
        runRecords: _sidebarRunRecords,
        onRunRecordsChanged: () => setState(() {}),
        initialTitle: _sidebarTitle,
        initialGoals: _sidebarGoals,
        initialFilePath: _sidebarFilePath,
        onTitleChanged: (v) => setState(() => _sidebarTitle = v),
        onGoalsChanged: (v) => _sidebarGoals = v,
        onFilePathChanged: (v) => _sidebarFilePath = v,
        loadDirectory: _goalLoadDirectory,
        onLoadDirectoryChanged: (v) => _goalLoadDirectory = v,
        onSelectGoal: (g) {
          setState(() => _selectedSubGoal = (_selectedSubGoal == g) ? "" : g);
        },
        onDeleteGoal: (goal) {
          if (_selectedSubGoal == goal) setState(() => _selectedSubGoal = "");
        },
        onClose: () => setState(() => _showSidebar = false),
      ),
    );
  }

  Widget _buildAwarenessSidebar() {
    return Positioned(
      key: const ValueKey('awarenessSidebar'),
      top: 0,
      left: 0,
      bottom: 0,
      child: AwarenessListSidebar(
        onBringToFront: () {
          if (!_awarenessSidebarOnTop) {
            setState(() => _awarenessSidebarOnTop = true);
          }
        },
        runRecords: _awarenessRunRecords,
        onRunRecordsChanged: () => setState(() {}),
        initialTitle: _awarenessTitle,
        initialItems: _awarenessItems,
        initialFilePath: _awarenessFilePath,
        onTitleChanged: (v) => _awarenessTitle = v,
        onItemsChanged: (v) => _awarenessItems = v,
        onFilePathChanged: (v) => _awarenessFilePath = v,
        loadDirectory: _awarenessLoadDirectory,
        onLoadDirectoryChanged: (v) => _awarenessLoadDirectory = v,
        onClose: () => setState(() => _showAwarenessSidebar = false),
      ),
    );
  }

  Widget _buildModeContent(BoxConstraints constraints) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentSecondsNotifier,
      builder: (context, seconds, _) => ValueListenableBuilder<bool>(
        valueListenable: _isRunningNotifier,
        builder: (context, isRunning, _) => ValueListenableBuilder<bool>(
          valueListenable: _showMessageNotifier,
          builder: (context, showMsg, _) {
            final viewProps = {
              'timeString': _formatDuration(seconds),
              'isRunning': isRunning,
              'progress': (seconds / _maxSeconds).clamp(0.0, 1.0),
              'glowMessage': _glowMessage,
              'showMessage': showMsg,
              'theme': _currentTheme,
            };
            if (_currentMode == DisplayMode.slim &&
                (_sessionStartTimeInSeconds - seconds >= 60) &&
                isRunning) {
              return ValueListenableBuilder<int>(
                valueListenable: _counterNotifier,
                builder: (context, counter, _) => SlimModeView(
                  counter: counter,
                  onIncrement: _incrementCounter,
                  onReset: _resetCounter,
                  theme: _currentTheme,
                  opacity: _uiOpacity,
                  isAlarmOn: _isAlarmOn,
                  onToggleSound: _toggleVideoSound,
                ),
              );
            }
            switch (_currentMode) {
              case DisplayMode.normal:
              case DisplayMode.slim:
                return NormalModeView(
                  timeString: viewProps['timeString'] as String,
                  isRunning: viewProps['isRunning'] as bool,
                  progress: viewProps['progress'] as double,
                  glowMessage: viewProps['glowMessage'] as String,
                  showMessage: viewProps['showMessage'] as bool,
                  theme: viewProps['theme'] as AppThemeData,
                );
              case DisplayMode.infoBar:
                return InfoBarModeView(
                  infoBar: ValueListenableBuilder<int>(
                    valueListenable: _counterNotifier,
                    builder: (context, c, _) => InfoBar(
                      counter: c,
                      metaPoint: _metaPointNotifier.value,
                      focusPercentage: _focusPercentageNotifier.value,
                      onReset: _resetCounter,
                      theme: _currentTheme,
                    ),
                  ),
                  timeString: viewProps['timeString'] as String,
                  isRunning: viewProps['isRunning'] as bool,
                  progress: viewProps['progress'] as double,
                  glowMessage: viewProps['glowMessage'] as String,
                  showMessage: viewProps['showMessage'] as bool,
                  theme: viewProps['theme'] as AppThemeData,
                );
              case DisplayMode.timeline:
                return TimelineModeView(
                  totalSeconds: _maxSeconds,
                  currentSeconds: seconds,
                  markers: _clickMarkers,
                  timeString: viewProps['timeString'] as String,
                  isRunning: viewProps['isRunning'] as bool,
                  progress: viewProps['progress'] as double,
                  glowMessage: viewProps['glowMessage'] as String,
                  showMessage: viewProps['showMessage'] as bool,
                  onReset: _resetCounter,
                  theme: _currentTheme,
                );
            }
          },
        ),
      ),
    );
  }
}

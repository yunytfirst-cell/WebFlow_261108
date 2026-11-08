import 'package:flutter/material.dart';
import 'goal_list_sidebar.dart';
import 'clay_button.dart';
import '../models/design_theme.dart';
import 'top_bar_ticker.dart';
import 'goal_title_display.dart';
import 'daily_schedule_box.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onDailyPressed;
  final VoidCallback? onMemoPressed;
  final VoidCallback? onToggleSiderbar;
  final VoidCallback? onToggleAwarenessSidebar;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onToggleTheme;
  final String selectedSubGoal;
  final List<GoalItem> sidebarGoals;
  final ScrollController scrollController;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback onClose;
  final VoidCallback onToggleDisplayMode;
  final String currentModeName;
  final AppThemeData theme;
  final String sidebarTitle;

  // Daily Schedule Box 관련 속성
  final bool showDailyScheduleBox;
  final List<String> dailySchedule;
  final DateTime currentTime;
  final VoidCallback? onCloseDailyScheduleBox;
  final VoidCallback? onOpenDailyScheduleEditor;

  const TopBar({
    super.key,
    this.onDailyPressed,
    this.onMemoPressed,
    this.onToggleSiderbar,
    this.onToggleAwarenessSidebar,
    this.onSettingsPressed,
    this.onToggleTheme,
    required this.selectedSubGoal,
    required this.sidebarGoals,
    required this.scrollController,
    required this.maxWidth,
    required this.maxHeight,
    required this.onClose,
    required this.onToggleDisplayMode,
    required this.currentModeName,
    required this.theme,
    this.sidebarTitle = "오늘의 스케줄",
    this.showDailyScheduleBox = false,
    this.dailySchedule = const [],
    required this.currentTime,
    this.onCloseDailyScheduleBox,
    this.onOpenDailyScheduleEditor,
  });

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        (maxHeight * 0.25).clamp(90.0, 165.0) + (showDailyScheduleBox ? 112.0 : 0.0),
      );
}

class _TopBarState extends State<TopBar> {
  int _currIndex = 0;
  bool _showInitialMessage = true;
  List<Map<String, dynamic>>? _cachedFlattenedLines;

  // 설정값
  final double _tickerFontSizeRatio = 0.35;
  final double _tickerBarHeightRatio = 1.5;

  double _getTickerFontSize() {
    const double minBarHeight = 60.0;
    const double maxBarHeight = 120.0;
    final double containerHeight = (widget.maxHeight * 0.2).clamp(minBarHeight, maxBarHeight).floorToDouble();
    final double containerWidth = (widget.maxWidth - 40).clamp(200.0, 800.0).floorToDouble();
    double refSize = containerWidth < containerHeight ? containerWidth : containerHeight;
    return refSize * 0.55 * _tickerFontSizeRatio;
  }

  double _getTickerBarHeight() => _getTickerFontSize() * _tickerBarHeightRatio;

  // 하단 아이콘 행의 실측 원본 폭 계산 (확대/축소 시 스케줄 박스가 아이콘 범위를 절대 넘지 않도록 제한)
  double _calculateUnscaledIconsRowWidth(double buttonSize, String modeName) {
    final double rectPadding = 44.0;
    final double iconOnlyRect = buttonSize * 0.45 + rectPadding; // Daily, Awareness, Theme
    final double modeTextWidth = modeName.length * (buttonSize * 0.20);
    final double modeRect = buttonSize * 0.45 + 10.0 + modeTextWidth + rectPadding; // Mode
    final double circleButtons = buttonSize * 3.0; // Memo, Sidebar, Settings

    const double gaps = (12.0 * 5) + 30.0; // 아이콘 간격 5개(각 12px) + 좌우 그룹 간격(30px)

    return (iconOnlyRect * 3 + modeRect + circleButtons + gaps).floorToDouble();
  }

  void _updateFlattenedLines() {
    List<Map<String, dynamic>> lines = [];
    for (int i = 0; i < widget.sidebarGoals.length; i++) {
      final goal = widget.sidebarGoals[i];
      final splitText = goal.text.trim().split('\n');
      for (int j = 0; j < splitText.length; j++) {
        if (splitText[j].trim().isEmpty) continue;
        lines.add({
          'mainIdx': i + 1,
          'subIdx': splitText.length > 1 ? j + 1 : null,
          'text': splitText[j].trim(),
          'fullOriginal': goal.text.trim(),
        });
      }
    }
    _cachedFlattenedLines = lines;
  }

  List<Map<String, dynamic>> get _flattenedLines {
    if (_cachedFlattenedLines == null) _updateFlattenedLines();
    return _cachedFlattenedLines!;
  }

  @override
  void initState() {
    super.initState();
    _updateFlattenedLines();
    _updateIndexFromSelected(forceShowList: false);
  }

  @override
  void didUpdateWidget(TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sidebarGoals != widget.sidebarGoals) setState(() => _updateFlattenedLines());
    if (oldWidget.selectedSubGoal != widget.selectedSubGoal) _updateIndexFromSelected(forceShowList: widget.selectedSubGoal.isNotEmpty);
    if (oldWidget.maxHeight != widget.maxHeight || oldWidget.maxWidth != widget.maxWidth) _scrollToIndex();
  }

  void _updateIndexFromSelected({bool forceShowList = true}) {
    _updateFlattenedLines();
    final lines = _flattenedLines;
    if (widget.selectedSubGoal.isEmpty) { setState(() => _showInitialMessage = true); return; }
    final searchTerm = widget.selectedSubGoal.replaceAll('...', '').trim().toLowerCase();
    int idx = lines.indexWhere((l) {
      final fullText = l['fullOriginal'].toString().toLowerCase();
      final lineText = l['text'].toString().toLowerCase();
      return fullText.contains(searchTerm) || lineText.contains(searchTerm);
    });
    if (idx >= 0) {
      setState(() { _currIndex = idx; if (forceShowList) _showInitialMessage = false; });
      _scrollToIndex();
    } else if (lines.isNotEmpty) {
      setState(() { _currIndex = 0; if (forceShowList) _showInitialMessage = false; });
      _scrollToIndex();
    } else {
      setState(() => _showInitialMessage = true);
    }
  }

  void _scrollToIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(_currIndex * _getTickerBarHeight());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double containerHeight = widget.preferredSize.height;
    final double containerWidth = (widget.maxWidth - 40).clamp(200.0, 800.0).floorToDouble();
    final double tickerWidth = (widget.maxWidth - 120).clamp(180.0, 700.0).floorToDouble();
    final double totalAreaWidth = widget.maxWidth;
    double refSize = containerWidth < containerHeight ? containerWidth : containerHeight;
    
    final double unifiedFontSize = refSize * 0.28;
    final double tickerFontSize = _getTickerFontSize();

    // 하단 아이콘 행의 실측 원본 폭 계산
    final double unscaledIconsWidth = _calculateUnscaledIconsRowWidth(unifiedFontSize, widget.currentModeName);
    
    // 스케줄 박스와 아이콘 행이 완벽히 동일한 영역 폭을 공유하도록 매칭 (절대 스케줄 박스가 더 크지 않음)
    final double targetWidth = containerWidth < unscaledIconsWidth ? containerWidth : unscaledIconsWidth;

    // 스케줄 박스 상하 여백 (상단 24px, 박스 76px, 하단 12px 간격)
    final double buttonRowTop = widget.showDailyScheduleBox ? 112.0 : 2.0;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: containerHeight,
      automaticallyImplyLeading: false,
      title: Center(
        child: SizedBox(
          width: totalAreaWidth,
          height: containerHeight,
          child: Stack(
            children: [
              // 0. Daily Schedule 표시 영역 (아이콘 행과 targetWidth 동일하게 맞춤)
              if (widget.showDailyScheduleBox)
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: targetWidth,
                      child: DailyScheduleBox(
                        schedule24h: widget.dailySchedule,
                        currentTime: widget.currentTime,
                        theme: widget.theme,
                        onClose: widget.onCloseDailyScheduleBox ?? () {},
                        onOpenEditor: widget.onOpenDailyScheduleEditor,
                        width: targetWidth,
                      ),
                    ),
                  ),
                ),

              // 1. 아이콘 버튼들 (Daily Schedule 박스와 정확히 동일한 targetWidth 내에 배치하여 완벽 좌우 정렬)
              Positioned(
                top: buttonRowTop,
                right: 0,
                left: 0,
                child: Center(
                  child: SizedBox(
                    width: targetWidth,
                    height: (widget.maxHeight * 0.25).clamp(90.0, 165.0) * 0.35,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Daily 아이콘 (좌측 가장 끝)
                              ClayButton(
                                icon: Icons.calendar_today_rounded,
                                onPressed: widget.onDailyPressed,
                                tooltip: "Daily 스케줄",
                                size: unifiedFontSize,
                                baseColor: widget.theme.accentColor,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.psychology_outlined,
                                onPressed: widget.onToggleAwarenessSidebar,
                                tooltip: "알아차림",
                                size: unifiedFontSize,
                                baseColor: widget.theme.primaryColor,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.dashboard_customize,
                                label: widget.currentModeName.toUpperCase(),
                                onPressed: widget.onToggleDisplayMode,
                                size: unifiedFontSize,
                                baseColor: widget.theme.backgroundColor,
                                textColor: widget.theme.textColor,
                              ),
                            ],
                          ),
                          const SizedBox(width: 30),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClayButton(
                                icon: Icons.palette_outlined,
                                onPressed: widget.onToggleTheme,
                                tooltip: "테마",
                                size: unifiedFontSize,
                                baseColor: widget.theme.accentColor,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.edit,
                                onPressed: widget.onMemoPressed,
                                tooltip: "메모장",
                                size: unifiedFontSize,
                                baseColor: widget.theme.primaryColor,
                                isCircle: true,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.app_registration_rounded,
                                onPressed: widget.onToggleSiderbar,
                                tooltip: "끝장 리스트",
                                size: unifiedFontSize,
                                baseColor: widget.theme.backgroundColor,
                                isCircle: true,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              // 설정 아이콘 (우측 가장 끝)
                              ClayButton(
                                icon: Icons.settings_suggest_rounded,
                                onPressed: widget.onSettingsPressed,
                                tooltip: "설정",
                                size: unifiedFontSize,
                                baseColor: widget.theme.accentColor,
                                isCircle: true,
                                textColor: widget.theme.textColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. [별도 파일 관리] 상단 1층: 목표 제목 표시 영역
              Positioned(
                bottom: _getTickerBarHeight() + 10,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: tickerWidth,
                    child: GoalTitleDisplay(
                      title: widget.sidebarTitle,
                      fontSize: tickerFontSize,
                      theme: widget.theme,
                      width: tickerWidth,
                    ),
                  ),
                ),
              ),

              // 3. [완전 고정] 상단 2층: 티커
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Container(
                  height: _getTickerBarHeight(),
                  alignment: Alignment.center,
                  child: TopBarTicker(
                    lines: _flattenedLines,
                    currIndex: _currIndex,
                    scrollController: widget.scrollController,
                    rowHeight: _getTickerBarHeight(),
                    columnWidth: tickerWidth,
                    fontSize: tickerFontSize,
                    theme: widget.theme,
                    showInitialMessage: _showInitialMessage,
                    onResetIndex: () {
                      setState(() => _showInitialMessage = true);
                      widget.onClose();
                    },
                    onUpdateIndex: (newIdx) {
                      setState(() => _currIndex = newIdx);
                      _scrollToIndex();
                    },
                    maxWidth: widget.maxWidth,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

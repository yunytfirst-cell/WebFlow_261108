import 'package:flutter/material.dart';
import 'list_sidebar.dart';
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
  final List<ListSidebarItem> sidebarGoals; // 메인에 보낸 항목이 속한 리스트(끝장 또는 알아차림)
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

  /// 2026-11-24 사용자 지시: 컨트롤 아이콘 행 위쪽 여백(창 위 끝에 붙어 보기 불편했음).
  /// main.dart의 본문 시작 높이도 이만큼 더 내린다.
  static const double topGap = 24.0;

  @override
  Size get preferredSize => Size.fromHeight(
        topGap + (maxHeight * 0.25).clamp(90.0, 165.0) + (showDailyScheduleBox ? 112.0 : 0.0),
      );
}

class _TopBarState extends State<TopBar> {
  int _currIndex = 0;

  // 2026-11-24 사용자 지시: Daily 앞 "+" 버튼으로 상단 컨트롤 아이콘들을 접고 펼친다 (앱 실행 중에만 기억)
  bool _controlsExpanded = true;

  // 2026-11-24 사용자 지시: 상단 컨트롤 아이콘은 예전 크기의 2/3, 모드·테마 사이 간격은 예전(30)의 2배 이상
  static const double _iconScale = 2 / 3;
  static const double _modeThemeGap = 70.0;

  // 2026-11-24 사용자 지시: 목표 제목·티커(목표바)의 시작은 "−/+" 버튼 왼쪽 끝, 끝은 설정 아이콘 오른쪽 끝에 맞춘다.
  // 아이콘 행은 FittedBox로 줄어들 수 있어 계산 대신 그린 뒤 실제 위치를 잰다(펼친 상태일 때만 갱신).
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _iconsRowKey = GlobalKey();
  double? _barLeft;
  double? _barWidth;
  // 아이콘 행(FittedBox로 줄어든 실제 모습)의 아래 끝. 목표 박스를 이 아래 간격의 1/2 위치로 올린다.
  double? _rowBottom;

  // 2026-11-24 사용자 지적 "− 누르면 + 버튼 위치가 바뀐다": 예전엔 접을 때 버튼을 트리에서 빼서
  // 행 폭·FittedBox 축소 비율이 달라져 + 위치·크기가 변했다. 이제 숨긴 버튼도 자리를 그대로 차지하게
  // (보이지 않고 눌리지 않게) 두어 + 버튼과 목표바·Daily 표시바 위치가 그대로 유지된다.
  List<Widget> _keepPlaceWhenCollapsed(List<Widget> children) => [
        for (final child in children)
          Visibility(
            visible: _controlsExpanded,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: child,
          ),
      ];

  void _measureIconsRow() {
    if (!mounted) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final rowBox = _iconsRowKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || rowBox == null || !rowBox.hasSize) return;
    final left = rowBox.localToGlobal(Offset.zero, ancestor: stackBox).dx;
    final right = rowBox.localToGlobal(Offset(rowBox.size.width, 0), ancestor: stackBox).dx;
    final width = right - left;
    final bottom = rowBox.localToGlobal(Offset(0, rowBox.size.height), ancestor: stackBox).dy;
    if (_barLeft == null ||
        (left - _barLeft!).abs() > 0.5 ||
        (width - _barWidth!).abs() > 0.5 ||
        _rowBottom == null ||
        (bottom - _rowBottom!).abs() > 0.5) {
      setState(() {
        _barLeft = left;
        _barWidth = width;
        _rowBottom = bottom;
      });
    }
  }
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
    final double base = refSize * 0.55 * _tickerFontSizeRatio;
    // 2026-11-24 사용자 지시 "목표바 안의 글자도 오토레이아웃": 목표바 폭이 좁으면 글자도 줄인다(최소 11).
    if (_barWidth == null) return base;
    return (_barWidth! * 0.045).clamp(11.0, base);
  }

  double _getTickerBarHeight() => _getTickerFontSize() * _tickerBarHeightRatio;

  /// 목표 박스의 bottom 값. 예전 자리(티커 바로 위 10)에서 아이콘 행과의 간격을
  /// 1/2로 줄이도록 위로 올린다 (2026-11-25 사용자 지시 "상단바와 목표 박스 간격 1/2, STEP 박스는 그대로").
  double _goalTitleBottom(double containerHeight) {
    final double tickerH = _getTickerBarHeight();
    final double oldBottom = tickerH + 10;
    if (_rowBottom == null) return oldBottom;
    // 목표 박스 높이 = 티커 줄 높이(fontSize * 1.5)
    final double oldTop = containerHeight - oldBottom - tickerH;
    final double gap = oldTop - _rowBottom!;
    if (gap <= 0) return oldBottom;
    return oldBottom + gap * goalGapRatio;
  }

  /// 아이콘 행~목표 박스 간격을 줄이는 비율 (줄인 만큼 위로 올림)
  static const double goalGapRatio = 0.5;

  // 하단 아이콘 행의 실측 원본 폭 계산 (확대/축소 시 스케줄 박스가 아이콘 범위를 절대 넘지 않도록 제한)
  double _calculateUnscaledIconsRowWidth(double buttonSize, String modeName) {
    final double rectPadding = 44.0;
    final double iconOnlyRect = buttonSize * 0.45 + rectPadding; // Daily, Awareness, Theme
    final double modeTextWidth = modeName.length * (buttonSize * 0.20);
    final double modeRect = buttonSize * 0.45 + 10.0 + modeTextWidth + rectPadding; // Mode
    final double circleButtons = buttonSize * 3.0; // Memo, Sidebar, Settings

    // 아이콘 간격 6개(각 12px, + 버튼 포함) + 모드·테마 사이 간격 + 접기(+) 버튼
    const double gaps = (12.0 * 6) + _modeThemeGap;
    final double toggleRect = buttonSize * 0.45 + rectPadding;

    return (iconOnlyRect * 3 + modeRect + circleButtons + gaps + toggleRect)
        .floorToDouble();
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
    // 목표바 폭·시작 위치: 아이콘 행을 잰 값(없으면 예전처럼 가운데 고정 폭)
    final double tickerWidth = _barWidth ?? (widget.maxWidth - 120).clamp(180.0, 700.0).floorToDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureIconsRow());
    final double totalAreaWidth = widget.maxWidth;
    double refSize = containerWidth < containerHeight ? containerWidth : containerHeight;

    final double unifiedFontSize = refSize * 0.28;
    final double tickerFontSize = _getTickerFontSize();

    // 하단 아이콘 행의 실측 원본 폭 계산
    final double unscaledIconsWidth = _calculateUnscaledIconsRowWidth(unifiedFontSize, widget.currentModeName);

    // 스케줄 박스 폭은 예전 아이콘 크기 기준을 유지한다 (아이콘만 2/3로 줄임)
    final double targetWidth = containerWidth < unscaledIconsWidth ? containerWidth : unscaledIconsWidth;

    // 아이콘 행은 2/3 크기로 그린다
    final double iconSize = unifiedFontSize * _iconScale;
    final double iconsRowWidth = _calculateUnscaledIconsRowWidth(iconSize, widget.currentModeName);
    final double iconsTargetWidth = containerWidth < iconsRowWidth ? containerWidth : iconsRowWidth;

    // 스케줄 박스 상하 여백 (상단 24px, 박스 76px, 하단 12px 간격)
    final double buttonRowTop = TopBar.topGap + (widget.showDailyScheduleBox ? 112.0 : 2.0);

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
            key: _stackKey,
            children: [
              // 0. Daily Schedule 표시 영역 (아이콘 행과 targetWidth 동일하게 맞춤)
              if (widget.showDailyScheduleBox)
                // 2026-11-24 사용자 지시: Daily 스케줄 표시바도 −/+ 버튼 왼쪽 끝 ~ 설정 아이콘 오른쪽 끝에 맞춘다
                // (아이콘 행을 잰 _barLeft/_barWidth, 재기 전 첫 프레임은 예전처럼 targetWidth 가운데)
                Positioned(
                  top: TopBar.topGap + 24,
                  left: _barLeft ?? (totalAreaWidth - targetWidth) / 2,
                  width: _barWidth ?? targetWidth,
                  child: DailyScheduleBox(
                    schedule24h: widget.dailySchedule,
                    currentTime: widget.currentTime,
                    theme: widget.theme,
                    onClose: widget.onCloseDailyScheduleBox ?? () {},
                    onOpenEditor: widget.onOpenDailyScheduleEditor,
                    width: _barWidth ?? targetWidth,
                  ),
                ),

              // 1. 아이콘 버튼들 (Daily Schedule 박스와 정확히 동일한 targetWidth 내에 배치하여 완벽 좌우 정렬)
              Positioned(
                top: buttonRowTop,
                right: 0,
                left: 0,
                child: Center(
                  child: SizedBox(
                    width: iconsTargetWidth,
                    height: (widget.maxHeight * 0.25).clamp(90.0, 165.0) * 0.35 * _iconScale,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      // 접으면 + 버튼만 남으므로 왼쪽에 붙인다
                      alignment: Alignment.center,
                      child: Row(
                        key: _iconsRowKey,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 컨트롤 접기/펼치기 (+) — Daily 아이콘 앞
                              ClayButton(
                                icon: _controlsExpanded ? Icons.remove : Icons.add,
                                onPressed: () => setState(() => _controlsExpanded = !_controlsExpanded),
                                tooltip: _controlsExpanded ? "컨트롤 접기" : "컨트롤 펼치기",
                                size: iconSize,
                                baseColor: widget.theme.primaryColor,
                                textColor: widget.theme.textColor,
                              ),
                              ..._keepPlaceWhenCollapsed([
                              const SizedBox(width: 12),
                              // Daily 아이콘
                              ClayButton(
                                icon: Icons.calendar_today_rounded,
                                onPressed: widget.onDailyPressed,
                                tooltip: "Daily 스케줄",
                                size: iconSize,
                                baseColor: widget.theme.accentColor,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.psychology_outlined,
                                onPressed: widget.onToggleAwarenessSidebar,
                                tooltip: "알아차림",
                                size: iconSize,
                                baseColor: widget.theme.primaryColor,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.dashboard_customize,
                                label: widget.currentModeName.toUpperCase(),
                                onPressed: widget.onToggleDisplayMode,
                                size: iconSize,
                                baseColor: widget.theme.backgroundColor,
                                textColor: widget.theme.textColor,
                              ),
                              ]),
                            ],
                          ),
                          ..._keepPlaceWhenCollapsed([
                          const SizedBox(width: _modeThemeGap),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClayButton(
                                icon: Icons.palette_outlined,
                                onPressed: widget.onToggleTheme,
                                tooltip: "테마: ${widget.theme.name}",
                                size: iconSize,
                                baseColor: widget.theme.accentColor,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.edit,
                                onPressed: widget.onMemoPressed,
                                tooltip: "메모장",
                                size: iconSize,
                                baseColor: widget.theme.primaryColor,
                                isCircle: true,
                                textColor: widget.theme.textColor,
                              ),
                              const SizedBox(width: 12),
                              ClayButton(
                                icon: Icons.app_registration_rounded,
                                onPressed: widget.onToggleSiderbar,
                                tooltip: "끝장 리스트",
                                size: iconSize,
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
                                size: iconSize,
                                baseColor: widget.theme.accentColor,
                                isCircle: true,
                                textColor: widget.theme.textColor,
                              ),
                            ],
                          ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. [별도 파일 관리] 상단 1층: 목표 제목 표시 영역
              Positioned(
                bottom: _goalTitleBottom(containerHeight),
                left: _barLeft ?? (totalAreaWidth - tickerWidth) / 2,
                width: tickerWidth,
                child: GoalTitleDisplay(
                  title: widget.sidebarTitle,
                  active: !_showInitialMessage,
                  fontSize: tickerFontSize,
                  theme: widget.theme,
                  width: tickerWidth,
                ),
              ),

              // 3. [완전 고정] 상단 2층: 티커
              Positioned(
                bottom: 2,
                left: _barLeft ?? (totalAreaWidth - tickerWidth) / 2,
                width: tickerWidth,
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
                    // 폭은 columnWidth(아이콘 행에 맞춘 값)를 그대로 쓴다
                    maxWidth: null,
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

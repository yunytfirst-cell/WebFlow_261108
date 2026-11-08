import 'package:flutter/material.dart';
import '../models/design_theme.dart';
import '../services/daily_schedule_service.dart';

class DailyScheduleDialog extends StatefulWidget {
  final List<String> initialSchedule;
  final AppThemeData theme;
  final ValueChanged<List<String>> onSave;

  const DailyScheduleDialog({
    super.key,
    required this.initialSchedule,
    required this.theme,
    required this.onSave,
  });

  @override
  State<DailyScheduleDialog> createState() => _DailyScheduleDialogState();
}

class _DailyScheduleDialogState extends State<DailyScheduleDialog> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  final ScrollController _scrollController = ScrollController();
  int _currentHour = DateTime.now().hour;

  @override
  void initState() {
    super.initState();
    _currentHour = DateTime.now().hour;
    _controllers = List.generate(27, (i) {
      final initialText = (i < widget.initialSchedule.length) ? widget.initialSchedule[i] : "";
      return TextEditingController(text: initialText);
    });
    _focusNodes = List.generate(27, (_) => FocusNode());

    // 현재 시간대로 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentHour > 0 && _scrollController.hasClients) {
        final targetOffset = (_currentHour * 56.0).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final updatedList = _controllers.map((c) => c.text.trim()).toList();
    await DailyScheduleService.saveSchedule(updatedList);
    widget.onSave(updatedList);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("💾 27시간 Daily 스케줄이 저장되었습니다!"),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 화면 크기에 맞추어 안전한 폭/높이 계산 (절대 화면 밖으로 넘치지 않도록 제한)
          final double maxW = constraints.maxWidth > 650 ? 620.0 : (constraints.maxWidth * 0.95);
          final double maxH = (constraints.maxHeight - 16.0).clamp(200.0, constraints.maxHeight);

          return Container(
            width: maxW,
            height: maxH,
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.theme.primaryColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 헤더 영역 (Autolayout + Overflow 방지)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(
                      bottom: BorderSide(
                        color: widget.theme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: widget.theme.textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Daily 27시간 스케줄 관리",
                          style: TextStyle(
                            color: widget.theme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.close, color: widget.theme.textColor.withValues(alpha: 0.7), size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: "닫기",
                      ),
                    ],
                  ),
                ),

                // 2. 27시간 스크롤 리스트 영역 (Autolayout - Expanded + ListView)
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: 27,
                      itemBuilder: (context, index) {
                        final isCurrentHour = (index == _currentHour);
                        final timeLabel = DailyScheduleService.getTimeSlotLabel(index); // 예: "00:00"

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isCurrentHour
                                ? widget.theme.accentColor.withValues(alpha: 0.25)
                                : widget.theme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrentHour
                                  ? widget.theme.accentColor
                                  : widget.theme.primaryColor.withValues(alpha: 0.2),
                              width: isCurrentHour ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // 시간 표시 영역 (FittedBox로 오버플로우 100% 방지)
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 60, maxWidth: 85),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        timeLabel,
                                        style: TextStyle(
                                          color: isCurrentHour
                                              ? widget.theme.accentColor
                                              : widget.theme.textColor.withValues(alpha: 0.8),
                                          fontSize: 13,
                                          fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w600,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      if (isCurrentHour) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: widget.theme.accentColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "NOW",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 스케줄 입력 영역 (Expanded + Responsive TextField)
                              Expanded(
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  style: TextStyle(
                                    color: widget.theme.textColor,
                                    fontSize: 13,
                                    fontWeight: isCurrentHour ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: isCurrentHour ? "현재 시간 스케줄 입력..." : "스케줄 입력...",
                                    hintStyle: TextStyle(
                                      color: widget.theme.textColor.withValues(alpha: 0.35),
                                      fontSize: 12,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                    filled: true,
                                    fillColor: Colors.black.withValues(alpha: 0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: widget.theme.accentColor, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 3. 하단 버튼 영역 (Autolayout + FittedBox로 Overflow 방지)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(
                      top: BorderSide(
                        color: widget.theme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: widget.theme.textColor.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              "취소",
                              style: TextStyle(color: widget.theme.textColor, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _handleSave,
                            icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              "저장",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.theme.accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              elevation: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

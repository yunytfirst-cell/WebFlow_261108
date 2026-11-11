import 'package:flutter/material.dart';

import '../services/run_counter_service.dart';

class RunCounterPanel extends StatefulWidget {
  const RunCounterPanel({
    required this.runRecords,
    required this.onRecordsChanged,
    super.key,
  });

  final Map<String, int> runRecords;
  final VoidCallback onRecordsChanged;

  @override
  State<RunCounterPanel> createState() => _RunCounterPanelState();
}

class _RunCounterPanelState extends State<RunCounterPanel> {
  int get _todayCount => widget.runRecords[RunCounterService.todayKey()] ?? 0;
  int get _totalCount => RunCounterService.total(widget.runRecords);

  void _changeRunCount(int delta) {
    final next = (_todayCount + delta).clamp(0, RunCounterService.maxCount);
    if (next == _todayCount) return;
    setState(() {
      widget.runRecords[RunCounterService.todayKey()] = next;
    });
    widget.onRecordsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;
        final count = Text(
          '$_todayCount',
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: isCompact ? 26 : 30,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
        final arrows = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _arrowButton(
              tooltip: '오늘 실행 횟수 늘리기',
              icon: Icons.keyboard_arrow_up,
              color: Colors.amberAccent,
              onPressed: () => _changeRunCount(1),
            ),
            _arrowButton(
              tooltip: '오늘 실행 횟수 줄이기',
              icon: Icons.keyboard_arrow_down,
              color: Colors.white54,
              onPressed: () => _changeRunCount(-1),
            ),
          ],
        );
        final cumulativeCount = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.5),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '누적 ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '$_totalCount',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final counterContents = [
          Text(
            '오늘 실행',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isCompact ? 12 : 13,
            ),
          ),
          SizedBox(width: isCompact ? 6 : 12),
          count,
          const SizedBox(width: 4),
          arrows,
        ];

        return Container(
          margin: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 20),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: isCompact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: counterContents,
                    ),
                    const SizedBox(height: 4),
                    cumulativeCount,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...counterContents,
                    const SizedBox(width: 16),
                    cumulativeCount,
                  ],
                ),
        );
      },
    );
  }

  Widget _arrowButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: color, size: 20),
      onPressed: onPressed,
    );
  }
}

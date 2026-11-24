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

  // 2026-11-24 사용자 지시: 숫자 옆 위/아래 화살표를 없애고 누적 박스 오른쪽에 나란히 둔다.
  // 화살표를 세로로 쌓지 않으므로 박스 높이가 예전의 절반 정도가 된다.
  // 한 줄로만 배치하고, 폭이 좁으면 FittedBox로 통째로 줄여 넘치지 않게 한다.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;
        final count = Text(
          '$_todayCount',
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 22,
            height: 1.1,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
        final cumulativeCount = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.5),
            ),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '누적 ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '$_totalCount',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
        return Container(
          margin: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 20),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '오늘 실행',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 10),
                count,
                const SizedBox(width: 14),
                cumulativeCount,
                const SizedBox(width: 6),
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
            ),
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
    // IconButton은 최소 터치 크기 48로 늘어나 박스가 높아지므로 36×36 고정 버튼을 쓴다.
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

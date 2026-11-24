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

  // 2026-11-24 사용자 지시: 사이드바 제목 앞에 붙는 작은 박스. `실행` → `누적 N` → 위/아래 화살표(세로).
  // 폭 맞춤은 부모(제목 줄의 FittedBox)가 하므로 여기서는 고정 크기로만 그린다.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "오늘 실행 N" 대신 "실행" 글자만 둔다. 화살표 결과는 누적 숫자로 보인다.
          const Text(
            '실행',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Container(
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
          ),
          const SizedBox(width: 4),
          // 2026-11-24 사용자 지시: 화살표는 누적 오른쪽에 세로로 쌓는다.
          Column(
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
          ),
        ],
      ),
    );
  }

  Widget _arrowButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    // IconButton은 최소 터치 크기 48로 늘어나 박스가 높아지므로 28×18 고정 버튼을 쓴다(세로 2개 = 36).
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 28,
          height: 18,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

import 'package:flow/services/run_counter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('실행 기록을 txt 줄로 만들고 다시 읽는다', () {
    final lines = RunCounterService.toLines({'2026-11-05': 3, '2026-11-04': 2, '2026-11-03': 0});
    expect(lines, '[RUN] 2026-11-04: 2\n[RUN] 2026-11-05: 3\n');

    final parsed = <String, int>{};
    for (final line in lines.split('\n')) {
      final e = RunCounterService.parseLine(line);
      if (e != null) parsed[e.key] = e.value;
    }
    expect(parsed, {'2026-11-04': 2, '2026-11-05': 3});
    expect(RunCounterService.total(parsed), 5);
  });

  test('일반 목표 줄은 실행 기록으로 읽지 않는다', () {
    expect(RunCounterService.parseLine('1. 상품 등록'), isNull);
    expect(RunCounterService.parseLine('[PJT]: 상품화'), isNull);
    expect(RunCounterService.parseLine('[RUN] 2026-11-05: 7\r')?.value, 7);
  });

  test('접두어가 다른 실행 기록은 읽지 않는다', () {
    expect(RunCounterService.parseLine('[AWARE_RUN] 2026-11-05: 7'), isNull);
    expect(
      RunCounterService.parseLine(
        '[AWARE_RUN] 2026-11-05: 7',
        linePrefix: '[AWARE_RUN] ',
      )?.value,
      7,
    );
    expect(
      RunCounterService.parseLine('[RUN] 2026-11-05: 7', linePrefix: '[AWARE_RUN] '),
      isNull,
    );
    expect(RunCounterService.isRunLine('[AWARE_RUN] 2026-11-05: 7'), isTrue);
  });

  test('todayKey 형식', () {
    expect(RunCounterService.todayKey(DateTime(2026, 1, 7)), '2026-01-07');
  });
}

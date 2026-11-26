import 'package:flow/services/daily_schedule_service.dart';
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

  test('저장 날짜는 MM.dd로 보인다', () {
    expect(RunCounterService.shortDate(DateTime(2026, 3, 5)), '03.05');
    expect(RunCounterService.shortDate(DateTime(2026, 11, 24)), '11.24');
  });

  test('Daily: 같은 글이 이어지는 구간의 시작·끝 시간', () {
    final schedule = List<String>.filled(27, '');
    schedule[9] = '공부';
    schedule[10] = '공부 ';
    schedule[11] = '공부';
    schedule[12] = '점심';
    expect(DailyScheduleService.getTimeRangeLabels(schedule, 10),
        (start: '09:00', end: '12:00'));
    expect(DailyScheduleService.getTimeRangeLabels(schedule, 12),
        (start: '12:00', end: '13:00'));
    // 빈 칸도 이어진 구간으로 본다
    expect(DailyScheduleService.getTimeRangeLabels(schedule, 3),
        (start: '00:00', end: '09:00'));
    expect(DailyScheduleService.getTimeRangeLabels(schedule, 20),
        (start: '13:00', end: '27:00'));
  });
}

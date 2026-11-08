/// 끝장 리스트 실행 카운터.
/// 기록은 각 스케줄 txt 파일 안에 날짜별 한 줄씩 저장된다.
///   [RUN] 2026-11-05: 3
class RunCounterService {
  static const String linePrefix = '[RUN] ';
  static const int maxCount = 99; // 2자리수

  static final RegExp _lineRegex = RegExp(r'^\[RUN\] (\d{4}-\d{2}-\d{2}): (\d+)\s*$');

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  /// txt 한 줄이 실행 기록이면 (날짜, 횟수), 아니면 null
  static MapEntry<String, int>? parseLine(String line) {
    final m = _lineRegex.firstMatch(line.trim());
    if (m == null) return null;
    return MapEntry(m.group(1)!, int.parse(m.group(2)!));
  }

  /// 날짜순 실행 기록 줄들 (0회인 날은 제외)
  static String toLines(Map<String, int> records) {
    final keys = records.keys.where((k) => records[k]! > 0).toList()..sort();
    return keys.map((k) => "$linePrefix$k: ${records[k]}\n").join();
  }

  /// 전체 날짜 합산
  static int total(Map<String, int> records) => records.values.fold(0, (a, b) => a + b);
}

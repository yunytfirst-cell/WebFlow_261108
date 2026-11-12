/// 리스트 실행 카운터.
/// 기록은 각 리스트 txt 파일 안에 날짜별 한 줄씩 저장된다.
/// 끝장(성공의 열쇠) 리스트와 알아차림 리스트는 서로 다른 접두어를 쓴다.
///   [RUN] 2026-11-05: 3        ← 끝장(성공의 열쇠) 리스트
///   [AWARE_RUN] 2026-11-05: 3  ← 알아차림 리스트
class RunCounterService {
  static const String defaultLinePrefix = '[RUN] ';
  static const int maxCount = 99; // 2자리수

  static final RegExp _lineRegex = RegExp(
    r'^(\[[A-Z_]+\] )(\d{4}-\d{2}-\d{2}): (\d+)\s*$',
  );

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  /// 어떤 접두어든 실행 기록 형식의 줄이면 true
  static bool isRunLine(String line) => _lineRegex.hasMatch(line.trim());

  /// txt 한 줄이 [linePrefix] 실행 기록이면 (날짜, 횟수), 아니면 null
  static MapEntry<String, int>? parseLine(
    String line, {
    String linePrefix = defaultLinePrefix,
  }) {
    final m = _lineRegex.firstMatch(line.trim());
    if (m == null || m.group(1) != linePrefix) return null;
    return MapEntry(m.group(2)!, int.parse(m.group(3)!));
  }

  /// 날짜순 실행 기록 줄들 (0회인 날은 제외)
  static String toLines(
    Map<String, int> records, {
    String linePrefix = defaultLinePrefix,
  }) {
    final keys = records.keys.where((k) => records[k]! > 0).toList()..sort();
    return keys.map((k) => "$linePrefix$k: ${records[k]}\n").join();
  }

  /// 전체 날짜 합산
  static int total(Map<String, int> records) => records.values.fold(0, (a, b) => a + b);
}

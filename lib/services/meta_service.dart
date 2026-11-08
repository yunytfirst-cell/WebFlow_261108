import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MetaService {
  static const double initialMetaPoint = 60.0;

  /// 오늘 날짜에 해당하는 파일명을 반환 (예: meta_2023-10-27.json)
  static String _getTodayFileName() {
    final now = DateTime.now();
    return 'meta_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
  }

  /// [저장] 클릭 로그 기록 (날짜별 파일 적용)
  static Future<double> saveDailyLog(int counter, String xp, int currentInterval) async {
    try {
      final file = await _getTodayHistoryFile();
      List<dynamic> history = await loadTodayHistory();

      double lastTotalScore = history.isEmpty ? initialMetaPoint : (history.last['totalScore'] ?? initialMetaPoint).toDouble();
      int previousInterval = history.isEmpty ? 0 : (history.last['interval'] ?? 0);

      double delta = 0.0;
      if (previousInterval > 0) {
        double ratio = (currentInterval / previousInterval) * 100;
        if (ratio >= 100 && ratio <= 110) {
          delta = 4.0;
        } else if (ratio > 110 && ratio <= 150) {
          delta = 3.0;
        } else if (ratio > 150) {
          delta = 2.0;
        } else if (ratio < 90) {
          delta = -1.0;
        } else if (ratio < 50) {
          delta = -2.0;
        } else if (ratio < 10) {
          delta = -3.0;
        }
      }

      double newTotalScore = (lastTotalScore + delta).clamp(0.0, 999.0);

      history.add({
        'date': DateTime.now().toIso8601String(),
        'counter': counter,
        'interval': currentInterval,
        'delta': delta,
        'totalScore': newTotalScore,
        'type': 'click'
      });

      await file.writeAsString(json.encode(history));
      return double.parse(newTotalScore.toStringAsFixed(1));
    } catch (e) {
      return initialMetaPoint;
    }
  }

  /// [아카이빙] 세션 종료 기록 (날짜별 파일 적용)
  static Future<void> finalizeSession(int finalCounter, double finalScore) async {
    final file = await _getTodayHistoryFile();
    List<dynamic> history = await loadTodayHistory();
    
    history.add({
      'date': DateTime.now().toIso8601String(),
      'finalCounter': finalCounter,
      'totalScore': finalScore,
      'type': 'session_end'
    });
    
    await file.writeAsString(json.encode(history));
  }

  /// [재계산] 오늘의 파일 데이터를 기반으로 수치 산출
  static Future<Map<String, double>> recalculateToday() async {
    final history = await loadTodayHistory();
    if (history.isEmpty) return {'meta': initialMetaPoint, 'focusIncrease': 0.0};

    double currentMeta = initialMetaPoint;
    int totalIncrease = 0;
    int prevInterval = 0;

    for (var log in history) {
      if (log['type'] == 'click') {
        currentMeta += (log['delta'] ?? 0.0);
        int currentInterval = log['interval'] ?? 0;
        if (prevInterval > 0 && currentInterval > prevInterval) totalIncrease += (currentInterval - prevInterval);
        prevInterval = currentInterval;
      }
    }
    return {'meta': currentMeta.clamp(0.0, 999.0), 'focusIncrease': totalIncrease.toDouble()};
  }

  static Future<List<dynamic>> loadTodayHistory() async {
    try {
      final file = await _getTodayHistoryFile();
      if (!await file.exists()) return [];
      String content = await file.readAsString();
      return content.isEmpty ? [] : json.decode(content);
    } catch (e) {
      return [];
    }
  }

  static Future<File> _getTodayHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/${_getTodayFileName()}');
  }

  static double calculateCurrentPoint(List<dynamic> history) {
    if (history.isEmpty) return initialMetaPoint;
    return (history.last['totalScore'] ?? initialMetaPoint).toDouble();
  }

}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DailyScheduleService {
  static Future<String> get _scheduleDirPath async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/FlowSchedules";
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  static Future<File> get _scheduleFile async {
    final dirPath = await _scheduleDirPath;
    return File('$dirPath/daily_schedule.json');
  }

  /// 27시간 스케줄 불러오기
  static Future<List<String>> loadSchedule() async {
    try {
      final file = await _scheduleFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        List<String> result = List<String>.filled(27, "");
        for (int i = 0; i < 27 && i < jsonList.length; i++) {
          result[i] = jsonList[i].toString();
        }
        return result;
      }
    } catch (e) {
      debugPrint("Daily 스케줄 로드 에러: $e");
    }
    return List<String>.filled(27, "");
  }

  /// 27시간 스케줄 저장하기
  static Future<void> saveSchedule(List<String> schedule) async {
    try {
      final file = await _scheduleFile;
      final content = jsonEncode(schedule);
      await file.writeAsString(content);
    } catch (e) {
      debugPrint("Daily 스케줄 저장 에러: $e");
    }
  }

  /// 시작시간 한 개만 표시 (예: 00:00, 14:00, 24:00, 26:00)
  static String getTimeSlotLabel(int hour) {
    final hourString = hour.toString().padLeft(2, '0');
    return "$hourString:00";
  }

  /// 지금 시간과 같은 글이 이어지는 구간의 (시작, 끝) 시각 (2026-11-26 사용자 지시:
  /// 위쪽 = 그 글이 처음 기입된 시간, 아래쪽 = 그 글이 끝나는 다음 시간).
  /// 예: 9·10·11시가 모두 "공부"면 지금이 10시여도 (09:00, 12:00).
  static ({String start, String end}) getTimeRangeLabels(
    List<String> schedule,
    int hour,
  ) {
    if (hour < 0 || hour >= schedule.length) {
      return (start: getTimeSlotLabel(hour), end: getTimeSlotLabel(hour + 1));
    }
    final text = schedule[hour].trim();
    var start = hour;
    while (start > 0 && schedule[start - 1].trim() == text) {
      start--;
    }
    var end = hour + 1;
    while (end < schedule.length && schedule[end].trim() == text) {
      end++;
    }
    return (start: getTimeSlotLabel(start), end: getTimeSlotLabel(end));
  }

  /// 현재 시간대의 스케줄 텍스트 가져오기
  static String getCurrentScheduleText(List<String> schedule, [DateTime? now]) {
    final currentNow = now ?? DateTime.now();
    final hour = currentNow.hour;
    if (hour >= 0 && hour < schedule.length) {
      final text = schedule[hour].trim();
      return text.isNotEmpty ? text : "등록된 일정이 없습니다";
    }
    return "등록된 일정이 없습니다";
  }
}

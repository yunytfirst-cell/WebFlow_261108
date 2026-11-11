import 'dart:io';

import 'package:flow/services/list_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final kind in ListFileKind.values) {
    test('${kind.name} files can be opened by either list', () {
      final serialized = ListFileService.serialize(
        kind: kind,
        title: '공유 일정',
        items: ['첫 줄\n둘째 줄', '다음 항목'],
        runRecords: {'2026-11-11': 3, '2026-11-10': 2},
      );

      final parsed = ListFileService.parse(serialized);

      expect(parsed.title, '공유 일정');
      expect(parsed.items, ['첫 줄\n둘째 줄', '다음 항목']);
      expect(parsed.runRecords, {'2026-11-10': 2, '2026-11-11': 3});
    });
  }

  test('legacy numbered list files remain readable', () {
    final parsed = ListFileService.parse(
      '[PJT]: 기존 파일\n1. 첫 항목\n이어지는 내용\n2. 둘째 항목\n',
    );

    expect(parsed.title, '기존 파일');
    expect(parsed.items, ['첫 항목\n이어지는 내용', '둘째 항목']);
    expect(parsed.runRecords, isEmpty);
  });

  test(
    'legacy awareness files are copied without overwriting shared files',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'flow-list-file-test-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final legacyDirectory = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}FlowAwareness',
      )..createSync();
      final sharedDirectory = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}FlowSchedules',
      )..createSync();
      final legacyFile = File(
        '${legacyDirectory.path}${Platform.pathSeparator}일정.txt',
      )..writeAsStringSync('알아차림 파일');
      final existingFile = File(
        '${sharedDirectory.path}${Platform.pathSeparator}일정.txt',
      )..writeAsStringSync('목표 파일');

      await ListFileService.importLegacyAwarenessFiles(
        legacyDirectory: legacyDirectory,
        sharedDirectory: sharedDirectory,
      );

      expect(await existingFile.readAsString(), '목표 파일');
      expect(await legacyFile.readAsString(), '알아차림 파일');
      expect(
        await File(
          '${sharedDirectory.path}${Platform.pathSeparator}일정 (알아차림 1).txt',
        ).readAsString(),
        '알아차림 파일',
      );
    },
  );
}

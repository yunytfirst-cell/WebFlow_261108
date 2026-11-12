import 'dart:io';

import 'package:flow/services/list_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final kind in ListFileKind.values) {
    test('${kind.name} files round-trip title, items and run counter', () {
      final serialized = ListFileService.serialize(
        kind: kind,
        title: '일정',
        items: ['첫 줄\n둘째 줄', '다음 항목'],
        runRecords: {'2026-11-11': 3, '2026-11-10': 2},
      );

      final parsed = ListFileService.parse(serialized, kind: kind);

      expect(parsed.title, '일정');
      expect(parsed.items, ['첫 줄\n둘째 줄', '다음 항목']);
      expect(parsed.runRecords, {'2026-11-10': 2, '2026-11-11': 3});
    });
  }

  test('goal and awareness lists use separate folders and run lines', () {
    expect(ListFileKind.goal.directoryName, 'FlowSchedules');
    expect(ListFileKind.awareness.directoryName, 'FlowAwareness');

    final goal = ListFileService.serialize(
      kind: ListFileKind.goal,
      title: '목표',
      items: ['항목'],
      runRecords: {'2026-11-12': 4},
    );
    final awareness = ListFileService.serialize(
      kind: ListFileKind.awareness,
      title: '알아차림',
      items: ['항목'],
      runRecords: {'2026-11-12': 1},
    );

    expect(goal, contains('[RUN] 2026-11-12: 4'));
    expect(awareness, contains('[AWARE_RUN] 2026-11-12: 1'));
    expect(awareness, isNot(contains('[RUN] ')));
  });

  test('a list never picks up the other list\'s run counter', () {
    const content = '[AWARE]: 알아차림\n'
        '[RUN] 2026-11-12: 7\n'
        '[AWARE_RUN] 2026-11-12: 2\n'
        '[AWARE_ITEM:1]\n항목\n[END_AWARE_ITEM]\n';

    final awareness = ListFileService.parse(
      content,
      kind: ListFileKind.awareness,
    );
    final goal = ListFileService.parse(content, kind: ListFileKind.goal);

    expect(awareness.runRecords, {'2026-11-12': 2});
    expect(awareness.items, ['항목']);
    expect(goal.runRecords, {'2026-11-12': 7});
    expect(goal.items, ['항목']);
  });

  test('legacy numbered list files remain readable', () {
    final parsed = ListFileService.parse(
      '[PJT]: 기존 파일\n1. 첫 항목\n이어지는 내용\n2. 둘째 항목\n',
      kind: ListFileKind.goal,
    );

    expect(parsed.title, '기존 파일');
    expect(parsed.items, ['첫 항목\n이어지는 내용', '둘째 항목']);
    expect(parsed.runRecords, isEmpty);
  });

  test('picker start folder is normalized with a trailing separator', () {
    final sep = Platform.pathSeparator;
    expect(
      ListFileService.pickerInitialDirectory(r'C:/Docs\FlowAwareness'),
      'C:${sep}Docs${sep}FlowAwareness$sep',
    );
    expect(
      ListFileService.pickerInitialDirectory('C:${sep}Docs$sep'),
      'C:${sep}Docs$sep',
    );
  });
}

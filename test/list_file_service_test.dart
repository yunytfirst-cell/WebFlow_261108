import 'dart:io';

import 'package:flow/services/item_text_style.dart';
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
    const content =
        '[AWARE]: 알아차림\n'
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

  group('saveTargetPath: 제목이 파일 이름과 다르면 새 파일, 기존 파일 유지', () {
    final sep = Platform.pathSeparator;
    final folder = 'C:${sep}Lists';
    final opened = '$folder$sep월요일.txt';

    test('열린 파일이 없으면 작업 폴더에 제목 파일명으로', () {
      expect(
        ListFileService.saveTargetPath(
          currentFilePath: null,
          directory: 'D:/Docs',
          fileName: '할일.txt',
          exists: (_) => false,
        ),
        'D:/Docs/할일.txt',
      );
    });

    test('제목이 열린 파일 이름과 같으면 그 파일에 덮어쓴다 (대소문자 무시)', () {
      expect(
        ListFileService.saveTargetPath(
          currentFilePath: opened,
          directory: 'D:/Docs',
          fileName: '월요일.txt',
          exists: (_) => true,
        ),
        opened,
      );
      final upper = '$folder${sep}Plan.TXT';
      expect(
        ListFileService.saveTargetPath(
          currentFilePath: upper,
          directory: 'D:/Docs',
          fileName: 'plan.txt',
          exists: (_) => true,
        ),
        upper,
      );
    });

    test('제목이 다르면 열린 파일과 같은 폴더에 제목 이름으로 새 파일', () {
      expect(
        ListFileService.saveTargetPath(
          currentFilePath: opened,
          directory: 'D:/Docs',
          fileName: '화요일.txt',
          exists: (p) => p == opened,
        ),
        '$folder$sep화요일.txt',
      );
    });

    test('새 이름 파일이 이미 있으면 덮어쓰지 않고 번호를 붙인다', () {
      final taken = {opened, '$folder$sep화요일.txt', '$folder$sep화요일 (2).txt'};
      expect(
        ListFileService.saveTargetPath(
          currentFilePath: opened,
          directory: 'D:/Docs',
          fileName: '화요일.txt',
          exists: taken.contains,
        ),
        '$folder$sep화요일 (3).txt',
      );
    });

    test('번호가 붙은 파일(화요일 (3).txt)을 열고 제목이 화요일이면 그 파일에 덮어쓴다', () {
      final numbered = '$folder$sep화요일 (3).txt';
      expect(
        ListFileService.saveTargetPath(
          currentFilePath: numbered,
          directory: 'D:/Docs',
          fileName: '화요일.txt',
          exists: (_) => true,
        ),
        numbered,
      );
    });

    test('제목에 정규식 특수문자가 있어도 같은 제목으로 인정', () {
      final special = '$folder${sep}a+b (1).txt';
      expect(
        ListFileService.saveTargetPath(
          currentFilePath: special,
          directory: 'D:/Docs',
          fileName: 'a+b (1).txt',
          exists: (_) => true,
        ),
        special,
      );
    });

    test('실제 파일: 제목을 바꿔 저장해도 기존 파일 내용이 그대로 남는다', () {
      final dir = Directory.systemTemp.createTempSync('flow_save_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final old = File('${dir.path}$sep월요일.txt')..writeAsStringSync('기존');
      final target = ListFileService.saveTargetPath(
        currentFilePath: old.path,
        directory: dir.path,
        fileName: '화요일.txt',
      );
      File(target).writeAsStringSync('새것');
      expect(old.readAsStringSync(), '기존');
      expect(File('${dir.path}$sep화요일.txt').readAsStringSync(), '새것');
    });
  });

  for (final kind in ListFileKind.values) {
    test('${kind.name} files keep folded (collapsed) state per item', () {
      final serialized = ListFileService.serialize(
        kind: kind,
        title: '접기',
        items: ['긴 항목\n둘째 줄', '펼친 항목', '[FOLDED]로 시작하는 글'],
        runRecords: {},
        collapsed: [true, false, false],
      );
      expect(serialized, contains('[${kind.itemMarker}:1]\n[FOLDED]\n긴 항목'));

      final parsed = ListFileService.parse(serialized, kind: kind);
      expect(parsed.items, ['긴 항목\n둘째 줄', '펼친 항목', '[FOLDED]로 시작하는 글']);
      expect(parsed.collapsed, [true, false, false]);
    });

    test('${kind.name} applyFoldState changes only fold marks on disk', () {
      final disk = ListFileService.serialize(
        kind: kind,
        title: '디스크 제목',
        items: ['가', '나', '가'],
        runRecords: {'2026-11-21': 2},
        collapsed: [false, true, false],
      );

      final updated = ListFileService.applyFoldState(
        disk,
        kind: kind,
        screenItems: [
          (text: '가', collapsed: true),
          (text: '나', collapsed: false),
          (text: '가', collapsed: false),
          (text: '저장 안 한 새 항목', collapsed: true),
        ],
      );
      final parsed = ListFileService.parse(updated, kind: kind);

      expect(parsed.title, '디스크 제목');
      expect(parsed.items, ['가', '나', '가']);
      expect(parsed.runRecords, {'2026-11-21': 2});
      expect(parsed.collapsed, [true, false, false]);
    });
  }

  test('old files without fold marks open fully expanded', () {
    final parsed = ListFileService.parse(
      '[PJT]: 예전\n[GOAL:1]\n항목\n[END_GOAL]\n1. 옛 형식\n',
      kind: ListFileKind.goal,
    );
    expect(parsed.items, ['항목', '옛 형식']);
    expect(parsed.collapsed, [false, false]);
  });

  // 2026-11-25: 서식은 선택한 글자 구간마다 [SPAN] 줄로 저장·복원된다
  for (final kind in ListFileKind.values) {
    test(
      '${kind.name} item style spans round-trip and survive fold updates',
      () {
        const styled = ItemTextStyle(
          color: 0xE6B422,
          sizeScale: 1.2,
          bold: true,
          italic: true,
          underline: true,
          strike: true,
        );
        const spans = [
          StyleSpan(2, 4, styled),
          StyleSpan(5, 6, ItemTextStyle(bold: true)),
        ];
        final serialized = ListFileService.serialize(
          kind: kind,
          title: '서식',
          items: ['꾸민 항목 글', '보통 항목'],
          runRecords: const {},
          collapsed: [true, false],
          spans: [spans, const []],
        );
        expect(
          serialized,
          contains(
            '[SPAN] 2-4 color=E6B422;size=1.2;bold;italic;underline;strike',
          ),
        );
        expect(serialized, contains('[SPAN] 5-6 bold'));
        expect('[SPAN]'.allMatches(serialized).length, 2);

        final parsed = ListFileService.parse(serialized, kind: kind);
        expect(parsed.items, ['꾸민 항목 글', '보통 항목']);
        expect(parsed.collapsed, [true, false]);
        expect(parsed.spans, [spans, const <StyleSpan>[]]);

        final refolded = ListFileService.applyFoldState(
          serialized,
          kind: kind,
          screenItems: [
            (text: '꾸민 항목 글', collapsed: false),
            (text: '보통 항목', collapsed: true),
          ],
        );
        final again = ListFileService.parse(refolded, kind: kind);
        expect(again.collapsed, [false, true]);
        expect(again.spans, [spans, const <StyleSpan>[]]);
      },
    );
  }

  test('old whole-item [STYLE] lines load as a span over the whole item', () {
    final parsed = ListFileService.parse(
      '[PJT]: 예전\n[GOAL:1]\n[STYLE] italic\n항목글\n[END_GOAL]\n',
      kind: ListFileKind.goal,
    );
    expect(parsed.items, ['항목글']);
    expect(parsed.spans.first, [
      const StyleSpan(0, 3, ItemTextStyle(italic: true)),
    ]);
  });
}

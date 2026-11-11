import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'run_counter_service.dart';

enum ListFileKind {
  goal(titleMarker: '[PJT]', itemMarker: 'GOAL'),
  awareness(titleMarker: '[AWARE]', itemMarker: 'AWARE_ITEM');

  const ListFileKind({required this.titleMarker, required this.itemMarker});

  final String titleMarker;
  final String itemMarker;
}

class ListFileData {
  const ListFileData({
    required this.title,
    required this.items,
    required this.runRecords,
  });

  final String? title;
  final List<String> items;
  final Map<String, int> runRecords;
}

class ListFileService {
  static const String sharedDirectoryName = 'FlowSchedules';

  static Future<Directory> sharedDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}$sharedDirectoryName',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await importLegacyAwarenessFiles(
      legacyDirectory: Directory(
        '${documents.path}${Platform.pathSeparator}FlowAwareness',
      ),
      sharedDirectory: directory,
    );
    return directory;
  }

  static Future<void> importLegacyAwarenessFiles({
    required Directory legacyDirectory,
    required Directory sharedDirectory,
  }) async {
    if (!await legacyDirectory.exists()) return;

    await for (final entity in legacyDirectory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.txt')) {
        continue;
      }

      final fileName = entity.uri.pathSegments.last;
      var destination = File(
        '${sharedDirectory.path}${Platform.pathSeparator}$fileName',
      );
      if (await destination.exists()) {
        if (await entity.readAsString() == await destination.readAsString()) {
          continue;
        }

        final extensionIndex = fileName.lastIndexOf('.');
        final baseName = fileName.substring(0, extensionIndex);
        var copyNumber = 1;
        do {
          final alternateName = '$baseName (알아차림 $copyNumber).txt';
          destination = File(
            '${sharedDirectory.path}${Platform.pathSeparator}$alternateName',
          );
          copyNumber++;
        } while (await destination.exists() &&
            await entity.readAsString() != await destination.readAsString());
        if (await destination.exists()) continue;
      }

      await entity.copy(destination.path);
    }
  }

  static String serialize({
    required ListFileKind kind,
    required String title,
    required List<String> items,
    required Map<String, int> runRecords,
  }) {
    final content = StringBuffer()
      ..writeln('${kind.titleMarker}: $title')
      ..write(RunCounterService.toLines(runRecords));

    for (var index = 0; index < items.length; index++) {
      content
        ..writeln('[${kind.itemMarker}:${index + 1}]')
        ..writeln(items[index])
        ..writeln('[END_${kind.itemMarker}]');
    }
    return content.toString();
  }

  static ListFileData parse(String content) {
    final items = <String>[];
    final runRecords = <String, int>{};
    String? title;
    String? markedItem;
    final legacyItem = StringBuffer();

    void addLegacyItem() {
      final text = legacyItem.toString().trim();
      if (text.isNotEmpty) items.add(text);
      legacyItem.clear();
    }

    for (final line in content.split('\n')) {
      final trimmedLine = line.trim();
      if (RegExp(r'^\[(GOAL|AWARE_ITEM):\d+\]$').hasMatch(trimmedLine)) {
        addLegacyItem();
        markedItem = '';
      } else if (RegExp(r'^\[END_(GOAL|AWARE_ITEM)\]$').hasMatch(trimmedLine) &&
          markedItem != null) {
        items.add(markedItem.trim());
        markedItem = null;
      } else if (markedItem != null) {
        markedItem = markedItem.isEmpty ? line : '$markedItem\n$line';
      } else {
        final run = RunCounterService.parseLine(line);
        if (run != null) {
          runRecords[run.key] = run.value;
        } else if (line.startsWith('[PJT]: ') || line.startsWith('[AWARE]: ')) {
          title = line.substring(line.indexOf(']: ') + 3);
        } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
          addLegacyItem();
          legacyItem.write(line.replaceFirst(RegExp(r'^\d+\. '), ''));
        } else if (line.trim().isNotEmpty) {
          if (legacyItem.isNotEmpty) legacyItem.write('\n');
          legacyItem.write(line);
        }
      }
    }

    if (markedItem != null) {
      items.add(markedItem.trim());
    } else {
      addLegacyItem();
    }

    return ListFileData(title: title, items: items, runRecords: runRecords);
  }
}

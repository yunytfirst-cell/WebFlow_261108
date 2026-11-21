import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow/app_version.dart';

void main() {
  test('app_version.dart와 pubspec.yaml 버전이 같다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(match!.group(1), '$appVersion+$appBuild');
  });

  test('CHANGELOG.md 맨 위 버전이 현재 버전이다', () {
    final log = File('CHANGELOG.md').readAsStringSync();
    final first = RegExp(r'^## \[?(\d+\.\d+\.\d+)', multiLine: true).firstMatch(log);
    expect(first, isNotNull);
    expect(first!.group(1), appVersion);
  });
}

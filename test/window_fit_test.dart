import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow/services/window_fit.dart';

void main() {
  test('큰 모니터에서는 원래 크기(650x900) 그대로, 가운데', () {
    final r = fitWindowToScreen(desired: kDesiredWindowSize, workArea: const Rect.fromLTWH(0, 0, 2560, 1380));
    expect(r.size, kDesiredWindowSize);
    expect(r.left, (2560 - 650) / 2);
    expect(r.top, (1380 - 900) / 2);
  });

  test('작은 모니터(1920x1080, 배율 150% → 작업영역 1280x680)에서는 높이를 90%로 줄인다', () {
    final r = fitWindowToScreen(desired: kDesiredWindowSize, workArea: const Rect.fromLTWH(0, 0, 1280, 680));
    expect(r.height, 612);
    expect(r.width, 650);
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(680));
  });

  test('창 전체가 작업 영역 안에 있다 (다른 위치의 모니터)', () {
    const work = Rect.fromLTWH(1707, 235, 1280, 680);
    final r = fitWindowToScreen(desired: kDesiredWindowSize, workArea: work);
    expect(work.contains(r.topLeft), isTrue);
    expect(r.right, lessThanOrEqualTo(work.right));
    expect(r.bottom, lessThanOrEqualTo(work.bottom));
  });

  test('최소 크기도 모니터에 맞춰 줄인다', () {
    expect(fitMinimumSize(kMinWindowSize, const Size(650, 450)), const Size(300, 450));
  });
}

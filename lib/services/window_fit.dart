import 'dart:math' as math;
import 'dart:ui';

/// 처음 띄울 창 크기(논리 픽셀). 모니터가 작으면 아래 [fitWindowToScreen]이 줄인다.
const Size kDesiredWindowSize = Size(650, 900);

/// 창 최소 크기. 모니터가 이보다 작으면 모니터에 맞춘다.
const Size kMinWindowSize = Size(300, 500);

/// 모니터 작업 영역(작업표시줄 제외)에 창을 맞춘다.
///
/// - 창 크기는 작업 영역의 [fraction](기본 90%)을 넘지 않는다.
/// - 작업 영역 가운데에 놓고, 제목줄이 화면 위로 나가지 않게 top을 작업 영역 안으로 둔다.
///   (제목줄이 화면 밖이면 마우스로 창을 옮길 수 없다.)
Rect fitWindowToScreen({
  required Size desired,
  required Rect workArea,
  double fraction = 0.9,
}) {
  final double maxW = workArea.width * fraction;
  final double maxH = workArea.height * fraction;
  final double w = math.min(desired.width, maxW).roundToDouble();
  final double h = math.min(desired.height, maxH).roundToDouble();
  final double left = (workArea.left + (workArea.width - w) / 2).roundToDouble();
  final double top = math.max(workArea.top, workArea.top + (workArea.height - h) / 2).roundToDouble();
  return Rect.fromLTWH(left, top, w, h);
}

/// 최소 크기도 모니터보다 크지 않게 줄인다.
Size fitMinimumSize(Size minimum, Size fitted) =>
    Size(math.min(minimum.width, fitted.width), math.min(minimum.height, fitted.height));

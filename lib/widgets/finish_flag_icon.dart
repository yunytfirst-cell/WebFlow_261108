import 'package:flutter/material.dart';

/// "ITEM FINISH" 대신 보이는 완료 아이콘 (2026-11-25 사용자 지시, 첨부 이미지 참조):
/// 엇갈린 체크무늬 깃발 두 개 + 아래 "FINISH" 글자. 어두운 바탕에서도 보이게
/// 깃발은 흰/검 체크에 흰 테두리, 깃대는 [poleColor], 글자는 [textColor].
class FinishFlagIcon extends StatelessWidget {
  const FinishFlagIcon({
    super.key,
    required this.height,
    required this.poleColor,
    required this.textColor,
  });

  /// 아이콘 전체 높이 (깃발 + 글자)
  final double height;

  /// 높이 [height]일 때 아이콘 폭 (깃발 폭 = 깃발 높이 72% × 1.5)
  static double widthFor(double height) => height * 0.72 * 1.5;

  /// 아이콘 가운데(0.5)와 깃발 가운데(0.72/2 = 0.36)의 차이 ÷ 아이콘 높이.
  /// 깃발을 글자 가운데에 맞추려면 아이콘을 이만큼 내린다.
  static const double flagCenterDrop = 0.5 - 0.72 / 2;
  final Color poleColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    // 첨부 이미지처럼 깃발이 크고(약 3/4) 글자 폭은 깃발 폭에 맞춘다
    final flagHeight = height * 0.72;
    final flagWidth = flagHeight * 1.5;
    return Tooltip(
      message: 'ITEM FINISH',
      child: SizedBox(
        width: widthFor(height),
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: flagWidth,
              height: flagHeight,
              child: CustomPaint(painter: _FlagsPainter(poleColor)),
            ),
            SizedBox(
              width: flagWidth * 0.8,
              height: height - flagHeight,
              child: FittedBox(
                child: Text(
                  'FINISH',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagsPainter extends CustomPainter {
  _FlagsPainter(this.poleColor);

  final Color poleColor;

  // 설계 좌표 120×80 (왼쪽 깃발 기준, 오른쪽은 좌우 반전)
  static const _w = 120.0, _h = 80.0;
  static const _poleTop = Offset(50, 3), _poleBottom = Offset(74, 79);
  // 깃발 네 모서리: 깃대 위, 깃대 중간, 바깥 아래, 바깥 위 (바깥쪽이 살짝 처져 펄럭이는 모양)
  static const _flag = [
    Offset(50, 3),
    Offset(62, 44),
    Offset(6, 56),
    Offset(1, 14),
  ];
  static const _cols = 7, _rows = 5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _w, size.height / _h);
    for (final mirror in [false, true]) {
      Offset m(Offset p) => mirror ? Offset(_w - p.dx, p.dy) : p;
      // 깃대
      canvas.drawLine(
        m(_poleTop),
        m(_poleBottom),
        Paint()
          ..color = poleColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      // 체크무늬: 네 모서리를 이은 사각형을 칸으로 나눠 흰/검을 번갈아 칠한다
      Offset at(double u, double v) {
        final top = Offset.lerp(_flag[0], _flag[3], u)!;
        final bottom = Offset.lerp(_flag[1], _flag[2], u)!;
        return m(Offset.lerp(top, bottom, v)!);
      }

      for (var i = 0; i < _cols; i++) {
        for (var j = 0; j < _rows; j++) {
          final u0 = i / _cols, u1 = (i + 1) / _cols;
          final v0 = j / _rows, v1 = (j + 1) / _rows;
          final cell = Path()
            ..moveTo(at(u0, v0).dx, at(u0, v0).dy)
            ..lineTo(at(u1, v0).dx, at(u1, v0).dy)
            ..lineTo(at(u1, v1).dx, at(u1, v1).dy)
            ..lineTo(at(u0, v1).dx, at(u0, v1).dy)
            ..close();
          canvas.drawPath(
            cell,
            Paint()..color = (i + j).isEven ? Colors.black : Colors.white,
          );
        }
      }
      final outline = Path()..addPolygon(_flag.map(m).toList(), true);
      canvas.drawPath(
        outline,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_FlagsPainter old) => old.poleColor != poleColor;
}

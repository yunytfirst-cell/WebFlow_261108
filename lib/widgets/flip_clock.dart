import 'package:flutter/material.dart';
import 'dart:math' as math;

/*
[반응형 최적화 완료]
1. (가변 사이즈 수용) FlipCard가 생성자를 통해 width와 height를 전달받도록 수정했습니다.
2. (글자 크기 자동 조절) 고정된 폰트 크기 대신 박스 높이의 80%를 fontSize로 사용하여 사이즈 변화에 대응합니다.
3. (안정적인 레이아웃) OverflowBox와 ClipRect 로직이 주입된 사이즈에 맞춰 유연하게 작동합니다.
*/

class FlipClock extends StatelessWidget {
  final int value;
  final double width;
  final double height;
  const FlipClock({
    super.key,
    required this.value,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final digits = value.toString().padLeft(3, '0').split('').map(int.parse).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlipCard(value: digits[0], width: width, height: height),
        const SizedBox(width: 8),
        FlipCard(value: digits[1], width: width, height: height),
        const SizedBox(width: 8),
        FlipCard(value: digits[2], width: width, height: height),
      ],
    );
  }
}

class FlipCard extends StatefulWidget {
  final int value;
  final double width;
  final double height;
  const FlipCard({
    super.key,
    required this.value,
    required this.width,
    required this.height,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentDigit;
  late int _nextDigit;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.value;
    _nextDigit = widget.value;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // 애니메이션 완료 시점에 상태 동기화
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentDigit = _nextDigit;
          _controller.reset();
        });
      }
    });
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _currentDigit && !_controller.isAnimating) {
      _nextDigit = widget.value;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * math.pi;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                _buildHalf(_nextDigit, true, widget.width, widget.height),
                if (angle <= math.pi / 2)
                  Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(angle),
                    child: _buildHalf(_currentDigit, true, widget.width, widget.height),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Stack(
              children: [
                _buildHalf(_currentDigit, false, widget.width, widget.height),
                if (angle > math.pi / 2)
                  Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(angle - math.pi),
                    child: _buildHalf(_nextDigit, false, widget.width, widget.height),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHalf(int digit, bool isTop, double width, double height) {
    return Container(
      width: width,
      height: height / 2,
      // color: Colors.black.withAlpha(50),
      decoration: BoxDecoration(
        // color: const Color(0xFF222222),
        border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
        borderRadius: isTop 
            ? const BorderRadius.vertical(top: Radius.circular(8)) 
            : const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          maxHeight: height,
          minHeight: height,
          maxWidth: width,
          child: Container(
            height: height,
            alignment: Alignment.center,
            color: Colors.black.withAlpha(20),
            child: Text(
              '$digit',
              style: TextStyle(
                fontSize: height * 0.68, // 박스 높이의 68%로 조절하여 하단 숫자 잘림 방지
                fontWeight: FontWeight.bold,
                color: Colors.white.withAlpha(70),
                fontFamily: 'Impact',
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

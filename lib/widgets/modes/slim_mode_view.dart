import 'package:flutter/material.dart';
import '../../models/design_theme.dart';

class SlimModeView extends StatefulWidget {
  final int counter;
  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final AppThemeData theme;
  final double opacity;
  final bool isAlarmOn; // [추가] 알람 상태
  final VoidCallback onToggleSound; // [추가] 알람 토글 콜백

  const SlimModeView({
    super.key,
    required this.counter,
    required this.onIncrement,
    required this.onReset,
    required this.theme,
    this.opacity = 1.0,
    required this.isAlarmOn, // [추가]
    required this.onToggleSound, // [추가]
  });

  @override
  State<SlimModeView> createState() => _SlimModeViewState();
}

class _SlimModeViewState extends State<SlimModeView> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pressController.forward().then((_) => _pressController.reverse());
    widget.onIncrement();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 크기에 따른 가변 수치 계산
        double screenW = constraints.maxWidth;
        double screenH = constraints.maxHeight;
        double refSize = screenW < screenH ? screenW : screenH;
        
        // 반응형 스케일링 수치
        double counterFontSize = (refSize * 0.25).clamp(40.0, 150.0);
        double buttonSize = (refSize * 0.4).clamp(100.0, 300.0);
        double iconSize = buttonSize * 0.4;
        double controlBtnSize = (refSize * 0.1).clamp(30.0, 60.0);

        return Opacity(
          opacity: widget.opacity,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. 카운터 숫자
                    Text(
                      "${widget.counter}",
                      style: TextStyle(
                        fontSize: counterFontSize,
                        fontWeight: FontWeight.w900,
                        color: widget.theme.accentColor,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 2. 메인 클릭 버튼
                    GestureDetector(
                      onTapDown: (_) => _pressController.forward(),
                      onTapUp: (_) => _handleTap(),
                      onTapCancel: () => _pressController.reverse(),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                widget.theme.accentColor,
                                widget.theme.primaryColor.withValues(alpha: 0.5)
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.theme.accentColor.withValues(alpha: 0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(Icons.touch_app, size: iconSize, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // 3. 안내 문구
                    Text(
                      "CLICK TO COUNT",
                      style: TextStyle(
                        color: widget.theme.textColor.withValues(alpha: 0.4),
                        letterSpacing: 5,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 4. 하단 제어 버튼 (메인에서 이동됨)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 알람 사운드 버튼
                        IconButton(
                          icon: Icon(
                            widget.isAlarmOn ? Icons.volume_up : Icons.volume_off,
                            color: widget.isAlarmOn ? widget.theme.accentColor : widget.theme.textColor.withValues(alpha: 0.3),
                            size: controlBtnSize,
                          ),
                          onPressed: widget.onToggleSound,
                          tooltip: "사운드 토글",
                        ),
                        const SizedBox(width: 40),
                        // 리셋 버튼
                        IconButton(
                          icon: Icon(Icons.refresh, size: controlBtnSize, color: Colors.redAccent),
                          onPressed: widget.onReset,
                          tooltip: "카운터 초기화",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

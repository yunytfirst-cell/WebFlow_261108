import 'package:flutter/material.dart';

class ClayButton extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color baseColor;
  final double size;
  final bool isCircle;
  final double borderRadius;
  final String? tooltip;
  final Color? textColor;

  const ClayButton({
    super.key,
    this.icon,
    this.label,
    this.onPressed,
    required this.baseColor,
    this.size = 50,
    this.isCircle = false,
    this.borderRadius = 15,
    this.tooltip,
    this.textColor,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    int r = (widget.baseColor.r * 255).round();
    int g = (widget.baseColor.g * 255).round();
    int b = (widget.baseColor.b * 255).round();

    // 그림자 및 하이라이트 색상 계산
    final Color shadowColor = Color.fromARGB(
      180,
      (r - 60).clamp(0, 255),
      (g - 60).clamp(0, 255),
      (b - 50).clamp(0, 255),
    );
    final Color lightColor = Colors.white.withValues(alpha: 200 / 255);
    
    final Color displayContentColor = widget.textColor ?? 
        (ThemeData.estimateBrightnessForColor(widget.baseColor) == Brightness.dark 
            ? Colors.white
            : Colors.black);

    final Color lighterColor = Color.fromARGB(
      (widget.baseColor.a * 255).round(),
      (r + 30).clamp(0, 255),
      (g + 30).clamp(0, 255),
      (b + 30).clamp(0, 255),
    );

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: widget.isCircle ? widget.size : null,
      height: widget.size,
      padding: EdgeInsets.symmetric(horizontal: widget.isCircle ? 0 : 22, vertical: 5),
      decoration: BoxDecoration(
        color: widget.baseColor.withValues(alpha: 220 / 255),
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
        boxShadow: _isPressed
            ? [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 100 / 255),
                  offset: const Offset(1, 1),
                  blurRadius: 1,
                  spreadRadius: 1,
                )
              ]
            : [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(3, 3),
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: lightColor,
                  offset: const Offset(-2, -2),
                  blurRadius: 2,
                  spreadRadius: 2,
                ),
              ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.baseColor.withValues(alpha: 200 / 255),
            widget.baseColor,
            lighterColor,
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null)
            Icon(
              widget.icon,
              size: widget.size * 0.45,
              color: displayContentColor,
            ),
          if (widget.icon != null && widget.label != null) const SizedBox(width: 10),
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(
                color: displayContentColor,
                fontWeight: FontWeight.w900,
                fontSize: widget.size * 0.3,
              ),
            ),
        ],
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: content,
      ),
    );
  }
}

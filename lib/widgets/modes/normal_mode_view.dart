import 'package:flutter/material.dart';
import '../clock_display.dart';
import '../../models/design_theme.dart'; // [추가]

class NormalModeView extends StatelessWidget {
  final String timeString;
  final bool isRunning;
  final double progress;
  final String glowMessage;
  final bool showMessage;
  final AppThemeData theme; // [추가]

  const NormalModeView({
    super.key,
    required this.timeString,
    required this.isRunning,
    required this.progress,
    required this.glowMessage,
    required this.showMessage,
    required this.theme, // [추가]
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClockDisplay(
        timeString: timeString,
        isRunning: isRunning,
        progress: progress,
        glowMessage: glowMessage,
        showMessage: showMessage,
        theme: theme, // [전달]
      ),
    );
  }
}

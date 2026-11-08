import 'package:flutter/material.dart';
import '../clock_display.dart';
import '../../models/design_theme.dart';

class InfoBarModeView extends StatelessWidget {
  final Widget infoBar;
  final String timeString;
  final bool isRunning;
  final double progress;
  final String glowMessage;
  final bool showMessage;
  final AppThemeData theme;

  const InfoBarModeView({
    super.key,
    required this.infoBar,
    required this.timeString,
    required this.isRunning,
    required this.progress,
    required this.glowMessage,
    required this.showMessage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        infoBar,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ClockDisplay(
              timeString: timeString,
              isRunning: isRunning,
              progress: progress,
              glowMessage: glowMessage,
              showMessage: showMessage,
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }
}

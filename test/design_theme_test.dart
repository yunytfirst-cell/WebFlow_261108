import 'package:flow/models/design_theme.dart';
import 'package:flow/widgets/clay_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provides five ordered themes from dark to white', () {
    expect(AppThemeMode.values, [
      AppThemeMode.dark,
      AppThemeMode.blue,
      AppThemeMode.green,
      AppThemeMode.violet,
      AppThemeMode.white,
    ]);

    expect(
      AppThemeMode.values.map((mode) => AppThemeData.getTheme(mode).name),
      ['1. 다크', '2. 블루', '3. 세이지 그린', '4. 바이올렛', '5. 화이트'],
    );
  });

  test('keeps readable foreground colors across all theme surfaces', () {
    for (final mode in AppThemeMode.values) {
      final theme = AppThemeData.getTheme(mode);

      expect(
        _contrastRatio(theme.backgroundColor, theme.accentColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(theme.backgroundColor, theme.textColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(theme.primaryColor, theme.textColor),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('button foreground adapts when a theme color has low contrast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClayButton(
            baseColor: const Color(0xFF315E9B),
            textColor: const Color(0xFF1A2B45),
            label: 'Theme',
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Theme'));
    expect(label.style?.color, Colors.white);
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

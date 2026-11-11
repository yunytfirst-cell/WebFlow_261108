import 'package:flutter/material.dart';

enum AppThemeMode { dark, blue, green, violet, white }

class AppThemeData {
  final String name;
  final Color backgroundColor;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;
  final Color glassColor;
  final Color shadowColor;

  const AppThemeData({
    required this.name,
    required this.backgroundColor,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
    required this.glassColor,
    required this.shadowColor,
  });

  static AppThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return const AppThemeData(
          name: '1. 다크',
          backgroundColor: Color(0xFF151A22),
          primaryColor: Color(0xFF252D38),
          accentColor: Color(0xFF4DD0C3),
          textColor: Color(0xFFF2F4F8),
          subTextColor: Color(0xFFAAB3C1),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x66000000),
        );
      case AppThemeMode.blue:
        return const AppThemeData(
          name: '2. 블루',
          backgroundColor: Color(0xFFEDF3FA),
          primaryColor: Color(0xFFCAD9EC),
          accentColor: Color(0xFF315E9B),
          textColor: Color(0xFF1A2B45),
          subTextColor: Color(0xFF526985),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x33315E9B),
        );
      case AppThemeMode.green:
        return const AppThemeData(
          name: '3. 세이지 그린',
          backgroundColor: Color(0xFFEEF4EF),
          primaryColor: Color(0xFFD7E5D9),
          accentColor: Color(0xFF3A7053),
          textColor: Color(0xFF1E3427),
          subTextColor: Color(0xFF536B5C),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x333A7053),
        );
      case AppThemeMode.violet:
        return const AppThemeData(
          name: '4. 바이올렛',
          backgroundColor: Color(0xFFF4F0F7),
          primaryColor: Color(0xFFE0D6E8),
          accentColor: Color(0xFF704C91),
          textColor: Color(0xFF30223F),
          subTextColor: Color(0xFF665874),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x33704C91),
        );
      case AppThemeMode.white:
        return const AppThemeData(
          name: '5. 화이트',
          backgroundColor: Color(0xFFFFFFFF),
          primaryColor: Color(0xFFF2F4F7),
          accentColor: Color(0xFF285EA8),
          textColor: Color(0xFF202938),
          subTextColor: Color(0xFF606B7A),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x1A000000),
        );
    }
  }
}

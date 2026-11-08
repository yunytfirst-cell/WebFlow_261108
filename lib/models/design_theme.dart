import 'package:flutter/material.dart';

enum AppThemeMode {
  peachClay,
  oceanClay,
  roseClay,
  sageClay,
  ashClay,
  blackMode,
  whiteMode,
}

class AppThemeData {
  final Color backgroundColor;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;
  final Color glassColor;
  final Color shadowColor;

  const AppThemeData({
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
      case AppThemeMode.peachClay:
        return const AppThemeData(
          backgroundColor: Color(0xFFFDE8E0),
          primaryColor: Color(0xFFE5B9A8),
          accentColor: Color(0xFFFF9E80),
          // accentColor: Color(0xffff0000),
          textColor: Color(0xFF5D4037),
          subTextColor: Color(0xFF8D6E63),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x44A88E84),
        );
      case AppThemeMode.oceanClay:
        return const AppThemeData(
          backgroundColor: Color(0xFFA4C9E4),
          primaryColor: Color(0xFF7A9BB7),
          // accentColor: Color(0xFF80D8FF),
          accentColor: Color(0xFF042253),
          textColor: Color(0xFF263238),
          subTextColor: Color(0xFF455A64),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x44546E7A),
        );
      case AppThemeMode.roseClay:
        return const AppThemeData(
          backgroundColor: Color(0xFFF3D5D8),
          primaryColor: Color(0xFFC9A6AA),
          accentColor: Color(0xFFFF80AB),
          textColor: Color(0xFF4A148C),
          subTextColor: Color(0xFF7B1FA2),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x44880E4F),
        );
      case AppThemeMode.sageClay:
        return const AppThemeData(
          backgroundColor: Color(0xFFD4EAD8),
          primaryColor: Color(0xFFA6C9AD),
          // accentColor: Color(0xFFB9F6CA),
          accentColor: Color(0xFF044917),
          textColor: Color(0xFF1B5E20),
          subTextColor: Color(0xFF388E3C),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x442E7D32),
        );
      case AppThemeMode.ashClay:
        return const AppThemeData(
          backgroundColor: Color(0xFFE0E0E0),
          primaryColor: Color(0xFFAAAAAA),
          // accentColor: Color(0xFFBDBDBD),
          accentColor: Color(0xFF222222),
          textColor: Color(0xFF212121),
          subTextColor: Color(0xFF616161),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x44424242),
        );
      case AppThemeMode.blackMode:
        return const AppThemeData(
          backgroundColor: Color(0xFF000000),
          primaryColor: Color(0xFF1A1A1A), // 버튼을 배경보다 약간 밝게 하여 입체감 확보
          accentColor: Color(0xFF00E5FF),
          textColor: Color(0xFFFFFFFF), // 확실한 화이트 텍스트
          subTextColor: Color(0xFF9E9E9E),
          glassColor: Color(0x00000000),
          shadowColor: Color(0xFF222222), // 어두운 테마용 밝은 그림자 로직 대응
        );
      case AppThemeMode.whiteMode:
        return const AppThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          primaryColor: Color(0xFFF5F5F5),
          accentColor: Color(0xFF2196F3),
          textColor: Color(0xFF212121),
          subTextColor: Color(0xFF757575),
          glassColor: Color(0x00000000),
          shadowColor: Color(0x1A000000),
        );
    }
  }
}

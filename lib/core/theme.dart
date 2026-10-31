import 'package:flutter/material.dart';

/// 마음콕 v2 미니멀 디자인 토큰 (docs/SHARED.md 5번). 포인트 컬러는 여기 한 곳만 바꾼다.
class MkColors {
  static const accent = Color(0xFFFF6A3D); // 포인트(탠저린)
  static const text = Color(0xFF111111);
  static const textSub = Color(0xFF6B6B6B);
  static const border = Color(0xFFE5E5E5);
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const danger = Color(0xFFE5484D);
  static const charcoal = Color(0xFF2B2B2B); // 감정 아이콘 기본
  static const accentSoft = Color(0xFFFFF4EF); // 선택 타일 배경
  static const customDot = Color(0xFFBDBDBD);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MkColors.accent,
    primary: MkColors.accent,
    surface: MkColors.surface,
    error: MkColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MkColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: MkColors.background,
      foregroundColor: MkColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: MkColors.text,
      ),
      bodyMedium: TextStyle(fontSize: 15, color: MkColors.text),
      labelSmall: TextStyle(fontSize: 12, color: MkColors.textSub),
    ),
    cardTheme: CardThemeData(
      color: MkColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: MkColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MkColors.text,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MkColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MkColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MkColors.border),
      ),
    ),
  );
}

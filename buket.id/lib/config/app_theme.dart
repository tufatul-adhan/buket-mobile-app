import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF365C4B);
  static const Color primaryDark = Color(0xFF274638);
  static const Color primaryLight = Color(0xFF6F8C79);
  static const Color accentColor = Color(0xFFC9827C);
  static const Color successColor = Color(0xFF4F7C63);
  static const Color warningColor = Color(0xFFC48D45);
  static const Color errorColor = Color(0xFFB75D57);

  static const Color bgColor = Color(0xFFF7F7F2);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF25342C);
  static const Color textSecondaryColor = Color(0xFF748078);
  static const Color dividerColor = Color(0xFFE9ECE7);
  static const Color borderColor = Color(0xFFE2E7E1);
  static const Color softColor = Color(0xFFEEF3EE);
  static const Color blushColor = Color(0xFFF8EEEC);

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge:
            TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.15),
        displayMedium:
            TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
        displaySmall:
            TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
        headlineLarge:
            TextStyle(fontSize: 23, fontWeight: FontWeight.w700, height: 1.25),
        headlineMedium:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
        headlineSmall:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
        titleLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
        titleMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
        titleSmall:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
        bodyLarge:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.55),
        bodyMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ).apply(bodyColor: textPrimaryColor, displayColor: textPrimaryColor);

    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: borderColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        surface: cardColor,
        onSurface: textPrimaryColor,
        error: errorColor,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textPrimaryColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withValues(alpha: .35),
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: borderColor),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: outline,
        enabledBorder: outline,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.6),
        ),
        hintStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 13),
        prefixIconColor: textSecondaryColor,
        suffixIconColor: textSecondaryColor,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        disabledColor: softColor,
        selectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
            color: textPrimaryColor, fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerTheme:
          const DividerThemeData(color: dividerColor, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: textPrimaryColor, size: 22),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

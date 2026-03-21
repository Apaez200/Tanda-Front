import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: accentGold,
      secondary: primaryGreen,
      surface: cardBg,
      error: warningRed,
      onPrimary: darkBg,
      onSurface: offWhite,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: offWhite,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.dmSans(color: offWhite),
      bodyMedium: GoogleFonts.dmSans(color: offWhite),
      titleLarge: GoogleFonts.syne(fontWeight: FontWeight.w700, color: offWhite),
    ),
    dividerColor: softGray.withOpacity(0.3),
  );
}

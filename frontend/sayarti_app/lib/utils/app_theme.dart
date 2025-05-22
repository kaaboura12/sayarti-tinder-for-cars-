import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF1E88E5);     // Blue
  static const Color primaryDarkColor = Color(0xFF1565C0); // Dark Blue
  static const Color accentColor = Color(0xFF26C6DA);      // Cyan
  static const Color backgroundColor = Colors.white;
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFD32F2F);       // Red
  static const Color textColor = Color(0xFF212121);        // Dark Grey
  static const Color darkTextColor = Color(0xFFEEEEEE);    // Light Grey for dark mode
  static const Color textLightColor = Color(0xFF757575);   // Light Grey
  static const Color darkTextLightColor = Color(0xFFB0B0B0); // Lighter Grey for dark mode
  static const Color dividerColor = Color(0xFFBDBDBD);     // Grey
  static const Color darkDividerColor = Color(0xFF424242); // Dark Grey for dark mode

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    color: textColor,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    color: textColor,
  );
  
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    color: textLightColor,
  );
  
  // Dark mode text styles
  static TextStyle get darkHeadingLarge => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );
  
  static TextStyle get darkHeadingMedium => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
  );
  
  static TextStyle get darkBodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    color: darkTextColor,
  );
  
  static TextStyle get darkBodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    color: darkTextColor,
  );
  
  static TextStyle get darkBodySmall => GoogleFonts.poppins(
    fontSize: 12,
    color: darkTextLightColor,
  );
  
  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  
  // Text Field Decoration
  static InputDecoration textFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: dividerColor,
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: dividerColor,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
  
  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryButtonStyle,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      dividerColor: dividerColor,
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }
  
  // Dark Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        background: darkBackgroundColor,
        surface: darkSurfaceColor,
      ),
      cardColor: darkSurfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryButtonStyle,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: darkTextColor,
        displayColor: darkTextColor,
      ),
      dividerColor: darkDividerColor,
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }
} 
import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales - Design DUDU officiel (Vert foncé et Noir)
  static const Color primaryColor = Color(0xFF1B5E20); // Vert foncé
  static const Color secondaryColor = Color(0xFF2E7D32); // Vert moyen
  static const Color accentColor = Color(0xFF66BB6A); // Vert clair accent
  static const Color backgroundColor = Color(0xFFF5F5F5); // Gris très clair
  static const Color surfaceColor = Color(0xFFFFFFFF); // Blanc
  static const Color darkColor = Color(0xFF212121); // Noir profond
  static const Color textColor = Color(0xFF212121); // Noir pour texte
  static const Color textSecondaryColor = Color(0xFF757575); // Gris
  static const Color textLightColor = Color(0xFFFFFFFF); // Blanc pour texte sur fond foncé
  static const Color borderColor = Color(0xFFE0E0E0); // Gris clair
  static const Color successColor = Color(0xFF2E7D32); // Vert succès
  static const Color warningColor = Color(0xFFFFA726); // Orange warning
  static const Color errorColor = Color(0xFFE53935); // Rouge erreur
  static const Color infoColor = Color(0xFF1B5E20); // Vert foncé (primaire)

  // AJOUTS POUR LE DESIGN MODERNE
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient darkGradient = LinearGradient(
    colors: [Color(0xFF212121), Color(0xFF424242)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Ombres modernes
  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );
  
  static final BoxShadow buttonShadow = BoxShadow(
    color: primaryColor.withOpacity(0.3),
    blurRadius: 15,
    offset: const Offset(0, 6),
  );
  
  static final BoxShadow floatingShadow = BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 25,
    offset: const Offset(0, 12),
  );

  // Thème clair (CORRIGÉ)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    // CORRECTION ICI : Utilise CardTheme directement
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: surfaceColor,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textSecondaryColor,
      ),
    ),
  );

  // Thème sombre
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: const Color(0xFF2C2C2C),
      background: const Color(0xFF1A1A1A),
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2C2C2C),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  // MÉTHODES UTILITAIRES POUR LE DESIGN MODERNE
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [cardShadow],
    );
  }
  
  static BoxDecoration get buttonDecoration {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [buttonShadow],
    );
  }
  
  static BoxDecoration get secondaryButtonDecoration {
    return BoxDecoration(
      gradient: secondaryGradient,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [buttonShadow],
    );
  }
  
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(8);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(12);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(16);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(25);
}
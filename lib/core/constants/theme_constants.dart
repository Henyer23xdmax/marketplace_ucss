import 'package:flutter/material.dart';

class AppColors {
  // ========================================================
  // ☀️ TEMA CLARO - Institucional / Academia
  // Navy + oro mate sobre papel cálido. Contrastes WCAG verificados.
  // ========================================================
  static const Color primary = Color(0xFF1E3A5F); // navy  -> blanco 11.5:1
  static const Color primaryDark = Color(0xFF16293F); // pressed
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFA16207); // oro mate -> blanco 4.92:1
  static const Color secondaryDark = Color(0xFF7A4A05); // pressed / contenedor
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFAF9F6); // papel cálido
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF14181F); // 16.9:1 sobre fondo
  static const Color textSecondary = Color(0xFF4B5563); // 7.18:1
  static const Color textMuted = Color(0xFF6B7280); // 4.59:1 (AA)

  static const Color border = Color(0xFFE5E1D8); // agrupación decorativa
  static const Color borderStrong = Color(0xFF6B7280); // 4.59:1 para controles

  // ========================================================
  // 🌙 TEMA OSCURO - Navy profundo + oro
  // ========================================================
  static const Color darkBackground = Color(0xFF10151C);
  static const Color darkSurface = Color(0xFF1A222D);
  static const Color darkCard = Color(0xFF1A222D);
  static const Color darkText = Color(0xFFF5F5F4); // 16.8:1
  static const Color darkTextSecondary = Color(0xFFA3ADBA); // 7.05:1 sobre surface
  static const Color darkTextMuted = Color(0xFF6B7280);

  static const Color darkBorder = Color(0xFF2C3745); // decorativo
  static const Color darkBorderStrong = Color(0xFF64748B); // 3.37:1 controles

  static const Color darkPrimary = Color(0xFF9CC0E7); // 9.69:1 sobre fondo oscuro
  static const Color onDarkPrimary = Color(0xFF10151C); // 9.69:1 sobre darkPrimary
  static const Color darkSecondary = Color(0xFFD9A94F); // 8.5:1 sobre fondo oscuro
  static const Color darkAccent = Color(0xFF9CC0E7);

  // --- Estados (claro) ---
  static const Color success = Color(0xFF15803D); // 5.02:1 sobre blanco
  static const Color error = Color(0xFFB91C1C); // 6.47:1 sobre blanco
  static const Color warning = Color(0xFFA16207); // 4.92:1 sobre blanco

  // --- Estados (oscuro) ---
  static const Color darkSuccess = Color(0xFF4ADE80); // 10.52:1
  static const Color darkError = Color(0xFFF87171); // 6.62:1
  static const Color darkWarning = Color(0xFFFBBF24); // 10.98:1

  // --- Contenedores de estado / sombras ---
  static const Color warningContainer = Color(0xFFFFF6E5);
  static const Color onWarningContainer = Color(0xFF7A5900);
  static const Color darkWarningContainer = Color(0xFF33270E);
  static const Color onDarkWarningContainer = Color(0xFFFBBF24); // 8.75:1
  static const Color shadow = Color(0xFF000000);

  // --- Métodos de Pago Populares Perú ---
  static const Color yapePurple = Color(0xFF720E9E);
  static const Color plinCyan = Color(0xFF00A3FF);

  // ========================================================
  // 🔄 ALIAS DE COMPATIBILIDAD CON VISTAS EXISTENTES
  // ========================================================
  static const Color ucssNavy = primary;
  static const Color ucssNavyDark = primaryDark;
  static const Color ucssGold = secondary;
  static const Color ucssGoldLight = Color(0xFFEED9A8);
  static const Color ucssAccent = secondaryDark;

  static const Color iosBackground = background;
  static const Color iosCard = card;
  static const Color iosTextPrimary = textPrimary;
  static const Color iosTextSecondary = textSecondary;
  static const Color iosBorder = border;
  static const Color iosGreen = success;
  static const Color iosRed = error;
  static const Color iosOrange = warning;
}

// ========================================================
// TIPOGRAFÍA
// Inter (UI/cuerpo) + Source Serif 4 (títulos).
// Fuentes variables: los pesos se fijan con fontVariations.
// ========================================================
class AppFonts {
  static const String sans = 'Inter';
  static const String serif = 'SourceSerif4';

  static const List<FontVariation> w400 = [FontVariation('wght', 400)];
  static const List<FontVariation> w500 = [FontVariation('wght', 500)];
  static const List<FontVariation> w600 = [FontVariation('wght', 600)];
  static const List<FontVariation> w700 = [FontVariation('wght', 700)];
}

class AppTheme {
  // ----------------------------------------------------
  // TEMA CLARO
  // ----------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.sans,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryDark,
        onSecondaryContainer: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.onPrimary,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w700,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          height: 1.25,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w700,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          height: 1.30,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w600,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          height: 1.30,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w600,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          height: 1.40,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.50,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.50,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w600,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.40,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w600,
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w600,
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          color: AppColors.textMuted,
          fontSize: 15,
        ),
      ),
      // CTA principal (navy + texto blanco)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          minimumSize: const Size(44, 48),
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans,
            fontVariations: AppFonts.w600,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      // CTA secundario (oro + texto blanco)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          minimumSize: const Size(44, 48),
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans,
            fontVariations: AppFonts.w600,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TEMA OSCURO
  // ----------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppFonts.sans,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.onDarkPrimary,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.onDarkPrimary,
        secondaryContainer: AppColors.secondaryDark,
        onSecondaryContainer: AppColors.onPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.darkError,
        onError: AppColors.onDarkPrimary,
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w700,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          height: 1.25,
          letterSpacing: -0.5,
          color: AppColors.darkText,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w700,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          height: 1.30,
          letterSpacing: -0.3,
          color: AppColors.darkText,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w600,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          height: 1.30,
          color: AppColors.darkText,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.serif,
          fontVariations: AppFonts.w600,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          height: 1.40,
          color: AppColors.darkText,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.50,
          color: AppColors.darkText,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.50,
          color: AppColors.darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w600,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.40,
          color: AppColors.darkText,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w600,
          color: AppColors.darkText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.darkPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w600,
          color: AppColors.darkPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontVariations: AppFonts.w400,
          color: AppColors.darkTextSecondary,
          fontSize: 15,
        ),
      ),
      // CTA principal (azul acero claro + texto oscuro)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.onDarkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          minimumSize: const Size(44, 48),
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans,
            fontVariations: AppFonts.w600,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      // CTA secundario (oro sobre fondo oscuro + texto oscuro)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkSecondary,
          foregroundColor: AppColors.onDarkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          minimumSize: const Size(44, 48),
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans,
            fontVariations: AppFonts.w600,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

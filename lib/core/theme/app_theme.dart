import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Inter';

  static ThemeData light() => _build(_lightScheme, Brightness.light);

  static ThemeData dark() => _build(_darkScheme, Brightness.dark);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.indigo,
    onPrimary: Colors.white,
    primaryContainer: AppColors.indigoSoft,
    onPrimaryContainer: AppColors.indigoDeep,
    secondary: AppColors.violet,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF3EEFE),
    onSecondaryContainer: Color(0xFF5B21B6),
    tertiary: AppColors.checkedIn,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.successSoft,
    onTertiaryContainer: Color(0xFF14532D),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: Color(0xFF991B1B),
    surface: Colors.white,
    onSurface: AppColors.slate900,
    onSurfaceVariant: AppColors.slate500,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.slate50,
    surfaceContainer: AppColors.slate100,
    surfaceContainerHigh: AppColors.slate100,
    surfaceContainerHighest: AppColors.slate200,
    outline: AppColors.slate300,
    outlineVariant: AppColors.slate200,
    inverseSurface: AppColors.slate900,
    onInverseSurface: AppColors.slate100,
    shadow: AppColors.slate900,
    scrim: Colors.black,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.indigoLight,
    onPrimary: Color(0xFF1E1B4B),
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFFA78BFA),
    onSecondary: Color(0xFF2E1065),
    secondaryContainer: Color(0xFF5B21B6),
    onSecondaryContainer: Color(0xFFEDE9FE),
    tertiary: Color(0xFF4ADE80),
    onTertiary: Color(0xFF052E16),
    tertiaryContainer: Color(0xFF14532D),
    onTertiaryContainer: Color(0xFFDCFCE7),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AppColors.slate900,
    onSurface: Color(0xFFF1F5F9),
    onSurfaceVariant: AppColors.slate400,
    surfaceContainerLowest: AppColors.slate950,
    surfaceContainerLow: AppColors.slate900,
    surfaceContainer: AppColors.slate800,
    surfaceContainerHigh: AppColors.slate800,
    surfaceContainerHighest: AppColors.slate700,
    outline: AppColors.slate700,
    outlineVariant: AppColors.slate800,
    inverseSurface: AppColors.slate100,
    onInverseSurface: AppColors.slate900,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final background = isLight ? AppColors.canvas : AppColors.slate950;

    final base = ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isLight ? Colors.white : AppColors.slate800,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.slate50 : AppColors.slate900,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.md,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        border: _inputBorder(scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
        errorStyle: TextStyle(color: scheme.error, fontSize: 12.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: scheme.onSurface,
          backgroundColor: isLight ? Colors.white : AppColors.slate800,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : AppColors.slate800,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? Colors.white : AppColors.slate800,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md - 2),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    return base.apply(fontFamily: fontFamily).copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: fontFamily,
            height: 1.45,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: fontFamily,
            height: 1.5,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: fontFamily,
            height: 1.45,
            color: scheme.onSurfaceVariant,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        );
  }
}

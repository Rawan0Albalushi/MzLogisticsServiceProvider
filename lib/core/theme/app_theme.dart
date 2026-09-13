import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/page_transitions.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(Locale locale) {
    final arabic = locale.languageCode == 'ar';
    final scheme = const ColorScheme.light(
      primary: AppColors.teal,
      onPrimary: AppColors.white,
      secondary: AppColors.coral,
      onSecondary: AppColors.onAccent,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.white,
      outline: AppColors.border,
    );

    final latinStyle = GoogleFonts.ibmPlexSans();
    final arabicStyle = GoogleFonts.ibmPlexSansArabic();
    final primaryFamily = arabic ? arabicStyle.fontFamily : latinStyle.fontFamily;
    final fallbackFamily = arabic ? latinStyle.fontFamily : arabicStyle.fontFamily;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: primaryFamily,
    );
    final fallbacks = <String>[
      ?fallbackFamily,
      'Segoe UI',
      'Tahoma',
      'Arial',
      'sans-serif',
    ];

    final seeded = arabic
        ? GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
        : GoogleFonts.ibmPlexSansTextTheme(base.textTheme);

    TextStyle? withMetrics(TextStyle? style, {FontWeight? weight, double height = 1.45}) {
      return style?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        fontWeight: weight ?? style.fontWeight,
        height: height,
        letterSpacing: 0,
      );
    }

    final textTheme = seeded
        .apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
          fontFamily: primaryFamily,
          fontFamilyFallback: fallbacks,
        )
        .copyWith(
          headlineSmall: withMetrics(seeded.headlineSmall, weight: FontWeight.w600, height: 1.35),
          titleLarge: withMetrics(seeded.titleLarge, weight: FontWeight.w600, height: 1.35),
          titleMedium: withMetrics(seeded.titleMedium, weight: FontWeight.w600, height: 1.4),
          titleSmall: withMetrics(seeded.titleSmall, weight: FontWeight.w600, height: 1.4),
          bodyLarge: withMetrics(seeded.bodyLarge),
          bodyMedium: withMetrics(seeded.bodyMedium),
          bodySmall: withMetrics(seeded.bodySmall),
          labelLarge: withMetrics(seeded.labelLarge, height: 1.3),
          labelMedium: withMetrics(seeded.labelMedium, height: 1.3),
        );

    final radius = BorderRadius.circular(AppColors.radius);

    return base.copyWith(
      textTheme: textTheme,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const SubtleFadePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal800,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.teal800),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBg,
        side: const BorderSide(color: AppColors.border),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
        dividerThickness: 1,
        headingTextStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          fontSize: 11,
        ),
        dataTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.teal800,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.coral,
        dividerColor: AppColors.border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.tealSoft,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.teal800 : AppColors.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.teal800 : AppColors.muted,
          );
        }),
      ),
    );
  }
}

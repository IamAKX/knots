import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Design tokens for Knots. Change colours / fonts here only.
class K {
  // Side colours (used for chips, charts, avatars everywhere)
  static const groom = Color(0xFF4C7FB8);
  static const bride = Color(0xFFD19A3F);
  static const shared = Color(0xFF7E9C8A);

  static const chart = [
    Color(0xFF2F3E46),
    Color(0xFFC06C52),
    Color(0xFFD19A3F),
    Color(0xFF7E9C8A),
    Color(0xFF4C7FB8),
    Color(0xFFB5546A),
    Color(0xFF3C8D93),
    Color(0xFFBFAE96),
    Color(0xFF8A7CA8),
    Color(0xFF6B8F3E),
    Color(0xFFE0A58F),
    Color(0xFF5B6770),
    Color(0xFFA0522D),
  ];

  static const r = 20.0; // card radius
  static const gap = 16.0;
  static const maxW = 1080.0;

  static Color sideColor(String s) => switch (s) {
    'groom' => groom,
    'bride' => bride,
    _ => shared,
  };
  static String sideLabel(String s) => switch (s) {
    'groom' => 'Groom',
    'bride' => 'Bride',
    _ => 'Shared',
  };
}

extension Pal on BuildContext {
  bool get dark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get muted => dark ? const Color(0xFF9A928A) : const Color(0xFF7B736B);
  Color get line => dark ? const Color(0xFF2E2A2F) : const Color(0xFFEDE5D8);
  Color get card => dark ? const Color(0xFF211E22) : Colors.white;
  Color get soft => dark ? const Color(0xFF2A262B) : const Color(0xFFF5EFE6);
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get accent => Theme.of(this).colorScheme.primary;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get wide => MediaQuery.sizeOf(this).width >= 720;
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final ink = dark ? const Color(0xFFF2EBE0) : const Color(0xFF221E27);
  final primary = dark ? const Color(0xFFE3C58A) : const Color(0xFF2F3E46);
  final onPrimary = dark ? const Color(0xFF1B1710) : Colors.white;
  final bg = dark ? const Color(0xFF171518) : const Color(0xFFFAF6F0);
  final card = dark ? const Color(0xFF211E22) : Colors.white;
  final line = dark ? const Color(0xFF2E2A2F) : const Color(0xFFEDE5D8);
  final soft = dark ? const Color(0xFF2A262B) : const Color(0xFFF5EFE6);

  final scheme = ColorScheme(
    brightness: b,
    primary: primary,
    onPrimary: onPrimary,
    secondary: K.bride,
    onSecondary: Colors.white,
    error: const Color(0xFFC0443C),
    onError: Colors.white,
    surface: card,
    onSurface: ink,
    surfaceContainerHighest: soft,
    outline: line,
  );

  TextStyle p(
    double s,
    FontWeight w, {
    double? h,
    double? ls,
    String f = 'Roboto',
  }) => TextStyle(
    fontFamily: f,
    fontSize: s,
    fontWeight: w,
    color: ink,
    height: h,
    letterSpacing: ls,
  );

  final text = TextTheme(
    displayLarge: p(44, FontWeight.w700, h: 1.1, ls: -1),
    displayMedium: p(34, FontWeight.w700, h: 1.15, ls: -.6),
    headlineLarge: p(28, FontWeight.w700, h: 1.2, ls: -.4),
    headlineMedium: p(24, FontWeight.w700, h: 1.2, ls: -.3),
    headlineSmall: p(20, FontWeight.w700, h: 1.25, ls: -.2),
    titleLarge: p(18, FontWeight.w700),
    titleMedium: p(15, FontWeight.w700),
    titleSmall: p(13, FontWeight.w700),
    bodyLarge: p(15, FontWeight.w400, h: 1.5),
    bodyMedium: p(13.5, FontWeight.w400, h: 1.5),
    bodySmall: p(12, FontWeight.w400, h: 1.4),
    labelLarge: p(14, FontWeight.w500),
    labelMedium: p(12, FontWeight.w500),
    labelSmall: p(11, FontWeight.w500, ls: .3),
  );

  OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    dividerColor: line,
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(K.r),
        side: BorderSide(color: line),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: soft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: ob(Colors.transparent),
      enabledBorder: ob(Colors.transparent),
      focusedBorder: ob(primary, 1.5),
      errorBorder: ob(scheme.error),
      focusedErrorBorder: ob(scheme.error, 1.5),
      labelStyle: p(
        13,
        FontWeight.w400,
      ).copyWith(color: const Color(0xFF8A8279)),
      floatingLabelStyle: p(13, FontWeight.w500).copyWith(color: primary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: p(14, FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(0, 50),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: p(14, FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: p(13.5, FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFFF2EBE0) : const Color(0xFF221E27),
      contentTextStyle: p(
        13,
        FontWeight.w400,
      ).copyWith(color: dark ? const Color(0xFF221E27) : Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: soft,
      selectedColor: primary,
      side: BorderSide.none,
      labelStyle: p(12.5, FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? onPrimary : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? primary
            : const Color(0xFFCFC6B8),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? primary : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(onPrimary),
      side: BorderSide(
        color: dark ? const Color(0xFF6B635B) : const Color(0xFFC9BFB0),
        width: 1.5,
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

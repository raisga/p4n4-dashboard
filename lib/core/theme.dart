import 'package:flutter/material.dart';

/// Brand palette + fonts. The defaults are the p4n4 brand: dark is the
/// original launcher palette; light is its own set of steps tuned for contrast on
/// white, not an inversion. White-label brands override them via [withBrand].
@immutable
class P4Colors extends ThemeExtension<P4Colors> {
  const P4Colors({
    required this.brightness,
    required this.bg,
    required this.bg2,
    required this.bg3,
    required this.accent,
    required this.accent2,
    required this.onAccent,
    required this.amber,
    required this.blue,
    required this.heading,
    required this.text,
    required this.muted,
    required this.border,
    required this.border2,
    required this.ok,
    required this.warn,
    required this.err,
  });

  final Brightness brightness;
  final Color bg;
  final Color bg2;
  final Color bg3;
  final Color accent;
  final Color accent2;
  final Color onAccent;
  final Color amber;
  final Color blue;
  final Color heading;
  final Color text;
  final Color muted;
  final Color border;
  final Color border2;
  final Color ok;
  final Color warn;
  final Color err;

  /// Font families declared in pubspec.yaml. `tool/brand.dart apply` fills
  /// them with the brand's fonts (brand.json `fonts`), bundled for offline use.
  static const displayFamily = 'BrandDisplay';
  static const monoFamily = 'BrandMono';

  /// Colour tokens a brand may override in brand.json, by name.
  static const tokens = [
    'bg', 'bg2', 'bg3', 'accent', 'accent2', 'onAccent', 'amber', 'blue', //
    'heading', 'text', 'muted', 'border', 'border2', 'ok', 'warn', 'err',
  ];

  Color token(String name) => switch (name) {
    'bg' => bg,
    'bg2' => bg2,
    'bg3' => bg3,
    'accent' => accent,
    'accent2' => accent2,
    'onAccent' => onAccent,
    'amber' => amber,
    'blue' => blue,
    'heading' => heading,
    'text' => text,
    'muted' => muted,
    'border' => border,
    'border2' => border2,
    'ok' => ok,
    'warn' => warn,
    'err' => err,
    _ => throw ArgumentError.value(name, 'name', 'unknown colour token'),
  };

  /// Returns this palette with [overrides] (token name → colour) applied.
  P4Colors withBrand(Map<String, Color> overrides) {
    final unknown = overrides.keys.where((k) => !tokens.contains(k));
    if (unknown.isNotEmpty) throw FormatException('Unknown colour tokens: ${unknown.join(', ')}');
    Color c(String name) => overrides[name] ?? token(name);
    return P4Colors(
      brightness: brightness,
      bg: c('bg'),
      bg2: c('bg2'),
      bg3: c('bg3'),
      accent: c('accent'),
      accent2: c('accent2'),
      onAccent: c('onAccent'),
      amber: c('amber'),
      blue: c('blue'),
      heading: c('heading'),
      text: c('text'),
      muted: c('muted'),
      border: c('border'),
      border2: c('border2'),
      ok: c('ok'),
      warn: c('warn'),
      err: c('err'),
    );
  }

  static const dark = P4Colors(
    brightness: Brightness.dark,
    bg: Color(0xFF0A0A0A),
    bg2: Color(0xFF111111),
    bg3: Color(0xFF1A1A1A),
    accent: Color(0xFFF97316),
    accent2: Color(0xFFC2410C),
    onAccent: Color(0xFF0A0A0A),
    amber: Color(0xFFFB923C),
    blue: Color(0xFF94A3B8),
    heading: Color(0xFFFFFFFF),
    text: Color(0xFFECECEC),
    muted: Color(0xFFA8A8A8),
    border: Color(0xFF1F1F1F),
    border2: Color(0xFF2A2A2A),
    ok: Color(0xFF22C55E),
    warn: Color(0xFFEAB308),
    err: Color(0xFFEF4444),
  );

  static const light = P4Colors(
    brightness: Brightness.light,
    bg: Color(0xFFFAFAF9),
    bg2: Color(0xFFFFFFFF),
    bg3: Color(0xFFF5F5F4),
    accent: Color(0xFFC2410C),
    accent2: Color(0xFF9A3412),
    onAccent: Color(0xFFFFFFFF),
    amber: Color(0xFFB45309),
    blue: Color(0xFF475569),
    heading: Color(0xFF0A0A0A),
    text: Color(0xFF1C1917),
    muted: Color(0xFF57534E),
    border: Color(0xFFE7E5E4),
    border2: Color(0xFFD6D3D1),
    ok: Color(0xFF15803D),
    warn: Color(0xFFA16207),
    err: Color(0xFFB91C1C),
  );

  bool get isDark => brightness == Brightness.dark;

  /// This palette with secondary text close to body text and borders that
  /// stand out, for Settings → Accessibility → High contrast (or the device's
  /// own setting). Only ever raises contrast, so a valid brand stays valid.
  P4Colors get contrasted => withBrand({
    'muted': Color.lerp(muted, text, 0.6)!,
    'border': Color.lerp(border2, text, 0.3)!,
    'border2': Color.lerp(border2, text, 0.5)!,
  });

  TextStyle mono({double size = 11, Color? color, FontWeight weight = FontWeight.w400, double spacing = 0.08}) =>
      TextStyle(
        fontFamily: monoFamily,
        fontSize: size,
        color: color ?? muted,
        fontWeight: weight,
        letterSpacing: size * spacing,
      );

  TextStyle display({double size = 15, Color? color, FontWeight weight = FontWeight.w700, double spacing = -0.3}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        color: color ?? heading,
        fontWeight: weight,
        letterSpacing: spacing,
      );

  /// Running text: sentences people read, in the display face at a regular weight.
  TextStyle body({double size = 14, Color? color, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: displayFamily, fontSize: size, color: color ?? text, fontWeight: weight, height: 1.45);

  @override
  P4Colors copyWith() => this;

  /// Snap rather than tween: the palettes are discrete, and a 50% blend of
  /// the two is not a valid palette.
  @override
  P4Colors lerp(P4Colors? other, double t) => other == null || t < 0.5 ? this : other;
}

extension P4Context on BuildContext {
  P4Colors get p4 => Theme.of(this).extension<P4Colors>()!;
}

/// Corner radii shared by every surface, so cards, fields and buttons line up.
abstract final class Radii {
  /// Cards, panels, dialogs.
  static const card = 12.0;

  /// Buttons, fields, chips, menus.
  static const control = 8.0;

  static final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(card));
  static final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(control));
}

/// [reduceMotion] drops page transitions and ink ripples (Settings →
/// Accessibility → Reduce motion, or the device's own setting).
ThemeData buildTheme(P4Colors c, {bool reduceMotion = false}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: c.brightness,
    colorScheme: ColorScheme(
      brightness: c.brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.amber,
      onSecondary: c.onAccent,
      surface: c.bg2,
      onSurface: c.text,
      error: c.err,
      onError: c.onAccent,
      outline: c.border2,
      outlineVariant: c.border,
    ),
    scaffoldBackgroundColor: c.bg,
    dividerColor: c.border,
    pageTransitionsTheme: reduceMotion
        ? PageTransitionsTheme(builders: {for (final p in TargetPlatform.values) p: const _NoTransition()})
        : null,
    splashFactory: reduceMotion ? NoSplash.splashFactory : null,
  );
  final control = Radii.controlShape;
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.control),
    borderSide: BorderSide(color: c.border2),
  );
  // Labels people read are in the display face, sentence case; the mono face
  // is kept for values such as URLs, hosts and numbers.
  final label = c.display(size: 14, color: null, weight: FontWeight.w600, spacing: 0);
  return base.copyWith(
    extensions: [c],
    textTheme: base.textTheme.apply(fontFamily: P4Colors.displayFamily, bodyColor: c.text, displayColor: c.heading),
    iconTheme: IconThemeData(color: c.text),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(bottom: BorderSide(color: c.border)),
      titleTextStyle: c.display(size: 18, weight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg2,
      indicatorColor: c.accent.withValues(alpha: 0.15),
      indicatorShape: control,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => c.display(
          size: 12,
          color: s.contains(WidgetState.selected) ? c.heading : c.muted,
          weight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          spacing: 0,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.accent : c.muted),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.bg2,
      indicatorColor: c.accent.withValues(alpha: 0.15),
      indicatorShape: control,
      selectedLabelTextStyle: c.display(size: 12, color: c.heading, weight: FontWeight.w700, spacing: 0),
      unselectedLabelTextStyle: c.display(size: 12, color: c.muted, weight: FontWeight.w500, spacing: 0),
      selectedIconTheme: IconThemeData(color: c.accent),
      unselectedIconTheme: IconThemeData(color: c.muted),
    ),
    cardTheme: CardThemeData(
      color: c.bg2,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: Radii.cardShape.copyWith(side: BorderSide(color: c.border)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.bg2,
      surfaceTintColor: Colors.transparent,
      shape: Radii.cardShape.copyWith(side: BorderSide(color: c.border2)),
      titleTextStyle: c.display(size: 18),
      contentTextStyle: c.display(size: 14, color: c.text, weight: FontWeight.w400, spacing: 0),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        shape: control,
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.border2),
        shape: control,
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.accent, shape: control, textStyle: label),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(shape: control)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: control,
        foregroundColor: c.text,
        selectedBackgroundColor: c.accent,
        selectedForegroundColor: c.onAccent,
        textStyle: c.display(size: 13, color: null, weight: FontWeight.w600, spacing: 0),
        side: BorderSide(color: c.border2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: control,
      side: BorderSide(color: c.border2),
      backgroundColor: c.bg2,
      selectedColor: c.accent.withValues(alpha: 0.15),
      labelStyle: c.display(size: 13, color: c.text, weight: FontWeight.w500, spacing: 0),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.bg2,
      surfaceTintColor: Colors.transparent,
      shape: control.copyWith(side: BorderSide(color: c.border2)),
      textStyle: c.display(size: 14, color: c.text, weight: FontWeight.w400, spacing: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bg2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: c.display(size: 14, color: c.muted, weight: FontWeight.w400, spacing: 0),
      hintStyle: c.mono(size: 12, color: c.muted.withValues(alpha: 0.7), spacing: 0),
      helperStyle: c.display(size: 12, color: c.muted, weight: FontWeight.w400, spacing: 0),
      helperMaxLines: 3,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.accent, width: 1.5)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.bg3),
      trackOutlineColor: WidgetStatePropertyAll(c.border2),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: c.display(size: 14, color: c.text, weight: FontWeight.w500, spacing: 0),
      subtitleTextStyle: c.display(size: 13, color: c.muted, weight: FontWeight.w400, spacing: 0),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.bg3,
      contentTextStyle: c.display(size: 14, color: c.text, weight: FontWeight.w400, spacing: 0),
      shape: control.copyWith(side: BorderSide(color: c.border2)),
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.bg3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border2),
      ),
      textStyle: c.display(size: 12, color: c.text, weight: FontWeight.w500, spacing: 0),
    ),
  );
}

/// Pages that appear at once, for reduced motion.
class _NoTransition extends PageTransitionsBuilder {
  const _NoTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

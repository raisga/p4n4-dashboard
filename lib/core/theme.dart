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

ThemeData buildTheme(P4Colors c) {
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
  );
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: c.border2),
  );
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
      titleTextStyle: c.mono(size: 18, color: c.accent, weight: FontWeight.w700, spacing: -0.05),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg2,
      indicatorColor: c.accent.withValues(alpha: 0.15),
      indicatorShape: square,
      labelTextStyle: WidgetStatePropertyAll(c.mono(size: 10)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.bg2,
      indicatorColor: c.accent.withValues(alpha: 0.15),
      indicatorShape: square,
      selectedLabelTextStyle: c.mono(size: 10, color: c.accent),
      unselectedLabelTextStyle: c.mono(size: 10),
      selectedIconTheme: IconThemeData(color: c.accent),
      unselectedIconTheme: IconThemeData(color: c.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        shape: square,
        textStyle: c.mono(size: 11, weight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.border2),
        shape: square,
        textStyle: c.mono(size: 11),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bg2,
      isDense: true,
      labelStyle: c.mono(size: 12),
      hintStyle: c.mono(size: 12, color: c.muted.withValues(alpha: 0.6)),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.accent)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.bg3),
      trackOutlineColor: WidgetStatePropertyAll(c.border2),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.bg3,
      contentTextStyle: c.mono(size: 12, color: c.text),
      shape: square,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.bg3,
        border: Border.all(color: c.border2),
      ),
      textStyle: c.mono(size: 11, color: c.text),
    ),
  );
}

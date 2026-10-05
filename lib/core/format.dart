import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'settings.dart';

/// Regions that measure temperature in °F; everywhere else uses °C.
const fahrenheitRegions = {'US', 'BS', 'BZ', 'KY', 'LR', 'PW', 'FM', 'MH'};

/// Numbers, temperatures and times as the user asked for them in Settings →
/// Language & region: decimals in the language's style (51.3 in English,
/// 51,3 in Spanish), temperatures in their unit, times in their clock.
class Formats {
  const Formats({required this.locale, required this.fahrenheit, required this.use24h});

  /// For the current language and the user's settings.
  factory Formats.of(BuildContext context) {
    final s = SettingsScope.of(context);
    final dispatcher = View.maybeOf(context)?.platformDispatcher ?? PlatformDispatcher.instance;
    return Formats(
      locale: Localizations.localeOf(context).toLanguageTag(),
      fahrenheit: switch (s.temperatureUnit) {
        TemperatureUnit.celsius => false,
        TemperatureUnit.fahrenheit => true,
        TemperatureUnit.auto => fahrenheitRegions.contains(dispatcher.locale.countryCode),
      },
      use24h: switch (s.timeFormat) {
        TimeFormat.h12 => false,
        TimeFormat.h24 => true,
        // The device's switch where it has one (Android, iOS), else the language's custom.
        TimeFormat.auto when MediaQuery.alwaysUse24HourFormatOf(context) => true,
        TimeFormat.auto => null,
      },
    );
  }

  /// An intl locale tag such as `es`.
  final String locale;
  final bool fahrenheit;

  /// Null to follow [locale]'s custom.
  final bool? use24h;

  /// [v] with exactly [digits] decimals.
  String decimal(num v, [int digits = 1]) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits).format(v);

  /// [v] percent, e.g. `45.3%`.
  String percent(num v, [int digits = 0]) => '${decimal(v, digits)}%';

  /// [celsius] in the chosen unit, e.g. `51°C` or `124°F`.
  String temperature(double celsius, [int digits = 0]) =>
      fahrenheit ? '${decimal(celsius * 9 / 5 + 32, digits)}°F' : '${decimal(celsius, digits)}°C';

  /// The time of day of [t] in the chosen clock.
  String clock(DateTime t, {bool seconds = false}) => switch ((use24h, seconds)) {
    (true, false) => DateFormat.Hm(locale),
    (true, true) => DateFormat.Hms(locale),
    (false, false) => DateFormat('h:mm a', locale),
    (false, true) => DateFormat('h:mm:ss a', locale),
    (null, false) => DateFormat.jm(locale),
    (null, true) => DateFormat.jms(locale),
  }.format(t);
}

extension FormatsContext on BuildContext {
  Formats get formats => Formats.of(this);
}

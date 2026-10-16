import 'package:flutter/services.dart';

/// The platform's alert sound (silent where it has none, e.g. Linux).
Future<void> playChime() => SystemSound.play(SystemSoundType.alert);

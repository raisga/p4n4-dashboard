import 'package:flutter/widgets.dart';

import '../core/settings.dart';
import 'dashcam.dart';
import 'drive_channel.dart';
import 'gps_publisher.dart';
import 'location.dart';
import 'obd_relay.dart';

/// The phone in the car, for as long as the app runs: its GPS ([location]),
/// published to the stack ([publisher]), an OBD-II adapter relayed to the
/// stack ([relay]), and the [dashcam]. Each does nothing until turned on
/// (Settings → Drive, the Map tab, the Cameras tab).
class DriveServices {
  DriveServices(AppSettings settings) : location = LocationService(), awake = KeepAwake() {
    publisher = GpsPublisher(settings, location);
    relay = ObdRelay(settings);
    dashcam = Dashcam(settings, location, awake);
    if (settings.dashcamAutoStart) dashcam.start();
  }

  final LocationService location;

  /// Keeps the screen on while the map shows or the dashcam records.
  final KeepAwake awake;
  late final GpsPublisher publisher;
  late final ObdRelay relay;
  late final Dashcam dashcam;
}

/// Hands [DriveServices] down the tree.
class DriveScope extends InheritedWidget {
  const DriveScope({super.key, required this.services, required super.child});

  final DriveServices services;

  /// The services, where the app has them (not in some tests).
  static DriveServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DriveScope>()?.services;

  @override
  bool updateShouldNotify(DriveScope oldWidget) => services != oldWidget.services;
}

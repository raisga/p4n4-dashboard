import 'dart:math' as math;

/// One GPS fix: where the phone was, and how it was moving.
class Fix {
  const Fix({
    required this.lat,
    required this.lon,
    required this.time,
    this.alt,
    this.speed,
    this.heading,
    this.accuracy,
  });

  final double lat;
  final double lon;
  final DateTime time;

  /// Metres above sea level.
  final double? alt;

  /// Metres per second.
  final double? speed;

  /// The direction of travel, in degrees clockwise from north.
  final double? heading;

  /// How far off the fix may be, in metres.
  final double? accuracy;

  double? get speedKmh => speed == null ? null : speed! * 3.6;

  /// The fix as the stack files it, from `sensors/<device>/gps` (the
  /// mqtt-influx-grafana-obd2 template): speed in km/h, what's unknown left out.
  Map<String, num> toPayload() => {
    'lat': _round(lat, 6),
    'lon': _round(lon, 6),
    if (alt case final v?) 'alt': _round(v, 1),
    if (speedKmh case final v?) 'speed': _round(v, 1),
    if (heading case final v?) 'heading': _round(v, 1),
    if (accuracy case final v?) 'acc': _round(v, 1),
  };
}

double _round(double v, int digits) {
  final scale = math.pow(10, digits);
  return (v * scale).round() / scale;
}

/// The distance between two points, in metres (haversine, on a sphere).
double distanceMetres(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371008.8;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * earth * math.asin(math.min(1, math.sqrt(a)));
}

/// The way driven, for the Map tab: fixes at least [minMetres] apart and no
/// worse than [maxAccuracy], the latest [max] of them.
class Track {
  Track({this.minMetres = 5, this.maxAccuracy = 50, this.max = 5000});

  final double minMetres;
  final double maxAccuracy;
  final int max;

  final _fixes = <Fix>[];

  List<Fix> get fixes => List.unmodifiable(_fixes);

  /// Changes whenever the track does: a fix added, or [clear].
  int get revision => _revision;
  int _revision = 0;

  /// Adds [fix] unless it's too close to the last one or too vague; true if added.
  bool add(Fix fix) {
    if ((fix.accuracy ?? 0) > maxAccuracy) return false;
    if (_fixes.lastOrNull case final last? when distanceMetres(last.lat, last.lon, fix.lat, fix.lon) < minMetres) {
      return false;
    }
    _fixes.add(fix);
    if (_fixes.length > max) _fixes.removeRange(0, _fixes.length - max);
    _revision++;
    return true;
  }

  void clear() {
    _fixes.clear();
    _revision++;
  }

  /// A GeoJSON FeatureCollection: the track as one LineString, once it has two points.
  Map<String, Object> toGeoJson() => {
    'type': 'FeatureCollection',
    'features': [
      if (_fixes.length > 1)
        {
          'type': 'Feature',
          'properties': <String, Object>{},
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final f in _fixes) [f.lon, f.lat],
            ],
          },
        },
    ],
  };
}

/// [fixes] as a GPX 1.1 track named [name]: a dashcam clip's sidecar, which
/// players and maps can follow along with the video. Speed (m/s) and course
/// go in Garmin's TrackPointExtension, which most readers understand.
String gpx(Iterable<Fix> fixes, {required String name}) {
  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<gpx version="1.1" creator="p4n4 dashboard" xmlns="http://www.topografix.com/GPX/1/1" '
      'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2">',
    )
    ..writeln('  <trk>')
    ..writeln('    <name>${_xml(name)}</name>')
    ..writeln('    <trkseg>');
  for (final f in fixes) {
    out.write('      <trkpt lat="${f.lat.toStringAsFixed(7)}" lon="${f.lon.toStringAsFixed(7)}">');
    if (f.alt case final alt?) out.write('<ele>${alt.toStringAsFixed(1)}</ele>');
    out.write('<time>${f.time.toUtc().toIso8601String()}</time>');
    if (f.speed != null || f.heading != null) {
      out.write('<extensions><gpxtpx:TrackPointExtension>');
      if (f.speed case final speed?) out.write('<gpxtpx:speed>${speed.toStringAsFixed(2)}</gpxtpx:speed>');
      if (f.heading case final heading?) out.write('<gpxtpx:course>${heading.toStringAsFixed(1)}</gpxtpx:course>');
      out.write('</gpxtpx:TrackPointExtension></extensions>');
    }
    out.writeln('</trkpt>');
  }
  out
    ..writeln('    </trkseg>')
    ..writeln('  </trk>')
    ..writeln('</gpx>');
  return out.toString();
}

String _xml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

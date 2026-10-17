import '../widgets/common.dart' show Level;

/// The edge readings that have warning and critical levels.
enum Reading { cpu, memory, disk, temperature }

/// When a reading turns high (warning colour) or critical, and how long a
/// service may be down before that's critical too. Kept per deployment
/// (Settings → Thresholds), since a Jetson runs hotter than a Pi; a brand or
/// project can set its own as the `thresholds` default.
class Thresholds {
  const Thresholds({
    this.cpu = (75, 90),
    this.memory = (75, 90),
    this.disk = (80, 95),
    this.temperature = (70, 80),
    this.serviceDownMinutes = 5,
  });

  /// From `{"cpu": [75, 90], …, "serviceDownMinutes": 5}`; what's missing or
  /// malformed stays at the defaults.
  factory Thresholds.fromJson(Map<String, Object?> j) {
    const d = Thresholds();
    (double, double) pair(String key, (double, double) fallback) => switch (j[key]) {
      [final num high, final num critical] when high <= critical => (high.toDouble(), critical.toDouble()),
      _ => fallback,
    };
    return Thresholds(
      cpu: pair('cpu', d.cpu),
      memory: pair('memory', d.memory),
      disk: pair('disk', d.disk),
      temperature: pair('temperature', d.temperature),
      serviceDownMinutes: switch (j['serviceDownMinutes']) {
        final num m when m >= 0 => m.toInt(),
        _ => d.serviceDownMinutes,
      },
    );
  }

  /// High and critical, in percent ([cpu], [memory], [disk]) or °C ([temperature]).
  final (double, double) cpu;
  final (double, double) memory;
  final (double, double) disk;
  final (double, double) temperature;

  /// Minutes a service can be down before it's critical rather than a warning.
  final int serviceDownMinutes;

  (double, double) of(Reading r) => switch (r) {
    Reading.cpu => cpu,
    Reading.memory => memory,
    Reading.disk => disk,
    Reading.temperature => temperature,
  };

  /// How [value] of [r] compares with these thresholds.
  Level level(Reading r, double value) {
    final (high, critical) = of(r);
    return value >= critical
        ? Level.critical
        : value >= high
        ? Level.high
        : Level.normal;
  }

  /// A service down for [down]: a warning at first, critical after [serviceDownMinutes].
  Level downLevel(Duration down) => down.inMinutes >= serviceDownMinutes ? Level.critical : Level.high;

  Thresholds copyWith(Reading r, (double, double) value) => Thresholds(
    cpu: r == Reading.cpu ? value : cpu,
    memory: r == Reading.memory ? value : memory,
    disk: r == Reading.disk ? value : disk,
    temperature: r == Reading.temperature ? value : temperature,
    serviceDownMinutes: serviceDownMinutes,
  );

  Thresholds withServiceDown(int minutes) =>
      Thresholds(cpu: cpu, memory: memory, disk: disk, temperature: temperature, serviceDownMinutes: minutes);

  Map<String, Object> toJson() => {
    for (final r in Reading.values) r.name: [of(r).$1, of(r).$2],
    'serviceDownMinutes': serviceDownMinutes,
  };

  @override
  bool operator ==(Object other) =>
      other is Thresholds &&
      other.cpu == cpu &&
      other.memory == memory &&
      other.disk == disk &&
      other.temperature == temperature &&
      other.serviceDownMinutes == serviceDownMinutes;

  @override
  int get hashCode => Object.hash(cpu, memory, disk, temperature, serviceDownMinutes);
}

/// A client's p4n4 deployment: a named connection profile that an admin
/// monitors from the Clients tab and can connect the dashboard to.
class Deployment {
  Deployment({required this.id, required this.name, Map<String, Object>? values}) : values = {...?values};

  final String id;
  final String name;

  /// This deployment's connection settings, keyed like [AppSettings]
  /// (`host`, `apiBase`, `videoUrl`, …; see `profileKeys`). Missing keys fall
  /// back to the brand defaults.
  final Map<String, Object> values;

  Deployment copyWith({String? name, Map<String, Object>? values}) =>
      Deployment(id: id, name: name ?? this.name, values: values ?? this.values);

  Map<String, Object> toJson() => {'id': id, 'name': name, 'values': values};

  factory Deployment.fromJson(Map<String, dynamic> j) => Deployment(
    id: j['id'] as String,
    name: j['name'] as String,
    values: ((j['values'] as Map?) ?? const {}).cast<String, Object>(),
  );
}

/// A client's p4n4 deployment that an admin monitors from the Clients tab.
class Deployment {
  const Deployment(this.name, this.host);

  final String name;

  /// Host running the stacks; p4n4-api is expected on port 8000.
  final String host;

  Uri get apiUri => Uri.parse('http://$host:8000');

  Map<String, String> toJson() => {'name': name, 'host': host};

  factory Deployment.fromJson(Map<String, dynamic> j) => Deployment(j['name'] as String, j['host'] as String);
}

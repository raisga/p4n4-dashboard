/// A camera feed: an MJPEG stream or a JPEG snapshot URL.
class Camera {
  const Camera({required this.id, required this.name, required this.url});

  /// Stable across renames and URL changes, so the viewer keeps its stream.
  final String id;
  final String name;
  final String url;

  /// The parsed [url], or null if it isn't a usable http(s) URL.
  Uri? get uri => parseUrl(url);

  static Uri? parseUrl(String url) {
    final u = Uri.tryParse(url.trim());
    return u != null && (u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty ? u : null;
  }

  Camera copyWith({String? name, String? url}) => Camera(id: id, name: name ?? this.name, url: url ?? this.url);

  Map<String, String> toJson() => {'id': id, 'name': name, 'url': url};

  factory Camera.fromJson(Map<String, dynamic> j) =>
      Camera(id: j['id'] as String, name: j['name'] as String, url: j['url'] as String);
}

/// A camera feed: an MJPEG stream, a JPEG snapshot URL or a video file
/// ([isVideo]).
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

  /// Whether [url] is a video file or playlist (played on a loop, muted)
  /// rather than an MJPEG stream or snapshot.
  bool get isVideo => uri != null && looksLikeVideo(uri!);

  static bool looksLikeVideo(Uri uri) {
    final path = uri.path.toLowerCase();
    return const ['.mp4', '.m4v', '.mov', '.webm', '.ogv', '.m3u8'].any(path.endsWith);
  }

  Camera copyWith({String? name, String? url}) => Camera(id: id, name: name ?? this.name, url: url ?? this.url);

  Map<String, String> toJson() => {'id': id, 'name': name, 'url': url};

  factory Camera.fromJson(Map<String, dynamic> j) =>
      Camera(id: j['id'] as String, name: j['name'] as String, url: j['url'] as String);
}

/// Stand-in feeds for showing the Video tab without cameras: short, openly
/// licensed H.264 clips (CC0 from MDN; Big Buck Bunny and Sintel are
/// © Blender Foundation, CC BY 3.0, credited on the tab). Their ids never
/// collide with a deployment's own cameras.
const demoCameras = [
  Camera(id: 'demo-garden', name: 'Garden', url: 'https://mdn.github.io/shared-assets/videos/flower.mp4'),
  Camera(id: 'demo-street', name: 'Street', url: 'https://mdn.github.io/shared-assets/videos/friday.mp4'),
  Camera(
    id: 'demo-meadow',
    name: 'Meadow',
    url: 'https://mdn.github.io/learning-area/html/multimedia-and-embedding/video-and-audio-content/rabbit320.mp4',
  ),
  Camera(id: 'demo-gate', name: 'Gate', url: 'https://download.blender.org/durian/trailer/sintel_trailer-480p.mp4'),
];

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// The app's folder named [name] on the phone's shared storage
/// (`Android/data/<app>/files/<name>`, which a computer can copy from over
/// USB), made if needed; null where there's none (iOS).
Future<String?> externalFolder(String name) async {
  final Directory? base;
  try {
    base = await getExternalStorageDirectory();
  } on UnsupportedError {
    return null;
  }
  if (base == null) return null;
  final dir = await Directory('${base.path}/$name').create(recursive: true);
  return dir.path;
}

/// The files in [folder] whose names end with [suffix] (not its subfolders').
Future<List<({String path, int bytes, DateTime modified})>> listFiles(String folder, String suffix) async {
  final dir = Directory(folder);
  if (!await dir.exists()) return [];
  final found = <({String path, int bytes, DateTime modified})>[];
  await for (final entry in dir.list(followLinks: false)) {
    if (entry is! File || !entry.path.toLowerCase().endsWith(suffix)) continue;
    try {
      final stat = await entry.stat();
      found.add((path: entry.path, bytes: stat.size, modified: stat.modified));
    } on FileSystemException {
      // Deleted meanwhile.
    }
  }
  return found;
}

Future<bool> fileExists(String path) => File(path).exists();

/// Deletes [path], if it's there.
Future<void> deleteFile(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException {
    // Gone already.
  }
}

/// Moves [from] to [to], on the same storage; false if it couldn't.
Future<bool> moveFile(String from, String to) async {
  try {
    await File(from).rename(to);
    return true;
  } on FileSystemException {
    return false;
  }
}

Future<void> writeTextFile(String path, String text) => File(path).writeAsString(text, flush: true);

/// Plays the video file at [path].
VideoPlayerController localVideoPlayer(String path) => VideoPlayerController.file(File(path));

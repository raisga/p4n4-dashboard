import 'package:video_player/video_player.dart';

Future<String?> externalFolder(String name) async => null;

Future<List<({String path, int bytes, DateTime modified})>> listFiles(String folder, String suffix) async => const [];

Future<bool> fileExists(String path) async => false;

Future<void> deleteFile(String path) async {}

Future<bool> moveFile(String from, String to) async => false;

Future<void> writeTextFile(String path, String text) async => throw UnsupportedError('Browsers have no folders');

VideoPlayerController localVideoPlayer(String path) => throw UnsupportedError('Browsers have no folders');

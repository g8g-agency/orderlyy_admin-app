import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> saveBytesAsDownload(Uint8List bytes, String filename) async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted && !status.isLimited) {
      throw StateError('Storage permission denied');
    }
  }

  Directory? dir;
  if (Platform.isAndroid) {
    dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      dir = await getDownloadsDirectory();
    }
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  if (dir == null) {
    throw StateError('Could not resolve download directory');
  }

  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
}

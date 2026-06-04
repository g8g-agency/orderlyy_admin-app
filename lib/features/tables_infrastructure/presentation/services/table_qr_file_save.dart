import 'dart:typed_data';

import 'table_qr_file_save_io.dart'
    if (dart.library.html) 'table_qr_file_save_web.dart' as platform;

Future<void> saveBytesAsDownload(Uint8List bytes, String filename) =>
    platform.saveBytesAsDownload(bytes, filename);

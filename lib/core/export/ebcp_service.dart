import 'dart:io';

import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract final class EbcpService {
  // ── Export ──────────────────────────────────────────────────────────────────

  static Future<void> shareFile(EbcpFile file, String fileName) async {
    final bytes = file.toEbcp();
    final name = '${sanitizeName(fileName)}.ebcp';

    if (Platform.isAndroid || Platform.isIOS) {
      final tmp = await getTemporaryDirectory();
      final path = '${tmp.path}/$name';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(path, mimeType: 'application/octet-stream', name: name),
      ]);
    } else {
      final savePath = await FilePicker.platform.saveFile(
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['ebcp'],
        bytes: bytes,
      );
      if (savePath != null && !kIsWeb) {
        await File(savePath).writeAsBytes(bytes);
      }
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Opens a file picker for .ebcp files and returns the parsed [EbcpFile].
  /// Returns `null` if the user cancels or the file is invalid.
  static Future<EbcpFile?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ebcp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final Uint8List bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      return null;
    }

    return EbcpFile.fromEbcp(bytes);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String sanitizeName(String name) =>
      name.replaceAll(RegExp(r'[^\w\-. ]'), '_').trim();
}

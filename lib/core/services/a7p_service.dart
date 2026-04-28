import 'dart:io';

import 'package:a7p/a7p.dart';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'ebcp_service.dart';

Unit _offsetUnitValue(String value) =>
    Unit.values.firstWhere((u) => u.name == value, orElse: () => Unit.mil);

/// Converts the ammo angular zero offset to dimensionless click counts and
/// writes them into the a7p payload (a7p has no concept of click size).
///
/// Formula: clicks = offset_in_cm100m / click_size_in_cm100m
/// Stored as: zeroX = clicks × −1000 (sign flip), zeroY = clicks × +1000
void _setPayloadOffsets(ProfileExport profile, Payload payload) {
  if (profile.ammo == null || profile.sight == null) return;

  final ammo = profile.ammo!;
  final sight = profile.sight!;

  final clickX = sight.horizontalClick.convert(
    _offsetUnitValue(sight.horizontalClickUnit),
    Unit.cmPer100m,
  );
  final clickY = sight.verticalClick.convert(
    _offsetUnitValue(sight.verticalClickUnit),
    Unit.cmPer100m,
  );
  final offsetXCm = Angular(
    ammo.zeroOffsetX,
    _offsetUnitValue(ammo.zeroOffsetXUnit),
  ).in_(Unit.cmPer100m);
  final offsetYCm = Angular(
    ammo.zeroOffsetY,
    _offsetUnitValue(ammo.zeroOffsetYUnit),
  ).in_(Unit.cmPer100m);
  payload.profile.zeroX = (offsetXCm / clickX * -1000).round().clamp(
    -200000,
    200000,
  );
  payload.profile.zeroY = (offsetYCm / clickY * 1000).round().clamp(
    -200000,
    200000,
  );
}

abstract final class A7pService {
  static Future<void> shareFile(
    ProfileExport profile, [
    A7pRange? range,
  ]) async {
    final payload = A7pConverter.toPayload(profile, range);
    _setPayloadOffsets(profile, payload);
    final bytes = A7pFile.encode(payload);
    final name =
        '${EbcpService.sanitizeName(profile.name).replaceFirst(RegExp(r'^\.'), '')}.a7p';

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
        allowedExtensions: ['a7p'],
        bytes: bytes,
      );
      if (savePath != null && !kIsWeb) {
        await File(savePath).writeAsBytes(bytes);
      }
    }
  }

  /// Returns `null` if the user cancelled.
  /// Throws [A7pParseException] if the file is invalid.
  static Future<ProfileExport?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: Platform.isAndroid ? FileType.any : FileType.custom,
      allowedExtensions: Platform.isAndroid ? null : ['a7p'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (!file.name.toLowerCase().endsWith('.a7p')) {
      throw FormatException('Expected an .a7p file, got: ${file.name}');
    }

    final Uint8List bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      throw const A7pParseException('cannot read file bytes');
    }

    final payload = A7pFile.decode(bytes); // throws A7pParseException on error
    // Note: zeroX/zeroY are in dimensionless clicks — cannot reconstruct the
    // angular offset without knowing the sight's click size at import time.
    return A7pConverter.fromPayload(payload, validate: false);
  }

  /// Opens a single file picker accepting both .ebcp and .a7p files.
  /// Detects the format by file extension and returns the parsed profiles.
  /// Returns `null` if the user cancelled.
  /// Throws [A7pParseException] on invalid .a7p files or [Exception] on other errors.
  static Future<List<ProfileExport>?> pickAndParseProfiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: Platform.isAndroid ? FileType.any : FileType.custom,
      allowedExtensions: Platform.isAndroid ? null : ['ebcp', 'a7p'],
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
      throw const A7pParseException('cannot read file bytes');
    }

    final name = file.name.toLowerCase();
    if (name.endsWith('.a7p')) {
      final payload = A7pFile.decode(bytes);
      return [A7pConverter.fromPayload(payload, validate: false)];
    } else if (name.endsWith('.ebcp')) {
      final ebcp = EbcpFile.fromEbcp(bytes);
      if (ebcp == null) return [];
      return ebcp.items
          .map((i) => i.asProfile())
          .whereType<ProfileExport>()
          .toList();
    } else {
      throw FormatException(
        'Expected an .a7p or .ebcp file, got: ${file.name}',
      );
    }
  }
}

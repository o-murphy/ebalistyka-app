import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ebcp_item.dart';

part 'ebcp_file.g.dart';

const _kEntryName = 'ebalistyka.json';

/// Bump this when the .ebcp schema changes in a breaking way.
const kEbcpFormatVersion = '1.0.0';

@JsonSerializable()
class EbcpFile {
  const EbcpFile({this.version = kEbcpFormatVersion, required this.items});

  final String version;
  final List<EbcpItem> items;

  factory EbcpFile.fromJson(Map<String, dynamic> json) =>
      _$EbcpFileFromJson(json);

  Map<String, dynamic> toJson() => _$EbcpFileToJson(this);

  /// Encodes to a ZIP archive (.ebcp).
  Uint8List toEbcp() {
    final bytes = utf8.encode(jsonEncode(toJson()));
    final archive = Archive()
      ..addFile(ArchiveFile(_kEntryName, bytes.length, bytes));
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Decodes a .ebcp file. Returns `null` on any format error.
  static EbcpFile? fromEbcp(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entry = archive.findFile(_kEntryName);
      if (entry == null) return null;
      final json =
          jsonDecode(utf8.decode(entry.content as List<int>))
              as Map<String, dynamic>;
      return EbcpFile.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

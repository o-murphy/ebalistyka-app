// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ebcp_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EbcpFile _$EbcpFileFromJson(Map<String, dynamic> json) => EbcpFile(
  version: json['version'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => EbcpItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EbcpFileToJson(EbcpFile instance) => <String, dynamic>{
  'version': instance.version,
  'items': instance.items,
};

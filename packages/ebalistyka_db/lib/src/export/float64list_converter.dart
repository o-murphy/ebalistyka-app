import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

class Float64ListConverter
    implements JsonConverter<Float64List?, List<dynamic>?> {
  const Float64ListConverter();

  @override
  Float64List? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return Float64List.fromList(
      json.map((e) => (e as num).toDouble()).toList(),
    );
  }

  @override
  List<double>? toJson(Float64List? object) {
    if (object == null) return null;
    return object.toList();
  }
}

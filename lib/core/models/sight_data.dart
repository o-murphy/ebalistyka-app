import 'package:bclibc_ffi/unit.dart';
import 'package:uuid/uuid.dart';

class SightData {
  final String id;
  final String name;
  final String? manufacturer;
  final String? notes;

  SightData({String? id, required this.name, this.manufacturer, this.notes})
    : id = id ?? const Uuid().v4();

  SightData copyWith({
    String? name,
    String? manufacturer,
    Distance? sightHeight,
    Angular? zeroElevation,
    String? notes,
  }) => SightData(
    id: id,
    name: name ?? this.name,
    manufacturer: manufacturer ?? this.manufacturer,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (notes != null) 'notes': notes,
  };

  factory SightData.fromJson(Map<String, dynamic> json) => SightData(
    id: json['id'] as String,
    name: json['name'] as String,
    manufacturer: json['manufacturer'] as String?,
    notes: json['notes'] as String?,
  );
}

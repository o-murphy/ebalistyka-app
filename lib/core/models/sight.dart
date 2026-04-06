import 'package:bclibc_ffi/bclibc_ffi.dart';
import 'package:uuid/uuid.dart';

class Sight {
  final String id;
  final String name;
  final String? manufacturer;
  final String? notes;

  Sight({String? id, required this.name, this.manufacturer, this.notes})
    : id = id ?? const Uuid().v4();

  Sight copyWith({
    String? name,
    String? manufacturer,
    Distance? sightHeight,
    Angular? zeroElevation,
    String? notes,
  }) => Sight(
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

  factory Sight.fromJson(Map<String, dynamic> json) => Sight(
    id: json['id'] as String,
    name: json['name'] as String,
    manufacturer: json['manufacturer'] as String?,
    notes: json['notes'] as String?,
  );
}

import 'package:uuid/uuid.dart';

import '../solver/drag_model.dart';
import '_dim.dart';

class Projectile {
  final String id;
  final String name;
  final String? manufacturer;
  final DragModel dm;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Projectile({
    String? id,
    required this.name,
    this.manufacturer,
    required this.dm,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Projectile copyWith({
    String? name,
    String? manufacturer,
    DragModel? dm,
    String? notes,
  }) =>
      Projectile(
        id: id,
        name: name ?? this.name,
        manufacturer: manufacturer ?? this.manufacturer,
        dm: dm ?? this.dm,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (manufacturer != null) 'manufacturer': manufacturer,
        'dm': {
          'bc': dm.bc,
          'weight': dimToJson(dm.weight),
          'diameter': dimToJson(dm.diameter),
          'length': dimToJson(dm.length),
          'dragTable': dm.dragTable
              .map((p) => {'mach': p.mach, 'cd': p.cd})
              .toList(),
        },
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Projectile.fromJson(Map<String, dynamic> json) {
    final d = json['dm'] as Map;
    return Projectile(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String?,
      dm: DragModel(
        bc: (d['bc'] as num).toDouble(),
        dragTable: (d['dragTable'] as List)
            .map((p) => {'mach': p['mach'], 'cd': p['cd']})
            .toList(),
        weight: weightFromJson(d['weight'] as Map),
        diameter: distanceFromJson(d['diameter'] as Map),
        length: distanceFromJson(d['length'] as Map),
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

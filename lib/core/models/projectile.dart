import 'package:eballistica/core/solver/unit.dart';

import 'package:eballistica/core/solver/drag_model.dart';
import 'package:eballistica/core/solver/drag_tables.dart';
import '_storage.dart';

enum DragModelType { g1, g7, custom }

class CoeficientRow {
  final double bcCd;
  final double mv;

  const CoeficientRow({required this.bcCd, required this.mv});

  Map<String, dynamic> toJson() => {'bc_cd': bcCd, 'mv': mv};

  factory CoeficientRow.fromJson(Map<String, dynamic> json) => CoeficientRow(
    bcCd: (json['bc_cd'] as num).toDouble(),
    mv: (json['mv'] as num).toDouble(),
  );
}

class Projectile {
  final DragModelType dragType;
  final Weight weight;
  final Distance diameter;
  final Distance length;
  final List<CoeficientRow> coefRows;

  Projectile({
    this.dragType = DragModelType.custom,
    Weight? weight,
    Distance? diameter,
    Distance? length,
    List<CoeficientRow>? coefRows,
  }) : weight = weight ?? Weight(0, Unit.grain),
       diameter = diameter ?? Distance(0, Unit.inch),
       length = length ?? Distance(0, Unit.inch),
       coefRows = coefRows ?? const [];

  /// True when G1/G7 with multiple BC breakpoints (velocity-dependent BC).
  bool get isMultiBC => dragType != DragModelType.custom && coefRows.length > 1;

  /// Build a runtime [DragModel] for the ballistics solver.
  DragModel toDragModel() {
    switch (dragType) {
      case DragModelType.g1:
      case DragModelType.g7:
        final baseTable = dragType == DragModelType.g7 ? tableG7 : tableG1;
        if (coefRows.length <= 1) {
          final bc = coefRows.isEmpty || coefRows.first.bcCd == 0
              ? 1.0
              : coefRows.first.bcCd;
          return DragModel(
            bc: bc,
            dragTable: baseTable,
            weight: weight,
            diameter: diameter,
            length: length,
          );
        }
        // Multi-BC: mv values are in m/s
        final bcPoints = coefRows
            .map((r) => BCPoint(bc: r.bcCd, v: Velocity(r.mv, Unit.mps)))
            .toList();
        return createDragModelMultiBC(
          bcPoints: bcPoints,
          dragTable: baseTable,
          weight: weight,
          diameter: diameter,
          length: length,
        );
      case DragModelType.custom:
        // coefRows: bcCd = Cd, mv = Mach
        final table = coefRows.map((r) => (mach: r.mv, cd: r.bcCd)).toList();
        final sd = (weight.raw > 0 && diameter.raw > 0)
            ? calculateSectionalDensity(
                weight.in_(Unit.grain),
                diameter.in_(Unit.inch),
              )
            : 0.0;
        return DragModel(
          bc: sd > 0 ? sd : 1.0,
          dragTable: table.isNotEmpty ? table : tableG1,
          weight: weight,
          diameter: diameter,
          length: length,
        );
    }
  }

  Projectile copyWith({
    DragModelType? dragType,
    Weight? weight,
    Distance? diameter,
    Distance? length,
    List<CoeficientRow>? coefRows,
    String? notes,
  }) => Projectile(
    dragType: dragType ?? this.dragType,
    weight: weight ?? this.weight,
    diameter: diameter ?? this.diameter,
    length: length ?? this.length,
    coefRows: coefRows ?? this.coefRows,
  );

  Map<String, dynamic> toJson() => {
    'dragType': dragType.name,
    'weight': weight.in_(StorageUnits.projectileWeight),
    'diameter': diameter.in_(StorageUnits.projectileDiameter),
    'length': length.in_(StorageUnits.projectileLength),
    'coefRows': coefRows.map((r) => r.toJson()).toList(),
  };

  factory Projectile.fromJson(Map<String, dynamic> json) {
    final dragType = DragModelType.values.firstWhere(
      (t) => t.name == (json['dragType'] as String?),
      orElse: () => DragModelType.g1,
    );

    final coefRows =
        (json['coefRows'] as List?)
            ?.map((r) => CoeficientRow.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return Projectile(
      dragType: dragType,
      weight: Weight(
        (json['weight'] as num).toDouble(),
        StorageUnits.projectileWeight,
      ),
      diameter: Distance(
        (json['diameter'] as num).toDouble(),
        StorageUnits.projectileDiameter,
      ),
      length: Distance(
        (json['length'] as num).toDouble(),
        StorageUnits.projectileLength,
      ),
      coefRows: coefRows,
    );
  }
}

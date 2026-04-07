import 'package:uuid/uuid.dart';

import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';

import '_storage.dart';
import 'conditions_data.dart';

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

enum CartridgeType { cartridge, bullet }

class Cartridge {
  final String id;
  final String name;
  final String? projectileName;
  final String? vendor;
  final CartridgeType type;
  final DragModelType dragType;
  final Weight weight;
  final Distance diameter;
  final Distance length;
  final List<CoeficientRow> coefRows;
  final Velocity mv;
  final Temperature powderTemp;
  final Ratio powderSensitivity;

  // ── Zero data (belongs to cartridge, not profile) ──────────────────────────
  final Conditions zeroConditions;

  final String? notes;

  Cartridge({
    String? id,
    required this.name,
    this.projectileName,
    this.dragType = DragModelType.custom,
    Weight? weight,
    Distance? diameter,
    Distance? length,
    List<CoeficientRow>? coefRows,
    this.vendor,
    this.type = CartridgeType.cartridge,
    required this.mv,
    required this.powderTemp,
    required this.powderSensitivity,
    Conditions? zeroConditions,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       weight = weight ?? Weight.grain(0),
       diameter = diameter ?? Distance.inch(0),
       length = length ?? Distance.inch(0),
       coefRows = coefRows ?? const [],
       zeroConditions = zeroConditions ?? Conditions.withDefaults();

  /// True when G1/G7 with multiple BC breakpoints (velocity-dependent BC).
  bool get isMultiBC => dragType != DragModelType.custom && coefRows.length > 1;

  /// Build a runtime [DragModel] for the ballistics solver.
  bclibc.DragModel toDragModel() {
    switch (dragType) {
      case DragModelType.g1:
      case DragModelType.g7:
        final baseTable = dragType == DragModelType.g7
            ? bclibc.tableG7
            : bclibc.tableG1;
        if (coefRows.length <= 1) {
          final bc = coefRows.isEmpty || coefRows.first.bcCd == 0
              ? 1.0
              : coefRows.first.bcCd;
          return bclibc.DragModel(
            bc: bc,
            dragTable: baseTable,
            weight: weight,
            diameter: diameter,
            length: length,
          );
        }
        // Multi-BC: mv values are in m/s
        final bcPoints = coefRows
            .map((r) => bclibc.BCPoint(bc: r.bcCd, v: Velocity(r.mv, Unit.mps)))
            .toList();
        return bclibc.createDragModelMultiBC(
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
            ? bclibc.calculateSectionalDensity(
                weight.in_(Unit.grain),
                diameter.in_(Unit.inch),
              )
            : 0.0;
        return bclibc.DragModel(
          bc: sd > 0 ? sd : 1.0,
          dragTable: table.isNotEmpty ? table : bclibc.tableG1,
          weight: weight,
          diameter: diameter,
          length: length,
        );
    }
  }

  bclibc.Ammo toAmmo() => bclibc.Ammo(
    dm: toDragModel(),
    mv: mv,
    powderTemp: powderTemp,
    tempModifier: powderSensitivity.in_(Unit.fraction),
  );

  Cartridge copyWith({
    String? name,
    String? projectileName,
    String? vendor,
    CartridgeType? type,
    DragModelType? dragType,
    Weight? weight,
    Distance? diameter,
    Distance? length,
    List<CoeficientRow>? coefRows,
    Velocity? mv,
    Temperature? powderTemp,
    Ratio? powderSensitivity,
    Conditions? zeroConditions,
    String? notes,
  }) => Cartridge(
    id: id,
    name: name ?? this.name,
    projectileName: projectileName ?? this.projectileName,
    vendor: vendor ?? this.vendor,
    type: type ?? this.type,
    dragType: dragType ?? this.dragType,
    weight: weight ?? this.weight,
    diameter: diameter ?? this.diameter,
    length: length ?? this.length,
    coefRows: coefRows ?? this.coefRows,
    mv: mv ?? this.mv,
    powderTemp: powderTemp ?? this.powderTemp,
    powderSensitivity: powderSensitivity ?? this.powderSensitivity,
    zeroConditions: zeroConditions ?? this.zeroConditions,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (projectileName != null) 'vendor': projectileName,
    if (vendor != null) 'vendor': vendor,
    'type': type.name,
    'dragType': dragType.name,
    'weight': weight.in_(StorageUnits.projectileWeight),
    'diameter': diameter.in_(StorageUnits.projectileDiameter),
    'length': length.in_(StorageUnits.projectileLength),
    'coefRows': coefRows.map((r) => r.toJson()).toList(),
    'mv': mv.in_(StorageUnits.cartridgeMv),
    'powderTemp': powderTemp.in_(StorageUnits.cartridgePowderTemp),
    'powderSensitivity': powderSensitivity.in_(
      StorageUnits.cartridgePowderSensitivity,
    ),
    'zeroConditions': zeroConditions.toJson(),
    if (notes != null) 'notes': notes,
  };

  factory Cartridge.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = typeStr == 'bullet'
        ? CartridgeType.bullet
        : CartridgeType.cartridge;

    Conditions zeroConditions;

    if (json['zeroConditions'] != null) {
      zeroConditions = Conditions.fromJson(
        json['zeroConditions'] as Map<String, dynamic>,
      );
    } else {
      // Старий формат: створюємо Conditions з окремих полів
      final zeroDistance = json['zeroDistance'] != null
          ? Distance(
              (json['zeroDistance'] as num).toDouble(),
              StorageUnits.cartridgeZeroDistance,
            )
          : Distance.meter(100.0);

      final zeroAtmoJson = json['zeroConditions_legacy'] as Map?;
      final zeroAtmo = zeroAtmoJson != null
          ? AtmoData.fromJson(zeroAtmoJson)
          : null;

      final usePowderSensitivity =
          json['usePowderSensitivity'] as bool? ?? false;
      final useDiffPowderTemp = json['useDiffPowderTemp'] as bool? ?? false;

      zeroConditions = Conditions.withDefaults(
        atmo: zeroAtmo,
        distance: zeroDistance,
        usePowderSensitivity: usePowderSensitivity,
        useDiffPowderTemp: useDiffPowderTemp,
      );
    }

    final dragType = DragModelType.values.firstWhere(
      (t) => t.name == (json['dragType'] as String?),
      orElse: () => DragModelType.g1,
    );

    final coefRows =
        (json['coefRows'] as List?)
            ?.map((r) => CoeficientRow.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return Cartridge(
      id: json['id'] as String,
      name: json['name'] as String,
      projectileName: json['projectileName'] as String?,
      vendor: json['vendor'] as String?,
      type: type,
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
      mv: Velocity((json['mv'] as num).toDouble(), StorageUnits.cartridgeMv),
      powderTemp: Temperature(
        (json['powderTemp'] as num).toDouble(),
        StorageUnits.cartridgePowderTemp,
      ),
      powderSensitivity: Ratio(
        (json['powderSensitivity'] as num).toDouble(),
        StorageUnits.cartridgePowderSensitivity,
      ),
      zeroConditions: zeroConditions,
      notes: json['notes'] as String?,
    );
  }
}

extension CartridgeExtension on Cartridge {
  static Cartridge mock(String id, String name) {
    return Cartridge(
      id: id, // Додайте id, якщо його немає в моделі
      name: name,
      mv: Velocity.mps(800),
      powderTemp: Temperature.celsius(20),
      powderSensitivity: Ratio.fraction(0),
    );
  }
}

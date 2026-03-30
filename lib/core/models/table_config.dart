import 'package:eballistica/core/solver/unit.dart';

// ─── Table Configuration Model ────────────────────────────────────────────────
//
// Serialised inside AppSettings as 'tableConfig'.
// Controls the trajectory table's range, visible columns and details spoiler.

class TableConfig {
  // ── Range ──────────────────────────────────────────────────────────────────
  final double startM; // start distance, metres
  final double endM; // end distance,   metres
  final double stepM; // distance step,  metres

  // ── Extra tables ───────────────────────────────────────────────────────────
  final bool showZeros; // small zero-crossing table above main table
  final bool showSubsonicTransition; // highlight first subsonic row

  // ── Columns ────────────────────────────────────────────────────────────────
  /// IDs of columns that are hidden. 'range' is always visible.
  /// Column IDs: time, velocity, height, drop, adjDrop, wind, adjWind,
  ///             mach, drag, energy
  final Set<String> hiddenCols;

  /// false = show adjustment in [adjUnit] only
  /// true  = show one column per adjustment unit enabled in Adjustment Display
  final bool adjAllUnits;

  /// Override drop/windage unit for this table; null = use global unit.
  final Unit? dropUnit;

  /// Override adjustment unit for this table; null = use global unit.
  final Unit? adjUnit;

  const TableConfig({
    this.startM = 0,
    this.endM = 2000,
    this.stepM = 100,
    this.showZeros = true,
    this.showSubsonicTransition = false,
    this.hiddenCols = const {},
    this.adjAllUnits = false,
    this.dropUnit,
    this.adjUnit,
  });

  TableConfig copyWith({
    double? startM,
    double? endM,
    double? stepM,
    bool? showZeros,
    bool? showSubsonicTransition,
    Set<String>? hiddenCols,
    bool? adjAllUnits,
    Unit? dropUnit,
    Unit? adjUnit,
  }) {
    return TableConfig(
      startM: startM ?? this.startM,
      endM: endM ?? this.endM,
      stepM: stepM ?? this.stepM,
      showZeros: showZeros ?? this.showZeros,
      showSubsonicTransition:
          showSubsonicTransition ?? this.showSubsonicTransition,
      hiddenCols: hiddenCols ?? this.hiddenCols,
      adjAllUnits: adjAllUnits ?? this.adjAllUnits,
      dropUnit: dropUnit ?? this.dropUnit,
      adjUnit: adjUnit ?? this.adjUnit,
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'startM': startM,
    'endM': endM,
    'stepM': stepM,
    'showZeros': showZeros,
    'showSubsonicTransition': showSubsonicTransition,
    'hiddenCols': hiddenCols.toList(),
    'adjAllUnits': adjAllUnits,
    'dropUnit': dropUnit?.name,
    'adjUnit': adjUnit?.name,
  };

  factory TableConfig.fromJson(Map<String, dynamic> json) {
    bool b(String key, bool def) => json[key] as bool? ?? def;
    double d(String key, double default_) {
      return (json[key] as num?)?.toDouble() ?? default_;
    }

    Unit? u(String key) {
      final name = json[key] as String?;
      if (name == null) return null;
      return .fromName(name) ?? Unit.mil;
    }

    return TableConfig(
      startM: d('startM', 0),
      endM: d('endM', 2000),
      stepM: d('stepM', 100),
      showZeros: b('showZeros', true),
      showSubsonicTransition: b('showSubsonicTransition', false),
      hiddenCols: Set<String>.from(json['hiddenCols'] as List? ?? []),
      adjAllUnits: b('adjAllUnits', false),
      dropUnit: u('dropUnit'),
      adjUnit: u('adjUnit'),
    );
  }
}

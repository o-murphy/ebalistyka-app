import 'dart:math';

import 'package:test_app/src/constants.dart';
import 'package:test_app/src/drag_tables.dart';
import 'package:test_app/src/unit.dart';

class BCPoint {
  final double bc;
  final double mach;
  final Velocity? v;

  BCPoint({required this.bc, double? mach, Object? v})
    : mach = _calculateMach(mach, v),
      v = v != null ? PreferredUnits.velocity(v) : null {
    if (bc <= 0) {
      throw ArgumentError("Ballistic coefficient must be positive");
    }

    if (mach != null && v != null) {
      throw ArgumentError(
        "You cannot specify both 'mach' and 'v' at the same time",
      );
    }

    if (mach == null && v == null) {
      throw ArgumentError("One of 'mach' and 'v' must be specified");
    }
  }

  static double _calculateMach(double? mach, Object? v) {
    if (v != null) {
      final velocityObj = PreferredUnits.velocity(v);
      return velocityObj.in_(Unit.mps) / _machC();
    }
    return mach ?? 0.0;
  }

  static double _machC() {
    return sqrt(
          BallisticConstants.cStandardTemperatureC +
              BallisticConstants.cDegreesCtoK,
        ) *
        BallisticConstants.cSpeedOfSoundMetric;
  }

  @override
  String toString() => 'BCPoint(BC: $bc, Mach: ${mach.toStringAsFixed(3)})';
}

class DragModel {
  final double bc;
  final List<DragDataPoint> dragTable;
  final Weight weight;
  final Distance diameter;
  final Distance length;

  late final double _sectionalDensity;
  late final double _formFactor;

  DragModel({
    required this.bc,
    required List<dynamic>
    dragTable, // Може бути списком BCPoint або сирих даних
    Object? weight,
    Object? diameter,
    Object? length,
  }) : dragTable = makeDataPoints(dragTable),
       weight = PreferredUnits.weight(weight ?? 0),
       diameter = PreferredUnits.diameter(diameter ?? 0),
       length = PreferredUnits.length(length ?? 0) {
    if (this.dragTable.isEmpty) {
      throw ArgumentError("Received empty drag table");
    }
    if (bc <= 0) {
      throw ArgumentError("Ballistic coefficient must be positive");
    }

    if (this.weight.rawValue > 0 && this.diameter.rawValue > 0) {
      _sectionalDensity = _getSectionalDensity();
      _formFactor = _getFormFactor(bc);
    } else {
      _sectionalDensity = 0.0;
      _formFactor = 0.0;
    }
  }

  double _getSectionalDensity() {
    // Get weight in grains and diameter in inches
    final w = weight.in_(Unit.grain);
    final d = diameter.in_(Unit.inch);
    // Call the sectionalDensity function to calculate and return the result
    return sectionalDensity(w, d);
  }

  double _getFormFactor(double bcValue) {
    return _sectionalDensity / bc;
  }
}

List<DragDataPoint> makeDataPoints(List<dynamic> table) {
  return table.map((point) {
    return switch (point) {
      DragDataPoint p => p,

      Map<String, dynamic> m
          when m.containsKey('mach') && m.containsKey('cd') =>
        (mach: (m['mach'] as num).toDouble(), cd: (m['cd'] as num).toDouble()),

      Map<String, dynamic> m
          when m.containsKey('Mach') && m.containsKey('CD') =>
        (mach: (m['Mach'] as num).toDouble(), cd: (m['CD'] as num).toDouble()),

      _ => throw TypeError(),
    };
  }).toList();
}

double sectionalDensity(double weight, diameter) {
  return weight / pow(diameter, 2) / 7000;
}

List<double> linearInterpolation(
  List<double> x,
  List<double> xp,
  List<double> yp,
) {
  if (xp.length != yp.length) {
    throw ArgumentError("xp and yp lists must have the same length");
  }
  if (xp.isEmpty) {
    return x.isEmpty
        ? []
        : throw ArgumentError(
            "Cannot interpolate with empty reference points.",
          );
  }

  return x.map((xi) {
    if (xi <= xp.first) return yp.first;
    if (xi >= xp.last) return yp.last;

    int left = 0;
    int right = xp.length - 1;
    while (left < right - 1) {
      int mid = (left + right) ~/ 2;
      if (xi < xp[mid]) {
        right = mid;
      } else {
        left = mid;
      }
    }

    final double dx = xp[right] - xp[left];
    final double dy = yp[right] - yp[left];
    final double slope = dy / dx;

    return yp[left] + slope * (xi - xp[left]);
  }).toList();
}

DragModel createDragModelMultiBC({
  required List<BCPoint> bcPoints,
  required List<dynamic> dragTable,
  Object? weight,
  Object? diameter,
  Object? length,
}) {
  final Weight wObj = PreferredUnits.weight(weight ?? 0);
  final Distance dObj = PreferredUnits.diameter(diameter ?? 0);

  double baseBc;
  if (wObj.rawValue > 0 && dObj.rawValue > 0) {
    baseBc = sectionalDensity(wObj.in_(Unit.grain), dObj.in_(Unit.inch));
  } else {
    baseBc = 1.0;
  }

  final List<DragDataPoint> sourceTable = makeDataPoints(dragTable);
  final List<BCPoint> sortedBC = List.from(bcPoints)
    ..sort((a, b) => a.mach.compareTo(b.mach));

  final List<double> bcFactors = linearInterpolation(
    sourceTable.map((p) => p.mach).toList(),
    sortedBC.map((p) => p.mach).toList(),
    sortedBC.map((p) => p.bc / baseBc).toList(),
  );

  final List<DragDataPoint> adjustedTable = [];
  for (int i = 0; i < sourceTable.length; i++) {
    final double factor = bcFactors[i];

    final double finalCd = (factor > 0 && !factor.isNaN)
        ? sourceTable[i].cd / factor
        : sourceTable[i].cd;

    adjustedTable.add((mach: sourceTable[i].mach, cd: finalCd));
  }

  return DragModel(
    bc: baseBc,
    dragTable: adjustedTable,
    weight: wObj,
    diameter: dObj,
    length: length,
  );
}

import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

extension AmmoDragModelFormattedInfo on Ammo {
  String get dragModelFormattedInfo {
    final bcAcc = FC.ballisticCoefficient.accuracy;

    final firstBc = switch (dragType) {
      DragType.g7 => bcG7,
      DragType.g1 => bcG1,
      DragType.custom => 0.0,
    };
    return switch (dragType) {
      DragType.g1 =>
        isMultiBC ? 'G1 Multi' : 'G1 ${firstBc.toStringAsFixed(bcAcc)}',
      DragType.g7 =>
        isMultiBC ? 'G7 Multi' : 'G7 ${firstBc.toStringAsFixed(bcAcc)}',
      DragType.custom => 'CUSTOM',
    };
  }
}

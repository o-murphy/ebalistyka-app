import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:ebalistyka/shared/models/chart_point.dart';
import 'package:ebalistyka/shared/models/formatted_row.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';

// ── State ────────────────────────────────────────────────────────────────────

class HomeConditionsUiState {
  final double windAngleDeg;
  final String tempDisplay;
  final String altDisplay;
  final String pressDisplay;
  final String humidDisplay;
  final double targetDistanceM;

  const HomeConditionsUiState({
    this.windAngleDeg = 0.0,
    this.tempDisplay = '',
    this.altDisplay = '',
    this.pressDisplay = '',
    this.humidDisplay = '',
    this.targetDistanceM = 0.0,
  });
}

class ReticleUiState {
  final String? reticleId;
  final String? targetId;
  final double targetSizeMilAtDistance;
  final String? adjustedMessageLine;
  final String? zeroOffsetMessageLine;
  final String cartridgeInfoLine;
  final AdjustmentData adjustment;
  final AdjustmentDisplayFormat adjustmentFormat;
  final double adjustmentElevMil;
  final double adjustmentWindMil;

  const ReticleUiState({
    this.reticleId,
    this.targetId,
    this.targetSizeMilAtDistance = 0.0,
    this.adjustedMessageLine,
    this.zeroOffsetMessageLine,
    this.cartridgeInfoLine = '',
    required this.adjustment,
    this.adjustmentFormat = AdjustmentDisplayFormat.arrows,
    this.adjustmentElevMil = 0.0,
    this.adjustmentWindMil = 0.0,
  });
}

sealed class HomeUiState {
  const HomeUiState();
}

class HomeChartUiState {
  final ChartData chartData;
  final HomeChartPointInfo? selectedPointInfo;
  final int? selectedChartIndex;

  const HomeChartUiState({
    required this.chartData,
    this.selectedPointInfo,
    this.selectedChartIndex,
  });

  HomeChartUiState withSelection(HomeChartPointInfo info, int index) =>
      HomeChartUiState(
        chartData: chartData,
        selectedPointInfo: info,
        selectedChartIndex: index,
      );
}

class HomeUiReady extends HomeUiState {
  final String profileName;
  final String weaponName;
  final String ammoName;

  final HomeConditionsUiState conditionsState;
  final ReticleUiState reticleState;
  final FormattedTableData tableData;
  final HomeChartUiState chartState;

  const HomeUiReady({
    required this.profileName,
    required this.weaponName,
    required this.ammoName,
    required this.conditionsState,
    required this.reticleState,
    required this.tableData,
    required this.chartState,
  });
}

class HomeUiNoData extends HomeUiState {
  final String? message;
  final EmptyStateType type;
  const HomeUiNoData({this.message, this.type = EmptyStateType.noData});
}

class HomeUiError extends HomeUiState {
  final String message;
  const HomeUiError(this.message);
}

class HomeChartPointInfo {
  final String distance;
  final String velocity;
  final String energy;
  final String time;
  final String height;
  final String drop;
  final String windage;
  final String mach;

  const HomeChartPointInfo({
    required this.distance,
    required this.velocity,
    required this.energy,
    required this.time,
    required this.height,
    required this.drop,
    required this.windage,
    required this.mach,
  });
}

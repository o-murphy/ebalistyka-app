// Generate Play-Store-ready screenshots:
//   flutter test --update-goldens test/screenshots/
//
// Output:
//   screenshots/en/phoneScreenshots/      — 1080×1920 (9:16, "highly recommended")
//   screenshots/en/sevenInchScreenshots/  — 1200×1920 physical
//   screenshots/en/tenInchScreenshots/    — 1600×2560 physical

import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/features/home/widgets/home_chart_page.dart';
import 'package:ebalistyka/features/home/widgets/home_reticle_page.dart';
import 'package:ebalistyka/features/home/widgets/home_table_page.dart';
import 'package:ebalistyka/features/tables/details_table_mv.dart';
import 'package:ebalistyka/features/tables/widgets/details_table.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:ebalistyka/shared/models/chart_point.dart';
import 'package:ebalistyka/shared/models/formatted_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';

// ── Devices ───────────────────────────────────────────────────────────────────

// Phone portrait 9:16 — 1080×1920 physical (360×640 logical) — Play Store "highly recommended"
final _phone = ScreenshotDevice(
  platform: TargetPlatform.android,
  resolution: const Size(1080, 1920),
  pixelRatio: 3.0,
  goldenSubFolder: 'phoneScreenshots/',
  frameBuilder: ScreenshotFrame.androidPhone,
);

// 7" portrait — 1200×1920 physical (600×960 logical)
final _tablet7 = ScreenshotDevice(
  platform: TargetPlatform.android,
  resolution: const Size(1200, 1920),
  pixelRatio: 2.0,
  goldenSubFolder: 'sevenInchScreenshots/',
  frameBuilder: ScreenshotFrame.androidTablet,
);

// 10" portrait — 1600×2560 physical (800×1280 logical)
final _tablet10 = ScreenshotDevice(
  platform: TargetPlatform.android,
  resolution: const Size(1600, 2560),
  pixelRatio: 2.0,
  goldenSubFolder: 'tenInchScreenshots/',
  frameBuilder: ScreenshotFrame.androidTablet,
);

final _allDevices = [_phone, _tablet7, _tablet10];

// ── Fake ViewModel ────────────────────────────────────────────────────────────

class _FakeHomeVM extends HomeViewModel {
  final HomeUiState _state;
  _FakeHomeVM(this._state);

  @override
  Future<HomeUiState> build() async => _state;

  @override
  void selectChartPoint(int index) {}
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _homeState = HomeUiReady(
  profileName: 'Tactical .308',
  weaponName: 'Remington 700',
  ammoName: '.308 Win 175gr Sierra',
  conditionsState: const HomeConditionsUiState(
    windAngleDeg: 90.0,
    tempDisplay: '20 °C',
    altDisplay: '150 m',
    pressDisplay: '1013 hPa',
    humidDisplay: '50 %',
    targetDistanceM: 500.0,
  ),
  reticleState: ReticleUiState(
    cartridgeInfoLine: '.308 Win 175gr · G7 · 800 m/s',
    adjustment: const AdjustmentData(
      elevation: [
        AdjustmentValue(
          absValue: 3.2,
          isPositive: true,
          symbol: 'MRAD',
          decimals: 2,
        ),
      ],
      windage: [
        AdjustmentValue(
          absValue: 0.8,
          isPositive: false,
          symbol: 'MRAD',
          decimals: 2,
        ),
      ],
    ),
    adjustmentFormat: AdjustmentDisplayFormat.arrows,
  ),
  tableData: const FormattedTableData(
    distanceHeaders: ['100', '200', '300', '400', '500'],
    distanceUnit: 'm',
    rows: [
      FormattedRow(
        label: 'V',
        unitSymbol: 'm/s',
        cells: [
          FormattedCell(value: '790'),
          FormattedCell(value: '760'),
          FormattedCell(value: '730'),
          FormattedCell(value: '700'),
          FormattedCell(value: '670', isTargetColumn: true),
        ],
      ),
      FormattedRow(
        label: 'Drop',
        unitSymbol: 'cm',
        cells: [
          FormattedCell(value: '-2.1'),
          FormattedCell(value: '-8.5'),
          FormattedCell(value: '-19.2'),
          FormattedCell(value: '-35.0'),
          FormattedCell(value: '-56.0', isTargetColumn: true),
        ],
      ),
      FormattedRow(
        label: 'Wind',
        unitSymbol: 'cm',
        cells: [
          FormattedCell(value: '1.2'),
          FormattedCell(value: '4.8'),
          FormattedCell(value: '10.9'),
          FormattedCell(value: '19.4'),
          FormattedCell(value: '30.5', isTargetColumn: true),
        ],
      ),
    ],
  ),
  chartState: HomeChartUiState(
    chartData: ChartData(
      points: const [
        ChartPoint(
          distanceM: 0,
          heightCm: 0,
          velocityMps: 800,
          mach: 2.3,
          energyJ: 3200,
          time: 0,
          dropAngleMil: 0,
          windageAngleMil: 0,
        ),
        ChartPoint(
          distanceM: 100,
          heightCm: 3.2,
          velocityMps: 790,
          mach: 2.3,
          energyJ: 3100,
          time: 0.125,
          dropAngleMil: 0.3,
          windageAngleMil: 0.1,
        ),
        ChartPoint(
          distanceM: 200,
          heightCm: 2.1,
          velocityMps: 760,
          mach: 2.2,
          energyJ: 2890,
          time: 0.256,
          dropAngleMil: -0.8,
          windageAngleMil: 0.2,
        ),
        ChartPoint(
          distanceM: 300,
          heightCm: -4.5,
          velocityMps: 730,
          mach: 2.1,
          energyJ: 2680,
          time: 0.392,
          dropAngleMil: -1.9,
          windageAngleMil: 0.4,
        ),
        ChartPoint(
          distanceM: 400,
          heightCm: -17.3,
          velocityMps: 700,
          mach: 2.0,
          energyJ: 2460,
          time: 0.535,
          dropAngleMil: -3.5,
          windageAngleMil: 0.6,
        ),
        ChartPoint(
          distanceM: 500,
          heightCm: -38.2,
          velocityMps: 670,
          mach: 1.9,
          energyJ: 2250,
          time: 0.686,
          dropAngleMil: -5.8,
          windageAngleMil: 0.9,
        ),
      ],
      snapDistM: 100,
    ),
    selectedPointInfo: const HomeChartPointInfo(
      distance: '500 m',
      velocity: '670 m/s',
      energy: '2250 J',
      time: '0.69 s',
      height: '-38.2 cm',
      drop: '-5.80 MRAD',
      windage: '0.90 MRAD',
      mach: '1.90',
    ),
    selectedChartIndex: 5,
  ),
);

const _shotDetails = DetailsTableData(
  weaponName: 'Remington 700',
  caliber: '7.62 mm',
  twist: '1:11"',
  dragModel: 'G7',
  bc: '0.301',
  zeroMv: '800 m/s',
  currentMv: '797 m/s',
  zeroDist: '100 m',
  bulletLen: '33.0 mm',
  bulletDiam: '7.82 mm',
  bulletWeight: '11.3 g',
  formFactor: '0.980',
  sectionalDensity: '0.295',
  gyroStability: '1.42',
  temperature: '20 °C',
  humidity: '50 %',
  pressure: '1013 hPa',
  windSpeed: '5.0 m/s',
  windDir: '90°',
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _scope(Widget app) => ProviderScope(
  overrides: [homeVmProvider.overrideWith(() => _FakeHomeVM(_homeState))],
  child: app,
);

void _screenshot(
  String name,
  Widget Function() factory, {
  List<ScreenshotDevice>? devices,
}) {
  testGoldens(name, (tester) async {
    for (final device in devices ?? _allDevices) {
      await tester.pumpWidget(
        _scope(
          ScreenshotApp(
            device: device,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(body: factory()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.expectScreenshot(device, name);
    }
  });
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(loadAppFonts);
  ScreenshotDevice.screenshotsFolder = 'screenshots/';

  _screenshot('1_chart', () => const HomeChartPage());
  _screenshot('2_table', () => const HomeTablePage());
  _screenshot('3_reticle', () => const HomeReticlePage());
  _screenshot('4_shot_details', () => const DetailsTableContent(details: _shotDetails));
}

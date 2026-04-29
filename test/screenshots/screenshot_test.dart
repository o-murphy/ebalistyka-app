// Generate Play-Store-ready screenshots using the real database and solver.
//
//   flutter test --update-goldens test/screenshots/
//
// Output:
//   screenshots/en/phoneScreenshots/      — 1080×1920 (9:16, "highly recommended")
//   screenshots/en/sevenInchScreenshots/  — 1200×1920 physical
//   screenshots/en/tenInchScreenshots/    — 1600×2560 physical

import 'dart:io';

import 'package:ebalistyka/core/providers/db_provider.dart';
import 'package:ebalistyka/features/home/home_screen.dart';
import 'package:ebalistyka/features/home/widgets/home_chart_page.dart';
import 'package:ebalistyka/features/home/widgets/home_reticle_page.dart';
import 'package:ebalistyka/features/home/widgets/home_table_page.dart';
import 'package:ebalistyka/features/tables/details_table_mv.dart';
import 'package:ebalistyka/features/tables/widgets/details_table.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:path_provider/path_provider.dart';

// ── Devices ───────────────────────────────────────────────────────────────────

// Phone portrait 9:16 — 1080×1920 physical (360×640 logical)
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

// ── App theme (mirrors main.dart) ─────────────────────────────────────────────

final _darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ),
);

// ── Database ──────────────────────────────────────────────────────────────────

Store? _store;

Future<String?> _findDbPath() async {
  // path_provider returns the same dir the production app uses on Linux
  try {
    final dir = await getApplicationSupportDirectory();
    if (await File('${dir.path}/data.mdb').exists()) return dir.path;
  } catch (_) {}

  // Fallback: common Linux XDG path
  final home = Platform.environment['HOME'] ?? '';
  for (final name in ['ebalistyka', 'com.o.murphy.ebalistyka']) {
    final path = '$home/.local/share/$name';
    if (await File('$path/data.mdb').exists()) return path;
  }
  return null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _scope(Widget app) {
  if (_store == null) return app;
  return ProviderScope(
    overrides: [dbProvider.overrideWithValue(_store!)],
    child: app,
  );
}

void _screenshot(String name, Widget Function() factory) {
  testGoldens(name, (tester) async {
    for (final device in _allDevices) {
      await tester.pumpWidget(
        _scope(
          ScreenshotApp(
            device: device,
            darkTheme: _darkTheme,
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(body: factory()),
          ),
        ),
      );
      // Wait for DB queries, async providers, and the ballistics solver (compute).
      await tester.pumpAndSettle();
      await tester.expectScreenshot(device, name);
    }
  });
}

// ── Fixture for DetailsTableContent (no provider needed) ─────────────────────

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

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await loadAppFonts();

    // Register the bundled monospace font so 'fontFamily: monospace' renders.
    final monoLoader = FontLoader('monospace')
      ..addFont(rootBundle.load('assets/fonts/DejaVuSansMono.ttf'))
      ..addFont(rootBundle.load('assets/fonts/DejaVuSansMono-Bold.ttf'));
    await monoLoader.load();

    final dbPath = await _findDbPath();
    if (dbPath != null) {
      _store = await initObjectBox(directory: dbPath);
    } else {
      debugPrint('Screenshot test: database not found, screens will show empty state.');
    }
  });

  tearDownAll(() => _store?.close());

  ScreenshotDevice.screenshotsFolder = 'screenshots/';

  _screenshot('0_home', () => const HomeScreen());
  _screenshot('1_chart', () => const HomeChartPage());
  _screenshot('2_table', () => const HomeTablePage());
  _screenshot('3_reticle', () => const HomeReticlePage());
  _screenshot(
    '4_shot_details',
    () => const DetailsTableContent(details: _shotDetails),
  );
}

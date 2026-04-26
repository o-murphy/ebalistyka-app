import 'dart:io';
import 'dart:ui';

import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/shared/helpers/is_desktop.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/providers/db_provider.dart';
import 'core/providers/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';

// Constants for window sizes
const _windowMinWidth = 320.0;
const _windowMinHeight = 600.0;
// const _windowMaxWidth = 1000.0;
// const _windowMaxHeight = 1080.0;
const _windowInitialWidth = 375.0;
const _windowInitialHeight = 812.0;

// Constants for content restrictions
// const _contentMaxWidth = _windowMaxWidth;
// const _contentMaxHeight = _windowMaxHeight;

Future<(Store, bool)> _openStore(String directory) async {
  final hadData = await File('$directory/data.mdb').exists();
  try {
    return (await initObjectBox(directory: directory), false);
  } catch (e) {
    debugPrint('ObjectBox open failed — resetting DB: $e');
    for (final name in const ['data.mdb', 'lock.mdb']) {
      final f = File('$directory/$name');
      if (await f.exists()) await f.delete();
    }
    return (await initObjectBox(directory: directory), hadData);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();

    final double ratio =
        PlatformDispatcher.instance.views.first.devicePixelRatio;

    final size = Size(
      _windowInitialWidth * ratio,
      _windowInitialHeight * ratio,
    );
    final minSize = Size(_windowMinWidth * ratio, _windowMinHeight * ratio);

    WindowOptions windowOptions = WindowOptions(
      size: size,
      minimumSize: minSize,
      center: true,
      title: 'eBalistyka',
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.setIcon('assets/icon.png');
      await windowManager.focus();

      await windowManager.setMinimumSize(minSize);
      await windowManager.setMaximizable(false);
    });
  }

  final appSupport = await getApplicationSupportDirectory();
  final (store, dbWasReset) = await _openStore(appSupport.path);
  debugPrint("DB path: ${appSupport.path}");

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(store),
        dbWasResetProvider.overrideWithValue(dbWasReset),
      ],
      child: const MyApp(),
    ),
  );
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class _DbResetBanner extends ConsumerStatefulWidget {
  const _DbResetBanner({required this.child});
  final Widget child;

  @override
  ConsumerState<_DbResetBanner> createState() => _DbResetBannerState();
}

class _DbResetBannerState extends ConsumerState<_DbResetBanner> {
  @override
  void initState() {
    super.initState();
    if (ref.read(dbWasResetProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Database was corrupted and has been reset. All data has been cleared.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: "eBalistyka",
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      routerConfig: appRouter,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      scrollBehavior: _AppScrollBehavior(),
      builder: (context, child) {
        final inner = _DbResetBanner(child: child!);
        if (isDesktop) {
          return Center(child: Container(child: inner));
        }
        return inner;
      },
    );
  }
}

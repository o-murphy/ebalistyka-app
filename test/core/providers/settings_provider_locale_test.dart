// flutter test test/core/providers/settings_provider_locale_test.dart

import 'dart:io';

import 'package:ebalistyka/core/providers/db_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late TestWidgetsFlutterBinding binding;
  late Store store;
  late Directory tmpDir;

  setUpAll(() {
    binding = TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('settings_locale_test_');
    store = await initObjectBox(directory: tmpDir.path);
  });

  tearDown(() {
    binding.platformDispatcher.clearLocaleTestValue();
    store.close();
    tmpDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() =>
      ProviderContainer(overrides: [dbProvider.overrideWithValue(store)]);

  Future<GeneralSettings> waitForSettings(ProviderContainer c) =>
      c.read(settingsProvider.future);

  group('first launch — locale auto-resolved from system', () {
    test('Ukrainian system locale → languageCode = "uk"', () async {
      binding.platformDispatcher.localeTestValue = const Locale('uk');

      final container = makeContainer();
      addTearDown(container.dispose);

      final settings = await waitForSettings(container);
      expect(settings.languageCode, 'uk');
    });

    test('English system locale → languageCode = "en"', () async {
      binding.platformDispatcher.localeTestValue = const Locale('en');

      final container = makeContainer();
      addTearDown(container.dispose);

      final settings = await waitForSettings(container);
      expect(settings.languageCode, 'en');
    });

    test('Unsupported system locale → fallback to "en"', () async {
      binding.platformDispatcher.localeTestValue = const Locale('fr');

      final container = makeContainer();
      addTearDown(container.dispose);

      final settings = await waitForSettings(container);
      expect(settings.languageCode, 'en');
    });
  });

  group('subsequent launch — reads saved value, ignores system locale', () {
    test(
      'saved "uk" is returned even if system locale changed to "en"',
      () async {
        // First launch: system = 'uk' → saved to DB
        binding.platformDispatcher.localeTestValue = const Locale('uk');
        final c1 = makeContainer();
        await waitForSettings(c1);
        c1.dispose();

        // System locale changes to 'en', but DB already has 'uk'
        binding.platformDispatcher.localeTestValue = const Locale('en');
        final c2 = makeContainer();
        addTearDown(c2.dispose);

        final settings = await waitForSettings(c2);
        expect(settings.languageCode, 'uk');
      },
    );
  });
}

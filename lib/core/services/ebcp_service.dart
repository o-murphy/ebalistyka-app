import 'dart:io';

import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

abstract final class EbcpService {
  // ── Export ──────────────────────────────────────────────────────────────────

  static Future<void> shareFile(EbcpFile file, String fileName) async {
    final bytes = file.toEbcp();
    final name =
        '${EbcpService.sanitizeName(fileName).replaceFirst(RegExp(r'^\.'), '')}.ebcp';

    if (Platform.isAndroid || Platform.isIOS) {
      final tmp = await getTemporaryDirectory();
      final path = '${tmp.path}/$name';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(path, mimeType: 'application/octet-stream', name: name),
      ]);
    } else {
      final savePath = await FilePicker.platform.saveFile(
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['ebcp'],
        bytes: bytes,
      );
      if (savePath != null && !kIsWeb) {
        await File(savePath).writeAsBytes(bytes);
      }
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Opens a file picker for .ebcp files and returns the parsed [EbcpFile].
  /// Returns `null` if the user cancels or the file is invalid.
  static Future<EbcpFile?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: Platform.isAndroid ? FileType.any : FileType.custom,
      allowedExtensions: Platform.isAndroid ? null : ['ebcp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (!file.name.toLowerCase().endsWith('.ebcp')) {
      throw FormatException('Expected an .ebcp file, got: ${file.name}');
    }

    final Uint8List bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      return null;
    }

    return EbcpFile.fromEbcp(bytes);
  }

  // ── Full backup ─────────────────────────────────────────────────────────────

  /// Builds a full [EbcpFile] from the current DB state:
  /// all profiles (with weapon/ammo/sight embedded) +
  /// standalone ammo/sights not linked to any profile +
  /// all settings as a single nested item.
  static EbcpFile buildFullExport(WidgetRef ref) {
    final appState = ref.read(appStateProvider).value;
    final generalSettings = ref.read(settingsProvider).value;
    final unitSettings = ref.read(unitSettingsNotifierProvider).value;
    final tablesSettings = ref.read(tablesSettingsNotifierProvider).value;
    final conditions = ref.read(shotConditionsProvider).value;

    final items = <EbcpItem>[];

    if (appState != null) {
      // IDs already exported as part of a profile — skip standalone.
      final linkedAmmoIds = appState.profiles
          .map((p) => p.ammo.targetId)
          .where((id) => id != 0)
          .toSet();
      final linkedSightIds = appState.profiles
          .map((p) => p.sight.targetId)
          .where((id) => id != 0)
          .toSet();

      for (final profile in appState.profiles) {
        final weapon = appState.weapons
            .where((w) => w.id == profile.weapon.targetId)
            .firstOrNull;
        if (weapon == null) continue;
        final ammo = appState.cartridges
            .where((a) => a.id == profile.ammo.targetId)
            .firstOrNull;
        final sight = appState.sights
            .where((s) => s.id == profile.sight.targetId)
            .firstOrNull;
        items.add(
          EbcpItem.fromProfile(
            ProfileExport.fromEntities(profile, weapon, ammo, sight),
          ),
        );
      }

      for (final ammo in appState.cartridges) {
        if (!linkedAmmoIds.contains(ammo.id)) {
          items.add(EbcpItem.fromAmmo(AmmoExport.fromEntity(ammo)));
        }
      }

      for (final sight in appState.sights) {
        if (!linkedSightIds.contains(sight.id)) {
          items.add(EbcpItem.fromSight(SightExport.fromEntity(sight)));
        }
      }
    }

    if (generalSettings != null &&
        unitSettings != null &&
        tablesSettings != null &&
        conditions != null) {
      final reticleSettings = ref.read(reticleSettingsProvider);
      items.add(
        EbcpItem.fromSettings(
          SettingsExport.fromEntities(
            generalSettings,
            unitSettings,
            tablesSettings,
            conditions,
            reticleSettings,
          ),
        ),
      );
    }

    return EbcpFile(items: items);
  }

  /// Restores all entities from an [EbcpFile] into the DB via Riverpod notifiers.
  static Future<void> restoreFromExport(EbcpFile file, WidgetRef ref) async {
    for (final item in file.items) {
      final profile = item.asProfile();
      if (profile != null) {
        await ref.read(appStateProvider.notifier).importProfile(profile);
        continue;
      }
      final ammo = item.asAmmo();
      if (ammo != null) {
        await ref.read(appStateProvider.notifier).importAmmo(ammo);
        continue;
      }
      final sight = item.asSight();
      if (sight != null) {
        await ref.read(appStateProvider.notifier).importSight(sight);
        continue;
      }
      final settings = item.asSettings();
      if (settings != null) {
        await ref.read(settingsProvider.notifier).restore(settings.general);
        await ref
            .read(unitSettingsNotifierProvider.notifier)
            .restore(settings.units);
        await ref
            .read(tablesSettingsNotifierProvider.notifier)
            .restore(settings.tables);
        await ref
            .read(shotConditionsProvider.notifier)
            .restore(settings.conditions);
        await ref
            .read(reticleSettingsNotifierProvider.notifier)
            .restore(settings.reticle);
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String sanitizeName(String name) =>
      name.replaceAll(RegExp(r'[^\w\-. ]'), '_').trim();
}

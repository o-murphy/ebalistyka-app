import '../src/models/app_settings.dart';
import '../src/models/cartridge.dart';
import '../src/models/rifle.dart';
import '../src/models/shot_profile.dart';
import '../src/models/sight.dart';

abstract interface class AppStorage {
  // Settings
  Future<AppSettings?> loadSettings();
  Future<void> saveSettings(AppSettings s);

  // Current profile
  Future<ShotProfile?> loadCurrentProfile();
  Future<void> saveCurrentProfile(ShotProfile p);

  // Rifles
  Future<List<Rifle>> loadRifles();
  Future<void> saveRifle(Rifle r);
  Future<void> deleteRifle(String id);

  // Cartridges
  Future<List<Cartridge>> loadCartridges();
  Future<void> saveCartridge(Cartridge c);
  Future<void> deleteCartridge(String id);

  // Sights
  Future<List<Sight>> loadSights();
  Future<void> saveSight(Sight s);
  Future<void> deleteSight(String id);

  // Import / Export
  Future<Map<String, dynamic>> exportAll();
  Future<void> importAll(Map<String, dynamic> data);
}

import 'dart:io';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:test/test.dart';

void main() {
  late Store store;
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('ebalistyka_db_test_');
    store = await initObjectBox(directory: tmpDir.path);
  });

  tearDown(() {
    store.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('Owner', () {
    test('can create and retrieve owner by token', () {
      final box = store.box<Owner>();
      final owner = Owner()..token = 'local';
      final id = box.put(owner);

      final found = box.query(Owner_.token.equals('local')).build().findFirst();
      expect(found, isNotNull);
      expect(found!.id, id);
      expect(found.token, 'local');
    });
  });

  group('Weapon', () {
    test('stores and retrieves fields', () {
      final owner = Owner()..token = 'local';
      store.box<Owner>().put(owner);

      final weapon = Weapon()
        ..name = 'Test Rifle'
        ..caliberInch = 0.308
        ..twistInch = 11.0
        ..zeroElevationRad = 0.001
        ..owner.target = owner;

      final id = store.box<Weapon>().put(weapon);
      final found = store.box<Weapon>().get(id)!;

      expect(found.name, 'Test Rifle');
      expect(found.caliberInch, closeTo(0.308, 1e-6));
      expect(found.twistInch, closeTo(11.0, 1e-6));
      expect(found.zeroElevationRad, closeTo(0.001, 1e-9));
      expect(found.owner.targetId, owner.id);
    });
  });

  group('Sight', () {
    test('stores focalPlane as string', () {
      final sight = Sight()
        ..name = 'Vortex Razor'
        ..focalPlaneValue = 'ffp'
        ..sightHeightInch = 1.5
        ..verticalClick = 0.1
        ..horizontalClick = 0.1;

      final id = store.box<Sight>().put(sight);
      final found = store.box<Sight>().get(id)!;

      expect(found.name, 'Vortex Razor');
      expect(found.focalPlaneValue, 'ffp');
      expect(found.sightHeightInch, closeTo(1.5, 1e-6));
    });
  });

  group('Ammo', () {
    test('stores drag type as string', () {
      final ammo = Ammo()
        ..name = '.308 Win 175gr'
        ..weightGrain = 175.0
        ..caliberInch = 0.308
        ..dragTypeValue = 'g7'
        ..bcG7 = 0.475
        ..muzzleVelocityMps = 800.0
        ..muzzleVelocityTemperatureC = 15.0;

      final id = store.box<Ammo>().put(ammo);
      final found = store.box<Ammo>().get(id)!;

      expect(found.name, '.308 Win 175gr');
      expect(found.dragTypeValue, 'g7');
      expect(found.bcG7, closeTo(0.475, 1e-6));
      expect(found.muzzleVelocityMps, closeTo(800.0, 1e-6));
    });
  });

  group('Profile', () {
    test('links weapon, sight, ammo via ToOne relations', () {
      final owner = Owner()..token = 'local';
      store.box<Owner>().put(owner);

      final weapon = Weapon()
        ..name = 'Rifle'
        ..owner.target = owner;
      final sight = Sight()
        ..name = 'Scope'
        ..owner.target = owner;
      final ammo = Ammo()
        ..name = 'Ammo'
        ..owner.target = owner;

      store.box<Weapon>().put(weapon);
      store.box<Sight>().put(sight);
      store.box<Ammo>().put(ammo);

      final profile = Profile()
        ..name = 'Test Profile'
        ..weapon.target = weapon
        ..sight.target = sight
        ..ammo.target = ammo
        ..owner.target = owner;

      final id = store.box<Profile>().put(profile);
      final found = store.box<Profile>().get(id)!;

      expect(found.name, 'Test Profile');
      expect(found.weapon.target?.name, 'Rifle');
      expect(found.sight.target?.name, 'Scope');
      expect(found.ammo.target?.name, 'Ammo');
    });
  });

  group('Owner backlinks', () {
    test('weapons/sights/ammo linked to owner are accessible', () {
      final box = store.box<Owner>();
      final owner = Owner()..token = 'local';
      box.put(owner);

      store.box<Weapon>().put(
        Weapon()
          ..name = 'W1'
          ..owner.target = owner,
      );
      store.box<Weapon>().put(
        Weapon()
          ..name = 'W2'
          ..owner.target = owner,
      );
      store.box<Sight>().put(
        Sight()
          ..name = 'S1'
          ..owner.target = owner,
      );

      final found = box.get(owner.id)!;
      expect(found.weapons.length, 2);
      expect(found.sights.length, 1);
    });
  });

  group('GeneralSettings', () {
    test('stores settings and owner tracks active profile', () {
      final profile = Profile()..name = 'Active';
      store.box<Profile>().put(profile);

      final owner = Owner()
        ..token = 'local'
        ..activeProfile.target = profile;
      store.box<Owner>().put(owner);

      final settings = GeneralSettings()
        ..languageCode = 'uk'
        ..themeMode = 'dark'
        ..owner.target = owner;
      store.box<GeneralSettings>().put(settings);

      final foundOwner = store.box<Owner>().get(owner.id)!;
      expect(foundOwner.activeProfile.target?.name, 'Active');

      final foundSettings = store
          .box<GeneralSettings>()
          .query(GeneralSettings_.owner.equals(owner.id))
          .build()
          .findFirst()!;
      expect(foundSettings.languageCode, 'uk');
      expect(foundSettings.themeMode, 'dark');
    });
  });

  group('Conditions', () {
    test('stores conditions linked to owner via ToOne', () {
      final owner = Owner()..token = 'local';
      store.box<Owner>().put(owner);

      final cond = ShootingConditions()
        ..distanceMeter = 300.0
        ..temperatureC = 20.0
        ..pressurehPa = 1013.25
        ..humidityFrac = 0.5
        ..windSpeedMps = 3.0
        ..windDirectionDeg = 90.0
        ..owner.target = owner;

      store.box<ShootingConditions>().put(cond);

      final found = store
          .box<ShootingConditions>()
          .query(ShootingConditions_.owner.equals(owner.id))
          .build()
          .findFirst()!;

      expect(found.distanceMeter, closeTo(300.0, 1e-6));
      expect(found.temperatureC, closeTo(20.0, 1e-6));
      expect(found.windSpeedMps, closeTo(3.0, 1e-6));
      expect(found.windDirectionDeg, closeTo(90.0, 1e-6));
    });
  });

  group('ConvertorsState', () {
    test('stores convertor fields', () {
      final state = ConvertorsState()
        ..lengthValueInch = 50.0
        ..lengthLastUnit = 'centimeter'
        ..weightValueGrain = 200.0;

      final id = store.box<ConvertorsState>().put(state);
      final found = store.box<ConvertorsState>().get(id)!;

      expect(found.lengthValueInch, closeTo(50.0, 1e-6));
      expect(found.lengthLastUnit, 'centimeter');
      expect(found.weightValueGrain, closeTo(200.0, 1e-6));
    });
  });
}

// test/debug_test.dart
import 'package:ebalistyka_db/objectbox.g.dart';
import 'package:ebalistyka_db/src/entities.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  test('переглянути базу', () async {
    final store = await openStore();

    // Додаємо тестові дані через каскадну нотацію
    final sight = Sight()
      ..name = "Vortex Razor HD"
      ..focalPlane = FocalPlane.ffp
      ..minMagnification = 1.0
      ..maxMagnification = 10.0
      ..vendor = "Vortex"
      ..verticalClick = 0.1
      ..horizontalClick = 0.1;

    final sightBox = store.box<Sight>();
    sightBox.put(sight);

    // Додаємо набій
    final ammo = Ammo()
      ..name = ".308 Win"
      ..caliber = 7.62
      ..weight = 168.0
      ..bcG1 = 0.462;

    final cartridgeBox = store.box<Ammo>();
    cartridgeBox.put(ammo);

    final weapon = Weapon()
      ..name = "Мій ствол"
      ..caliber = 7.62
      ..twist = 254.0;

    // Додаємо профіль
    final profile = Profile()..name = "Мій профіль";

    profile.weapon.target = weapon;
    profile.sight.target = sight;
    profile.ammo.target = ammo;

    final profileBox = store.box<Profile>();
    profileBox.put(profile);

    // Додаємо власника
    final owner = Owner()..token = "user_123";

    final ownerBox = store.box<Owner>();
    ownerBox.put(owner);

    // Прив'язуємо все до власника
    sight.owner.target = owner;
    ammo.owner.target = owner;
    profile.owner.target = owner;

    sightBox.put(sight);
    cartridgeBox.put(ammo);
    profileBox.put(profile);

    print('\n=== БАЗА ДАНИХ ===');
    print('Шлях: ${Directory.current.path}/objectbox');
    print('Прицілів: ${sightBox.count()}');
    print('Набоїв: ${cartridgeBox.count()}');
    print('Профілів: ${profileBox.count()}');
    print('Власників: ${ownerBox.count()}');

    store.close();

    print('\nЩоб переглянути базу, запустіть:');
    print(
      'docker run --rm -it --volume "${Directory.current.path}:/db" --publish 8081:8081 objectboxio/admin:latest',
    );
    print('Потім відкрийте http://localhost:8081\n');
  });
}

// test/debug_test.dart
import 'package:ebalistyka_db/objectbox.g.dart';
import 'package:ebalistyka_db/src/entities.dart';
import 'package:objectbox/objectbox.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  test('переглянути базу', () async {
    // ObjectBox створить базу в тимчасовій директорії
    final store = await openStore();

    // Додамо тестові дані
    final sightBox = store.box<Sight>();
    sightBox.put(Sight(name: "Тестовий приціл", focalPlane: FocalPlane.ffp));

    // Отримуємо шлях до бази через властивість store
    // У ObjectBox для Dart, шлях зберігається внутрішньо, але ми можемо його дізнатись
    // Якщо ви не передавали directory в openStore(), то база створюється в поточній директорії
    final currentPath = Directory.current.path;
    final dbPath = '$currentPath/objectbox';

    print('База даних знаходиться в: $dbPath');
    print('Файли бази: ${Directory(dbPath).existsSync()}');

    store.close();

    // Тепер ви можете запустити Docker Admin:
    print('\nЩоб переглянути базу, запустіть:');
    print(
      'docker run --rm -it --volume "$currentPath:/db" --publish 8081:8081 objectboxio/admin:latest',
    );
    print('Потім відкрийте http://localhost:8081\n');
  });
}

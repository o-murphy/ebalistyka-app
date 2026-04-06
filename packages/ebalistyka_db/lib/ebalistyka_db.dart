import 'package:objectbox/objectbox.dart';
import 'objectbox.g.dart';
import 'dart:io';

late Store store;

Future<void> initObjectBox() async {
  store = await openStore();

  // Виведіть шлях до бази даних
  final dbPath = Directory.current.path;
  print('База даних знаходиться в: $dbPath');
  print('Файли бази: ${Directory('$dbPath/objectbox').existsSync()}');
}

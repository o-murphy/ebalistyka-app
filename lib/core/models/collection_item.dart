import 'package:ebalistyka/core/models/cartridge.dart';
import 'package:ebalistyka/core/models/sight.dart';

abstract interface class CollectionItem<T> {
  String get id;
  T get ref;
}

class CartridgeCollectionItem extends CollectionItem<Cartridge> {
  CartridgeCollectionItem({required this.ref});

  @override
  String get id => ref.id;

  @override
  final Cartridge ref;
}

class SightCollectionItem extends CollectionItem<Sight> {
  SightCollectionItem({required this.ref});

  @override
  String get id => ref.id;

  @override
  final Sight ref;
}

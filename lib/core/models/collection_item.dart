import 'package:ebalistyka_db/ebalistyka_db.dart';

abstract interface class CollectionItem<T> {
  String get id;
  T get ref;
}

class CartridgeCollectionItem extends CollectionItem<Ammo> {
  CartridgeCollectionItem({required this.ref});

  @override
  String get id => ref.id.toString();

  @override
  final Ammo ref;
}

class SightCollectionItem extends CollectionItem<Sight> {
  SightCollectionItem({required this.ref});

  @override
  String get id => ref.id.toString();

  @override
  final Sight ref;
}

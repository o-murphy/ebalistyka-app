import 'package:ebalistyka/core/models/ammo_data.dart';
import 'package:ebalistyka/core/models/sight_data.dart';

abstract interface class CollectionItem<T> {
  String get id;
  T get ref;
}

class CartridgeCollectionItem extends CollectionItem<AmmoData> {
  CartridgeCollectionItem({required this.ref});

  @override
  String get id => ref.id;

  @override
  final AmmoData ref;
}

class SightCollectionItem extends CollectionItem<SightData> {
  SightCollectionItem({required this.ref});

  @override
  String get id => ref.id;

  @override
  final SightData ref;
}

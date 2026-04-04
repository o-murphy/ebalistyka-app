import 'package:eballistica/core/models/cartridge.dart';

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

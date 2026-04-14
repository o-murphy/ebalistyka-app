mixin Cloneable<T> {
  T copyWith({int? id});

  T clone() => copyWith(id: 0);
}

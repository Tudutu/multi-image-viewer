extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> merge(Iterable<T> other) sync* {
    Iterator<T> iter1 = iterator;
    Iterator<T> iter2 = other.iterator;

    bool has1 = iter1.moveNext();
    bool has2 = iter2.moveNext();
    while (has1 && has2) {
      yield iter1.current;
      yield iter2.current;
      has1 = iter1.moveNext();
      has2 = iter2.moveNext();
    }
    while (has1) {
      yield iter1.current;
      has1 = iter1.moveNext();
    }
    while (has2) {
      yield iter2.current;
      has2 = iter2.moveNext();
    }
  }
}

import 'dart:collection';

/// Immutable snapshots share completed blocks instead of copying every GPS
/// point on every update. Indexing remains constant time for map and metrics.
class AppendOnlyList<T> extends ListBase<T> {
  AppendOnlyList.empty() : _blocks = [], _tail = [], _length = 0;

  AppendOnlyList._(this._blocks, this._tail, this._length);

  static const _blockSize = 64;
  final List<List<T>> _blocks;
  final List<T> _tail;
  final int _length;

  AppendOnlyList<T> appended(T value) {
    if (_tail.length == _blockSize) {
      return AppendOnlyList._([..._blocks, _tail], [value], _length + 1);
    }
    return AppendOnlyList._(_blocks, [..._tail, value], _length + 1);
  }

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('Immutable GPS snapshot');

  @override
  T operator [](int index) {
    RangeError.checkValidIndex(index, this, null, _length);
    final block = index ~/ _blockSize;
    return block < _blocks.length
        ? _blocks[block][index % _blockSize]
        : _tail[index % _blockSize];
  }

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Immutable GPS snapshot');
}

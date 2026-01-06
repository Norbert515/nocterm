class PersistentHashMap<K extends Object, V> {
  const PersistentHashMap.empty() : this._(null);
  const PersistentHashMap._(this._root);
  factory PersistentHashMap.from(Map<K, V> map) {
    var persistentMap = PersistentHashMap<K, V>.empty();
    for (final entry in map.entries) {
      persistentMap = persistentMap.put(entry.key, entry.value);
    }
    return persistentMap;
  }

  final _TrieNode? _root;

  PersistentHashMap<K, V> put(K key, V value) {
    final _TrieNode newRoot = (_root ?? _CompressedNode.empty).put(
      0,
      key,
      key.hashCode,
      value,
    );
    if (newRoot == _root) {
      return this;
    }
    return PersistentHashMap<K, V>._(newRoot);
  }

  @pragma('dart2js:as:trust')
  V? operator [](K key) {
    return _root?.get(0, key, key.hashCode) as V?;
  }
}

abstract class _TrieNode {
  static const int hashBitsPerLevel = 5;
  static const int hashBitsPerLevelMask = (1 << hashBitsPerLevel) - 1;

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  static int trieIndex(int hash, int bitIndex) {
    return (hash >>> bitIndex) & hashBitsPerLevelMask;
  }

  _TrieNode put(int bitIndex, Object key, int keyHash, Object? value);

  Object? get(int bitIndex, Object key, int keyHash);
}

class _FullNode extends _TrieNode {
  _FullNode(this.descendants);

  static const int numElements = 1 << _TrieNode.hashBitsPerLevel;

  final List<Object?> descendants;

  @override
  _TrieNode put(int bitIndex, Object key, int keyHash, Object? value) {
    final int index = _TrieNode.trieIndex(keyHash, bitIndex);
    final _TrieNode node =
        _unsafeCast<_TrieNode?>(descendants[index]) ?? _CompressedNode.empty;
    final _TrieNode newNode = node.put(
      bitIndex + _TrieNode.hashBitsPerLevel,
      key,
      keyHash,
      value,
    );
    return identical(newNode, node)
        ? this
        : _FullNode(_copy(descendants)..[index] = newNode);
  }

  @override
  Object? get(int bitIndex, Object key, int keyHash) {
    final int index = _TrieNode.trieIndex(keyHash, bitIndex);

    final _TrieNode? node = _unsafeCast<_TrieNode?>(descendants[index]);
    return node?.get(bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash);
  }
}

class _CompressedNode extends _TrieNode {
  _CompressedNode(this.occupiedIndices, this.keyValuePairs);
  _CompressedNode._empty() : this(0, _emptyArray);

  factory _CompressedNode.single(int bitIndex, int keyHash, _TrieNode node) {
    final int bit = 1 << _TrieNode.trieIndex(keyHash, bitIndex);
    final List<Object?> keyValuePairs = _makeArray(2)..[1] = node;
    return _CompressedNode(bit, keyValuePairs);
  }

  static final _CompressedNode empty = _CompressedNode._empty();

  static final List<Object?> _emptyArray = _makeArray(0);

  final int occupiedIndices;
  final List<Object?> keyValuePairs;

  @override
  _TrieNode put(int bitIndex, Object key, int keyHash, Object? value) {
    final int bit = 1 << _TrieNode.trieIndex(keyHash, bitIndex);
    final int index = _compressedIndex(bit);

    if ((occupiedIndices & bit) != 0) {
      final Object? keyOrNull = keyValuePairs[2 * index];
      final Object? valueOrNode = keyValuePairs[2 * index + 1];

      if (identical(keyOrNull, null)) {
        final _TrieNode newNode = _unsafeCast<_TrieNode>(
          valueOrNode,
        ).put(bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash, value);
        if (newNode == valueOrNode) {
          return this;
        }
        return _CompressedNode(
          occupiedIndices,
          _copy(keyValuePairs)..[2 * index + 1] = newNode,
        );
      }

      if (key == keyOrNull) {
        return identical(value, valueOrNode)
            ? this
            : _CompressedNode(
                occupiedIndices,
                _copy(keyValuePairs)..[2 * index + 1] = value,
              );
      }

      final _TrieNode newNode = _resolveCollision(
        bitIndex + _TrieNode.hashBitsPerLevel,
        keyOrNull,
        valueOrNode,
        key,
        keyHash,
        value,
      );
      return _CompressedNode(
        occupiedIndices,
        _copy(keyValuePairs)
          ..[2 * index] = null
          ..[2 * index + 1] = newNode,
      );
    } else {
      final int occupiedCount = _bitCount(occupiedIndices);
      if (occupiedCount >= 16) {
        return _inflate(bitIndex)
          ..descendants[_TrieNode.trieIndex(
            keyHash,
            bitIndex,
          )] = _CompressedNode.empty.put(
            bitIndex + _TrieNode.hashBitsPerLevel,
            key,
            keyHash,
            value,
          );
      } else {
        final int prefixLength = 2 * index;
        final int totalLength = 2 * occupiedCount;
        final List<Object?> newKeyValuePairs = _makeArray(totalLength + 2);
        for (var srcIndex = 0; srcIndex < prefixLength; srcIndex++) {
          newKeyValuePairs[srcIndex] = keyValuePairs[srcIndex];
        }
        newKeyValuePairs[prefixLength] = key;
        newKeyValuePairs[prefixLength + 1] = value;
        for (
          int srcIndex = prefixLength, dstIndex = prefixLength + 2;
          srcIndex < totalLength;
          srcIndex++, dstIndex++
        ) {
          newKeyValuePairs[dstIndex] = keyValuePairs[srcIndex];
        }
        return _CompressedNode(occupiedIndices | bit, newKeyValuePairs);
      }
    }
  }

  @override
  Object? get(int bitIndex, Object key, int keyHash) {
    final int bit = 1 << _TrieNode.trieIndex(keyHash, bitIndex);
    if ((occupiedIndices & bit) == 0) {
      return null;
    }
    final int index = _compressedIndex(bit);
    final Object? keyOrNull = keyValuePairs[2 * index];
    final Object? valueOrNode = keyValuePairs[2 * index + 1];
    if (keyOrNull == null) {
      final _TrieNode node = _unsafeCast<_TrieNode>(valueOrNode);
      return node.get(bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash);
    }
    if (key == keyOrNull) {
      return valueOrNode;
    }
    return null;
  }

  _FullNode _inflate(int bitIndex) {
    final List<Object?> nodes = _makeArray(_FullNode.numElements);
    var srcIndex = 0;
    for (var dstIndex = 0; dstIndex < _FullNode.numElements; dstIndex++) {
      if (((occupiedIndices >>> dstIndex) & 1) != 0) {
        final Object? keyOrNull = keyValuePairs[srcIndex];
        if (keyOrNull == null) {
          nodes[dstIndex] = keyValuePairs[srcIndex + 1];
        } else {
          nodes[dstIndex] = _CompressedNode.empty.put(
            bitIndex + _TrieNode.hashBitsPerLevel,
            keyOrNull,
            keyValuePairs[srcIndex].hashCode,
            keyValuePairs[srcIndex + 1],
          );
        }
        srcIndex += 2;
      }
    }
    return _FullNode(nodes);
  }

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  int _compressedIndex(int bit) {
    return _bitCount(occupiedIndices & (bit - 1));
  }

  static _TrieNode _resolveCollision(
    int bitIndex,
    Object existingKey,
    Object? existingValue,
    Object key,
    int keyHash,
    Object? value,
  ) {
    final existingKeyHash = existingKey.hashCode;
    return (existingKeyHash == keyHash)
        ? _HashCollisionNode.fromCollision(
            keyHash,
            existingKey,
            existingValue,
            key,
            value,
          )
        : _CompressedNode.empty
              .put(bitIndex, existingKey, existingKeyHash, existingValue)
              .put(bitIndex, key, keyHash, value);
  }
}

///
class _HashCollisionNode extends _TrieNode {
  _HashCollisionNode(this.hash, this.keyValuePairs);

  factory _HashCollisionNode.fromCollision(
    int keyHash,
    Object keyA,
    Object? valueA,
    Object keyB,
    Object? valueB,
  ) {
    final List<Object?> list = _makeArray(4);
    list[0] = keyA;
    list[1] = valueA;
    list[2] = keyB;
    list[3] = valueB;
    return _HashCollisionNode(keyHash, list);
  }

  final int hash;
  final List<Object?> keyValuePairs;

  @override
  _TrieNode put(int bitIndex, Object key, int keyHash, Object? val) {
    if (keyHash == hash) {
      final int index = _indexOf(key);
      if (index != -1) {
        return identical(keyValuePairs[index + 1], val)
            ? this
            : _HashCollisionNode(
                keyHash,
                _copy(keyValuePairs)..[index + 1] = val,
              );
      }
      final int length = keyValuePairs.length;
      final List<Object?> newArray = _makeArray(length + 2);
      for (var i = 0; i < length; i++) {
        newArray[i] = keyValuePairs[i];
      }
      newArray[length] = key;
      newArray[length + 1] = val;
      return _HashCollisionNode(keyHash, newArray);
    }

    return _CompressedNode.single(
      bitIndex,
      hash,
      this,
    ).put(bitIndex, key, keyHash, val);
  }

  @override
  Object? get(int bitIndex, Object key, int keyHash) {
    final int index = _indexOf(key);
    return index < 0 ? null : keyValuePairs[index + 1];
  }

  int _indexOf(Object key) {
    final int length = keyValuePairs.length;
    for (var i = 0; i < length; i += 2) {
      if (key == keyValuePairs[i]) {
        return i;
      }
    }
    return -1;
  }
}

///
@pragma('dart2js:tryInline')
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
int _bitCount(int n) {
  assert((n & 0xFFFFFFFF) == n);
  n = n - ((n >> 1) & 0x55555555);
  n = (n & 0x33333333) + ((n >>> 2) & 0x33333333);
  n = (n + (n >> 4)) & 0x0F0F0F0F;
  n = n + (n >> 8);
  n = n + (n >> 16);
  return n & 0x0000003F;
}

///
@pragma('dart2js:tryInline')
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
List<Object?> _copy(List<Object?> array) {
  final List<Object?> clone = _makeArray(array.length);
  for (var j = 0; j < array.length; j++) {
    clone[j] = array[j];
  }
  return clone;
}

///
@pragma('dart2js:tryInline')
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
List<Object?> _makeArray(int length) {
  return List<Object?>.filled(length, null);
}

@pragma('dart2js:as:trust')
@pragma('dart2js:tryInline')
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
T _unsafeCast<T>(Object? o) {
  return o as T;
}

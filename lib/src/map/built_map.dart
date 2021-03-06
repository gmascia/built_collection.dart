// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of built_collection.map;

/// The Built Collection [Map].
///
/// It implements the non-mutating part of the [Map] interface. It preserves
/// key order. Modifications are made via [MapBuilder].
///
/// See the
/// [Built Collection library documentation](#built_collection/built_collection)
/// for the general properties of Built Collections.
class BuiltMap<K, V> {
  final Map<K, V> _map;

  // Cached.
  int _hashCode = null;
  Iterable<K> _keys = null;
  Iterable<V> _values = null;

  /// Instantiates with elements from a [Map] or [BuiltMap].
  ///
  /// Must be called with a generic type parameter.
  ///
  /// Wrong: `new BuiltMap({1: '1', 2: '2', 3: '3'})`.
  ///
  /// Right: `new BuiltMap<int, String>({1: '1', 2: '2', 3: '3'})`,
  ///
  /// Rejects nulls. Rejects keys and values of the wrong type.
  factory BuiltMap([map = const {}]) {
    if (map is BuiltMap<K, V>) {
      return map;
    } else if (map is Map || map is BuiltMap) {
      return new BuiltMap<K, V>._copyAndCheck(map.keys, (k) => map[k]);
    } else {
      throw new ArgumentError(
          'expected Map or BuiltMap, got ${map.runtimeType}');
    }
  }

  /// Creates a [MapBuilder], applies updates to it, and builds.
  factory BuiltMap.build(updates(MapBuilder<K, V> builder)) =>
      (new MapBuilder<K, V>()..update(updates)).build();

  /// Converts to a [MapBuilder] for modification.
  ///
  /// The `BuiltMap` remains immutable and can continue to be used.
  MapBuilder<K, V> toBuilder() => new MapBuilder<K, V>(this);

  /// Converts to a [MapBuilder], applies updates to it, and builds.
  BuiltMap<K, V> rebuild(updates(MapBuilder<K, V> builder)) =>
      (toBuilder()..update(updates)).build();

  /// Converts to a [Map].
  ///
  /// Note that the implementation is efficient: it returns a copy-on-write
  /// wrapper around the data from this `BuiltMap`. So, if no mutations are
  /// made to the result, no copy is made.
  ///
  /// This allows efficient use of APIs that ask for a mutable collection
  /// but don't actually mutate it.
  Map<K, V> toMap() => new CopyOnWriteMap<K, V>(_map);

  /// Deep hashCode.
  ///
  /// A `BuiltMap` is only equal to another `BuiltMap` with equal key/value
  /// pairs in any order. Then, the `hashCode` is guaranteed to be the same.
  @override
  int get hashCode {
    if (_hashCode == null) {
      _hashCode = hashObjects(_map.keys
          .map((key) => hash2(key.hashCode, _map[key].hashCode))
          .toList(growable: false)..sort());
    }
    return _hashCode;
  }

  /// Deep equality.
  ///
  /// A `BuiltMap` is only equal to another `BuiltMap` with equal key/value
  /// pairs in any order.
  @override
  bool operator ==(other) {
    if (other is! BuiltMap) return false;
    if (other.length != length) return false;
    if (other.hashCode != hashCode) return false;
    for (final key in keys) {
      if (other[key] != this[key]) return false;
    }
    return true;
  }

  String toString() => _map.toString();

  // Map.

  /// As [Map].
  V operator [](K key) => _map[key];

  /// As [Map.containsKey].
  bool containsKey(Object key) => _map.containsKey(key);

  /// As [Map.containsValue].
  bool containsValue(Object value) => _map.containsValue(value);

  /// As [Map.forEach].
  void forEach(void f(K key, V value)) {
    _map.forEach(f);
  }

  /// As [Map.isEmpty].
  bool get isEmpty => _map.isEmpty;

  /// As [Map.isNotEmpty].
  bool get isNotEmpty => _map.isNotEmpty;

  /// As [Map.keys], but result is stable; it always returns the same instance.
  Iterable<K> get keys {
    if (_keys == null) {
      _keys = _map.keys;
    }
    return _keys;
  }

  /// As [Map.length].
  int get length => _map.length;

  /// As [Map.values], but result is stable; it always returns the same
  /// instance.
  Iterable<V> get values {
    if (_values == null) {
      _values = _map.values;
    }
    return _values;
  }

  // Internal.

  BuiltMap._copyAndCheck(Iterable keys, Function lookup)
      : _map = new Map<K, V>() {
    _checkGenericTypeParameter();

    for (final key in keys) {
      if (key is! K) {
        throw new ArgumentError('map contained invalid key: ${key}');
      }

      final value = lookup(key);
      if (value is! V) {
        throw new ArgumentError('map contained invalid value: ${value}');
      }

      _map[key] = value;
    }
  }

  BuiltMap._withSafeMap(this._map) {
    _checkGenericTypeParameter();
  }

  void _checkGenericTypeParameter() {
    if (null is K && K != Object) {
      throw new UnsupportedError(
          'explicit key type required, for example "new BuiltMap<int, int>"');
    }
    if (null is V && V != Object) {
      throw new UnsupportedError('explicit value type required,'
          ' for example "new BuiltMap<int, int>"');
    }
  }
}

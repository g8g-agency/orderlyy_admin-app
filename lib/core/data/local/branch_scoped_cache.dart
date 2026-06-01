import 'dart:collection';

class BranchScopedCache<K, V> {
  final int maxCapacity;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  BranchScopedCache({this.maxCapacity = 1000});

  V? get(K key) {
    if (_cache.containsKey(key)) {
      final value = _cache.remove(key) as V;
      _cache[key] = value; // Move to end (most recently used)
      return value;
    }
    return null;
  }

  void set(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    _cache[key] = value;
    if (_cache.length > maxCapacity) {
      _cache.remove(_cache.keys.first); // Remove oldest
    }
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  List<V> get values => _cache.values.toList();
  Map<K, V> toMap() => Map.unmodifiable(_cache);
  
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;
  
  V? operator [](K key) => get(key);
  void operator []=(K key, V value) => set(key, value);
}

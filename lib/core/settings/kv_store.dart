import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key-value storage abstraction (swap backend without touching UI).
abstract interface class KvStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
}

class PrefsKvStore implements KvStore {
  PrefsKvStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}

/// In-memory store for tests.
class MemoryKvStore implements KvStore {
  final Map<String, String> _data = {};

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }
}

/// Must be overridden in `ProviderScope` (see main.dart and tests).
final kvStoreProvider = Provider<KvStore>(
  (ref) => throw UnimplementedError('kvStoreProvider must be overridden'),
);

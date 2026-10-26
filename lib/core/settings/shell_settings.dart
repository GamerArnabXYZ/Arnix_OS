import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_registry/app_registry.dart';
import 'kv_store.dart';

enum TaskbarPosition { bottom, left, right }

@immutable
class ShellSettings {
  const ShellSettings({
    this.pinned = const <String>[],
    this.desktop = const <String>[],
    this.recent = const <String>[],
    this.taskbarPosition = TaskbarPosition.bottom,
    this.wallpaper = 0,
  });

  factory ShellSettings.defaults(Iterable<String> appIds) {
    final ids = appIds.toList(growable: false);
    return ShellSettings(pinned: ids, desktop: ids);
  }

  /// Parses stored JSON. Unknown app ids are dropped, duplicates removed.
  factory ShellSettings.fromJson(
    Map<String, Object?> json, {
    required bool Function(String id) isKnownApp,
  }) {
    List<String> ids(Object? v) {
      if (v is! List<Object?>) return const <String>[];
      final out = <String>[];
      for (final e in v) {
        if (e is String && isKnownApp(e) && !out.contains(e)) out.add(e);
      }
      return out;
    }

    final wp = json['wallpaper'];
    return ShellSettings(
      pinned: ids(json['pinned']),
      desktop: ids(json['desktop']),
      recent: ids(json['recent']),
      taskbarPosition: TaskbarPosition.values.asNameMap()[json['taskbar']] ??
          TaskbarPosition.bottom,
      wallpaper: wp is int && wp >= 0 ? wp : 0,
    );
  }

  final List<String> pinned;
  final List<String> desktop;
  final List<String> recent;
  final TaskbarPosition taskbarPosition;
  final int wallpaper;

  ShellSettings copyWith({
    List<String>? pinned,
    List<String>? desktop,
    List<String>? recent,
    TaskbarPosition? taskbarPosition,
    int? wallpaper,
  }) {
    return ShellSettings(
      pinned: pinned ?? this.pinned,
      desktop: desktop ?? this.desktop,
      recent: recent ?? this.recent,
      taskbarPosition: taskbarPosition ?? this.taskbarPosition,
      wallpaper: wallpaper ?? this.wallpaper,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'pinned': pinned,
        'desktop': desktop,
        'recent': recent,
        'taskbar': taskbarPosition.name,
        'wallpaper': wallpaper,
      };
}

final shellSettingsProvider =
    NotifierProvider<ShellSettingsNotifier, ShellSettings>(
  ShellSettingsNotifier.new,
);

class ShellSettingsNotifier extends Notifier<ShellSettings> {
  static const String storageKey = 'shell_settings_v1';
  static const int maxRecent = 6;

  @override
  ShellSettings build() {
    final registry = ref.read(appRegistryProvider);
    final raw = ref.read(kvStoreProvider).getString(storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) {
          return ShellSettings.fromJson(
            decoded,
            isKnownApp: (id) => registry.byId(id) != null,
          );
        }
      } catch (_) {
        // Corrupt data: fall through to defaults.
      }
    }
    return ShellSettings.defaults(registry.all.map((a) => a.id));
  }

  void _set(ShellSettings next) {
    state = next;
    unawaited(
      ref
          .read(kvStoreProvider)
          .setString(storageKey, jsonEncode(next.toJson())),
    );
  }

  static List<String> _toggle(List<String> list, String id) =>
      list.contains(id) ? list.where((e) => e != id).toList() : [...list, id];

  void togglePinned(String appId) =>
      _set(state.copyWith(pinned: _toggle(state.pinned, appId)));

  void toggleOnDesktop(String appId) =>
      _set(state.copyWith(desktop: _toggle(state.desktop, appId)));

  void addRecent(String appId) {
    final list =
        [appId, ...state.recent.where((e) => e != appId)].take(maxRecent);
    _set(state.copyWith(recent: list.toList()));
  }

  void setTaskbarPosition(TaskbarPosition position) =>
      _set(state.copyWith(taskbarPosition: position));

  void nextWallpaper(int count) {
    if (count <= 0) return;
    _set(state.copyWith(wallpaper: (state.wallpaper + 1) % count));
  }
}

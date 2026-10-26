import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_registry/app_registry.dart';
import '../../core/settings/shell_settings.dart';
import '../../core/window_manager/models/window_state.dart';
import '../../core/window_manager/window_controller.dart';

/// One taskbar slot: an app plus all of its open windows (grouped).
@immutable
class TaskbarItem {
  const TaskbarItem({
    required this.app,
    required this.pinned,
    required this.windows,
    required this.hasFocus,
  });

  final AppManifest app;
  final bool pinned;

  /// Sorted by window id (opening order).
  final List<WindowState> windows;
  final bool hasFocus;

  bool get running => windows.isNotEmpty;
}

/// Pinned apps first (pin order), then running unpinned apps (by first window).
List<TaskbarItem> buildTaskbarItems({
  required List<String> pinned,
  required List<WindowState> windows,
  required AppRegistry registry,
  required int? topVisibleId,
}) {
  final byApp = <String, List<WindowState>>{};
  for (final w in windows) {
    byApp.putIfAbsent(w.appId, () => <WindowState>[]).add(w);
  }
  for (final list in byApp.values) {
    list.sort((a, b) => a.id.compareTo(b.id));
  }

  TaskbarItem make(AppManifest app, {required bool isPinned}) {
    final list = byApp[app.id] ?? const <WindowState>[];
    return TaskbarItem(
      app: app,
      pinned: isPinned,
      windows: list,
      hasFocus: list.any((w) => w.id == topVisibleId),
    );
  }

  final items = <TaskbarItem>[];
  final seen = <String>{};

  for (final id in pinned) {
    final app = registry.byId(id);
    if (app == null || !seen.add(id)) continue;
    items.add(make(app, isPinned: true));
  }

  final runningOrder = byApp.keys.toList()
    ..sort((a, b) => byApp[a]!.first.id.compareTo(byApp[b]!.first.id));
  for (final id in runningOrder) {
    final app = registry.byId(id);
    if (app == null || !seen.add(id)) continue;
    items.add(make(app, isPinned: false));
  }
  return items;
}

final taskbarItemsProvider = Provider<List<TaskbarItem>>((ref) {
  final st = ref.watch(windowsProvider);
  final pinned = ref.watch(shellSettingsProvider.select((s) => s.pinned));
  return buildTaskbarItems(
    pinned: pinned,
    windows: st.windows,
    registry: ref.watch(appRegistryProvider),
    topVisibleId: st.topVisibleId,
  );
});

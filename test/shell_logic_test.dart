import 'dart:convert';
import 'dart:ui';

import 'package:arnix_os/core/app_registry/app_registry.dart';
import 'package:arnix_os/core/settings/kv_store.dart';
import 'package:arnix_os/core/settings/shell_settings.dart';
import 'package:arnix_os/core/window_manager/models/window_state.dart';
import 'package:arnix_os/core/window_manager/window_controller.dart';
import 'package:arnix_os/shell/launcher/app_launcher.dart';
import 'package:arnix_os/shell/taskbar/taskbar_items.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppManifest app(String id) => AppManifest(
      id: id,
      title: id.toUpperCase(),
      icon: IconData(0xe000),
      builder: (context, windowId) => const SizedBox(),
    );

final AppRegistry registry = AppRegistry([app('a'), app('b'), app('c')]);

ProviderContainer makeContainer([KvStore? store]) {
  final c = ProviderContainer(
    overrides: [
      appRegistryProvider.overrideWithValue(registry),
      kvStoreProvider.overrideWithValue(store ?? MemoryKvStore()),
    ],
  );
  addTearDown(c.dispose);
  c.read(windowsProvider.notifier).setDesktopSize(const Size(1000, 600));
  return c;
}

WindowState win(int id, String appId, {bool minimized = false}) => WindowState(
      id: id,
      appId: appId,
      title: appId,
      rect: Rect.zero,
      isMinimized: minimized,
    );

void main() {
  group('ShellSettings', () {
    test('defaults pin and show every app, bottom taskbar', () {
      final c = makeContainer();
      final s = c.read(shellSettingsProvider);
      expect(s.pinned, ['a', 'b', 'c']);
      expect(s.desktop, ['a', 'b', 'c']);
      expect(s.recent, isEmpty);
      expect(s.taskbarPosition, TaskbarPosition.bottom);
    });

    test('togglePinned / toggleOnDesktop', () {
      final c = makeContainer();
      final n = c.read(shellSettingsProvider.notifier);
      n.togglePinned('b');
      expect(c.read(shellSettingsProvider).pinned, ['a', 'c']);
      n.togglePinned('b');
      expect(c.read(shellSettingsProvider).pinned, ['a', 'c', 'b']);
      n.toggleOnDesktop('a');
      expect(c.read(shellSettingsProvider).desktop, ['b', 'c']);
    });

    test('recent is most-recent-first, deduped and capped', () {
      final c = makeContainer();
      final n = c.read(shellSettingsProvider.notifier);
      n.addRecent('a');
      n.addRecent('b');
      n.addRecent('a');
      expect(c.read(shellSettingsProvider).recent, ['a', 'b']);
      for (var i = 0; i < 10; i++) {
        n.addRecent('x$i');
      }
      final recent = c.read(shellSettingsProvider).recent;
      expect(recent.length, ShellSettingsNotifier.maxRecent);
      expect(recent.first, 'x9');
    });

    test('wallpaper index wraps', () {
      final c = makeContainer();
      final n = c.read(shellSettingsProvider.notifier);
      n.nextWallpaper(2);
      n.nextWallpaper(2);
      expect(c.read(shellSettingsProvider).wallpaper, 0);
    });

    test('settings persist across containers', () {
      final store = MemoryKvStore();
      final first = makeContainer(store);
      first.read(shellSettingsProvider.notifier)
        ..togglePinned('a')
        ..setTaskbarPosition(TaskbarPosition.right)
        ..addRecent('c');

      final second = makeContainer(store);
      final s = second.read(shellSettingsProvider);
      expect(s.pinned, ['b', 'c']);
      expect(s.taskbarPosition, TaskbarPosition.right);
      expect(s.recent, ['c']);
    });

    test('unknown app ids in stored data are dropped', () async {
      final store = MemoryKvStore();
      await store.setString(
        ShellSettingsNotifier.storageKey,
        jsonEncode({
          'pinned': ['a', 'ghost', 'a'],
          'desktop': ['ghost'],
          'recent': ['b'],
          'taskbar': 'left',
          'wallpaper': 2,
        }),
      );
      final s = makeContainer(store).read(shellSettingsProvider);
      expect(s.pinned, ['a']);
      expect(s.desktop, isEmpty);
      expect(s.recent, ['b']);
      expect(s.taskbarPosition, TaskbarPosition.left);
      expect(s.wallpaper, 2);
    });

    test('corrupt stored data falls back to defaults', () async {
      final store = MemoryKvStore();
      await store.setString(ShellSettingsNotifier.storageKey, '{not json');
      final s = makeContainer(store).read(shellSettingsProvider);
      expect(s.pinned, ['a', 'b', 'c']);
    });
  });

  group('buildTaskbarItems', () {
    test('pinned first, running unpinned appended, windows grouped', () {
      final items = buildTaskbarItems(
        pinned: ['b', 'a'],
        windows: [win(5, 'c'), win(2, 'a'), win(3, 'a')],
        registry: registry,
        topVisibleId: 3,
      );
      expect(items.map((i) => i.app.id), ['b', 'a', 'c']);
      expect(items[0].running, isFalse);
      expect(items[1].windows.map((w) => w.id), [2, 3]);
      expect(items[1].hasFocus, isTrue);
      expect(items[2].pinned, isFalse);
      expect(items[2].hasFocus, isFalse);
    });

    test('ignores unknown and duplicate pinned ids', () {
      final items = buildTaskbarItems(
        pinned: ['ghost', 'a', 'a'],
        windows: const [],
        registry: registry,
        topVisibleId: null,
      );
      expect(items.map((i) => i.app.id), ['a']);
    });
  });

  group('AppLauncher', () {
    test('launch opens a window, records recent and closes launcher', () {
      final c = makeContainer();
      c.read(launcherOpenProvider.notifier).toggle();
      expect(c.read(launcherOpenProvider), isTrue);

      final id = c.read(appLauncherProvider).launch('b');
      expect(id, isNotNull);
      expect(c.read(windowsProvider).windows.single.appId, 'b');
      expect(c.read(shellSettingsProvider).recent, ['b']);
      expect(c.read(launcherOpenProvider), isFalse);
    });

    test('launching an unknown app changes nothing', () {
      final c = makeContainer();
      c.read(launcherOpenProvider.notifier).toggle();
      expect(c.read(appLauncherProvider).launch('ghost'), isNull);
      expect(c.read(launcherOpenProvider), isTrue);
      expect(c.read(shellSettingsProvider).recent, isEmpty);
    });
  });
}

import 'dart:ui';

import 'package:arnix_os/core/app_registry/app_registry.dart';
import 'package:arnix_os/core/window_manager/models/resize_edges.dart';
import 'package:arnix_os/core/window_manager/models/window_state.dart';
import 'package:arnix_os/core/window_manager/window_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer makeContainer() {
  final registry = AppRegistry([
    AppManifest(
      id: 'a',
      title: 'A',
      icon: IconData(0xe000),
      builder: (context, id) => const SizedBox(),
    ),
    AppManifest(
      id: 'solo',
      title: 'Solo',
      icon: IconData(0xe000),
      singleInstance: true,
      builder: (context, id) => const SizedBox(),
    ),
  ]);
  final c = ProviderContainer(
    overrides: [appRegistryProvider.overrideWithValue(registry)],
  );
  addTearDown(c.dispose);
  c.read(windowsProvider.notifier).setDesktopSize(const Size(1000, 600));
  return c;
}

void main() {
  late ProviderContainer c;
  late WindowsNotifier n;

  WindowsState st() => c.read(windowsProvider);

  setUp(() {
    c = makeContainer();
    n = c.read(windowsProvider.notifier);
  });

  test('open stacks windows and focuses the newest', () {
    final a = n.open('a')!;
    final b = n.open('a')!;
    expect(st().windows.map((w) => w.id), [a, b]);
    expect(st().focusedId, b);
  });

  test('unknown app returns null', () {
    expect(n.open('nope'), isNull);
    expect(st().windows, isEmpty);
  });

  test('singleInstance focuses the existing window', () {
    final first = n.open('solo')!;
    n.open('a');
    final again = n.open('solo')!;
    expect(again, first);
    expect(st().windows.where((w) => w.appId == 'solo').length, 1);
    expect(st().focusedId, first);
  });

  test('focus moves window to top', () {
    final a = n.open('a')!;
    final b = n.open('a')!;
    n.focus(a);
    expect(st().windows.map((w) => w.id), [b, a]);
    expect(st().focusedId, a);
  });

  test('minimize falls back to previous window, focus restores', () {
    final a = n.open('a')!;
    final b = n.open('a')!;
    n.minimize(b);
    expect(st().byId(b)!.isMinimized, isTrue);
    expect(st().focusedId, a);
    n.focus(b);
    expect(st().byId(b)!.isMinimized, isFalse);
    expect(st().focusedId, b);
  });

  test('dock toggle: focused -> minimize -> restore', () {
    final a = n.open('a')!;
    n.toggleFromDock(a);
    expect(st().byId(a)!.isMinimized, isTrue);
    expect(st().focusedId, isNull);
    n.toggleFromDock(a);
    expect(st().byId(a)!.isMinimized, isFalse);
    expect(st().focusedId, a);
  });

  test('close removes window and refocuses', () {
    final a = n.open('a')!;
    final b = n.open('a')!;
    n.close(b);
    expect(st().windows.map((w) => w.id), [a]);
    expect(st().focusedId, a);
    n.close(a);
    expect(st().focusedId, isNull);
  });

  test('maximize and restore round trip', () {
    final a = n.open('a')!;
    final original = st().byId(a)!.rect;
    n.toggleMaximize(a);
    expect(st().byId(a)!.mode, WindowMode.maximized);
    expect(st().byId(a)!.rect, Offset.zero & const Size(1000, 600));
    n.toggleMaximize(a);
    expect(st().byId(a)!.mode, WindowMode.normal);
    expect(st().byId(a)!.rect, original);
  });

  test('snap left/right fill half the desktop', () {
    final a = n.open('a')!;
    n.snapLeft(a);
    expect(st().byId(a)!.rect, const Rect.fromLTWH(0, 0, 500, 600));
    n.snapRight(a);
    expect(st().byId(a)!.rect, const Rect.fromLTWH(500, 0, 500, 600));
    n.restore(a);
    expect(st().byId(a)!.mode, WindowMode.normal);
  });

  test('resize never goes below minimum size', () {
    final a = n.open('a')!;
    n.resizeBy(a, ResizeEdges.bottomRight, const Offset(-5000, -5000));
    expect(
      st().byId(a)!.rect.size,
      const Size(WindowsNotifier.minWidth, WindowsNotifier.minHeight),
    );
  });

  test('move keeps title bar reachable', () {
    final a = n.open('a')!;
    n.move(a, const Offset(0, -5000));
    expect(st().byId(a)!.rect.top, 0);
    n.move(a, const Offset(0, 5000));
    expect(st().byId(a)!.rect.top, lessThan(600));
  });

  test('dragging a maximized window restores it under the pointer', () {
    final a = n.open('a')!;
    final restoreWidth = st().byId(a)!.rect.width;
    n.maximize(a);
    n.startDrag(a, 0.5);
    final w = st().byId(a)!;
    expect(w.mode, WindowMode.normal);
    expect(w.rect.width, restoreWidth);
    // pointer was at x=500 (50% of 1000); window center should match
    expect(w.rect.center.dx, closeTo(500, 0.001));
  });

  test('dropAt top edge maximizes, side edges snap', () {
    final a = n.open('a')!;
    n.dropAt(a, const Offset(400, 2));
    expect(st().byId(a)!.mode, WindowMode.maximized);
    n.restore(a);
    n.dropAt(a, const Offset(1, 300));
    expect(st().byId(a)!.mode, WindowMode.snappedLeft);
    n.restore(a);
    n.dropAt(a, const Offset(999, 300));
    expect(st().byId(a)!.mode, WindowMode.snappedRight);
  });

  test('desktop resize keeps maximized windows filling the screen', () {
    final a = n.open('a')!;
    n.maximize(a);
    n.setDesktopSize(const Size(800, 500));
    expect(st().byId(a)!.rect, Offset.zero & const Size(800, 500));
  });
}

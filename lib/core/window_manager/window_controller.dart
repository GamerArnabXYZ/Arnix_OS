import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_registry/app_registry.dart';
import '../theme/tokens.dart';
import 'models/resize_edges.dart';
import 'models/window_state.dart';

final windowsProvider =
    NotifierProvider<WindowsNotifier, WindowsState>(WindowsNotifier.new);

/// Owns all window state. Pure logic: no widgets, fully unit-testable.
class WindowsNotifier extends Notifier<WindowsState> {
  static const double minWidth = 320;
  static const double minHeight = 200;
  static const double _margin = 24;
  static const double _cascadeStep = 32;
  static const double _grab = 96; // visible px that must stay on screen
  static const double _snapEdge = 6;

  Size _desktop = Size.zero;

  @override
  WindowsState build() => const WindowsState();

  // ---- geometry helpers -------------------------------------------------

  Size get _bounds =>
      _desktop.isEmpty ? const Size(1280, 720) : _desktop;

  Size get _min {
    final b = _bounds;
    return Size(math.min(minWidth, b.width), math.min(minHeight, b.height));
  }

  /// Clamp where [lo] wins if the range is inverted.
  static double _clamp(double v, double lo, double hi) =>
      math.max(lo, math.min(v, hi));

  Rect _fitNormal(Rect r) {
    final b = _bounds;
    final m = _min;
    final w = _clamp(r.width, m.width, b.width);
    final h = _clamp(r.height, m.height, b.height);
    final left = _clamp(r.left, 0, b.width - w);
    final top = _clamp(r.top, 0, b.height - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  Rect _rectFor(WindowMode mode, Rect normal) {
    final b = _bounds;
    switch (mode) {
      case WindowMode.normal:
        return _fitNormal(normal);
      case WindowMode.maximized:
        return Offset.zero & b;
      case WindowMode.snappedLeft:
        return Rect.fromLTWH(0, 0, b.width / 2, b.height);
      case WindowMode.snappedRight:
        return Rect.fromLTWH(b.width / 2, 0, b.width / 2, b.height);
    }
  }

  int _index(int id) => state.windows.indexWhere((w) => w.id == id);

  void _update(int id, WindowState Function(WindowState) f) {
    final i = _index(id);
    if (i < 0) return;
    final old = state.windows[i];
    final next = f(old);
    if (identical(old, next)) return;
    final list = [...state.windows];
    list[i] = next;
    state = state.copyWith(windows: list);
  }

  void _setList(List<WindowState> list) {
    state = state.copyWith(
      windows: list,
      focusedId: WindowsState.topVisible(list),
    );
  }

  // ---- lifecycle ----------------------------------------------------------

  /// Called by the host whenever the desktop area changes size.
  void setDesktopSize(Size size) {
    if (size == _desktop) return;
    _desktop = size;
    var changed = false;
    final list = <WindowState>[];
    for (final w in state.windows) {
      final base = w.restoreRect ?? w.rect;
      final rect = _rectFor(w.mode, w.mode == WindowMode.normal ? w.rect : base);
      if (rect != w.rect) changed = true;
      list.add(rect == w.rect ? w : w.copyWith(rect: rect));
    }
    if (changed) state = state.copyWith(windows: list);
  }

  /// Opens a window for [appId]. Returns its id, or null if unknown app.
  int? open(String appId) {
    final manifest = ref.read(appRegistryProvider).byId(appId);
    if (manifest == null) return null;

    if (manifest.singleInstance) {
      for (final w in state.windows) {
        if (w.appId == appId) {
          focus(w.id);
          return w.id;
        }
      }
    }

    final b = _bounds;
    final m = _min;
    final width = _clamp(
        manifest.defaultSize.width, m.width, math.max(m.width, b.width - 2 * _margin));
    final height = _clamp(
        manifest.defaultSize.height, m.height, math.max(m.height, b.height - 2 * _margin));
    final id = state.nextId;
    final offset = (id % 8) * _cascadeStep;
    final left = _clamp(_margin + offset, 0, b.width - width);
    final top = _clamp(_margin + offset, 0, b.height - height);

    final w = WindowState(
      id: id,
      appId: appId,
      title: manifest.title,
      rect: Rect.fromLTWH(left, top, width, height),
    );
    state = state.copyWith(
      windows: [...state.windows, w],
      focusedId: id,
      nextId: id + 1,
    );
    return id;
  }

  void close(int id) {
    if (_index(id) < 0) return;
    _setList(state.windows.where((w) => w.id != id).toList());
  }

  void focus(int id) {
    final i = _index(id);
    if (i < 0) return;
    final w = state.windows[i];
    if (state.focusedId == id && !w.isMinimized && i == state.windows.length - 1) {
      return;
    }
    final list = [...state.windows]..removeAt(i);
    list.add(w.copyWith(isMinimized: false));
    state = state.copyWith(windows: list, focusedId: id);
  }

  void minimize(int id) {
    if (_index(id) < 0) return;
    _setList([
      for (final w in state.windows)
        w.id == id ? w.copyWith(isMinimized: true) : w,
    ]);
  }

  void minimizeAll() {
    if (state.windows.isEmpty) return;
    _setList([
      for (final w in state.windows) w.isMinimized ? w : w.copyWith(isMinimized: true),
    ]);
  }

  void closeAllOf(String appId) {
    final list = state.windows.where((w) => w.appId != appId).toList();
    if (list.length == state.windows.length) return;
    _setList(list);
  }

  /// Taskbar/dock tap: restore if minimized, minimize if focused, else focus.
  void toggleFromDock(int id) {
    final w = state.byId(id);
    if (w == null) return;
    if (w.isMinimized) {
      focus(id);
    } else if (state.focusedId == id) {
      minimize(id);
    } else {
      focus(id);
    }
  }

  // ---- maximize / snap / restore ------------------------------------------

  void _setMode(int id, WindowMode mode) {
    _update(id, (w) {
      final restore = w.restoreRect ?? w.rect;
      return w.copyWith(
        rect: _rectFor(mode, restore),
        mode: mode,
        restoreRect: restore,
      );
    });
  }

  void maximize(int id) => _setMode(id, WindowMode.maximized);
  void snapLeft(int id) => _setMode(id, WindowMode.snappedLeft);
  void snapRight(int id) => _setMode(id, WindowMode.snappedRight);

  void restore(int id) {
    _update(id, (w) {
      if (w.mode == WindowMode.normal) return w;
      return w.copyWith(
        rect: _fitNormal(w.restoreRect ?? w.rect),
        mode: WindowMode.normal,
        clearRestore: true,
      );
    });
  }

  void toggleMaximize(int id) {
    final w = state.byId(id);
    if (w == null) return;
    if (w.mode == WindowMode.normal) {
      maximize(id);
    } else {
      restore(id);
    }
  }

  // ---- drag / resize --------------------------------------------------------

  /// Call when a title-bar drag starts. Un-maximizes/un-snaps so the window
  /// stays under the pointer ([grabFraction] = 0..1 across the title bar).
  void startDrag(int id, double grabFraction) {
    _update(id, (w) {
      final restore = w.restoreRect;
      if (w.mode == WindowMode.normal || restore == null) return w;
      final b = _bounds;
      final width = math.min(restore.width, b.width);
      final height = math.min(restore.height, b.height);
      final pointerX = w.rect.left + grabFraction * w.rect.width;
      final left =
          _clamp(pointerX - grabFraction * width, -(width - _grab), b.width - _grab);
      return w.copyWith(
        rect: Rect.fromLTWH(left, 0, width, height),
        mode: WindowMode.normal,
        clearRestore: true,
      );
    });
  }

  void move(int id, Offset delta) {
    _update(id, (w) {
      if (w.mode != WindowMode.normal) return w;
      final b = _bounds;
      final left =
          _clamp(w.rect.left + delta.dx, -(w.rect.width - _grab), b.width - _grab);
      final top =
          _clamp(w.rect.top + delta.dy, 0, b.height - Tokens.titleBarHeight);
      return w.copyWith(
        rect: Rect.fromLTWH(left, top, w.rect.width, w.rect.height),
      );
    });
  }

  /// Call when a drag ends. [pointer] is in desktop coordinates.
  void dropAt(int id, Offset pointer) {
    final w = state.byId(id);
    if (w == null || w.mode != WindowMode.normal) return;
    final b = _bounds;
    if (pointer.dy <= _snapEdge) {
      maximize(id);
    } else if (pointer.dx <= _snapEdge) {
      snapLeft(id);
    } else if (pointer.dx >= b.width - _snapEdge) {
      snapRight(id);
    }
  }

  void resizeBy(int id, ResizeEdges edges, Offset delta) {
    _update(id, (w) {
      if (w.mode != WindowMode.normal) return w;
      final r = w.rect;
      final m = _min;
      final b = _bounds;
      var l = r.left;
      var t = r.top;
      var rt = r.right;
      var bt = r.bottom;
      if (edges.left) l = _clamp(l + delta.dx, 0, rt - m.width);
      if (edges.right) rt = _clamp(rt + delta.dx, l + m.width, b.width);
      if (edges.top) t = _clamp(t + delta.dy, 0, bt - m.height);
      if (edges.bottom) bt = _clamp(bt + delta.dy, t + m.height, b.height);
      return w.copyWith(rect: Rect.fromLTRB(l, t, rt, bt));
    });
  }
}

import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

enum WindowMode { normal, maximized, snappedLeft, snappedRight }

@immutable
class WindowState {
  const WindowState({
    required this.id,
    required this.appId,
    required this.title,
    required this.rect,
    this.mode = WindowMode.normal,
    this.restoreRect,
    this.isMinimized = false,
  });

  final int id;
  final String appId;
  final String title;

  /// Position/size in desktop coordinates (desktop layout only).
  final Rect rect;
  final WindowMode mode;

  /// Non-null while [mode] != normal; used to restore.
  final Rect? restoreRect;
  final bool isMinimized;

  WindowState copyWith({
    Rect? rect,
    WindowMode? mode,
    Rect? restoreRect,
    bool clearRestore = false,
    bool? isMinimized,
  }) {
    return WindowState(
      id: id,
      appId: appId,
      title: title,
      rect: rect ?? this.rect,
      mode: mode ?? this.mode,
      restoreRect: clearRestore ? null : (restoreRect ?? this.restoreRect),
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }
}

@immutable
class WindowsState {
  const WindowsState({
    this.windows = const <WindowState>[],
    this.focusedId,
    this.nextId = 1,
  });

  /// Z-order: index 0 = bottom, last = top.
  final List<WindowState> windows;
  final int? focusedId;
  final int nextId;

  static const Object _unset = Object();

  WindowsState copyWith({
    List<WindowState>? windows,
    Object? focusedId = _unset,
    int? nextId,
  }) {
    return WindowsState(
      windows: windows ?? this.windows,
      focusedId: identical(focusedId, _unset)
          ? this.focusedId
          : focusedId as int?,
      nextId: nextId ?? this.nextId,
    );
  }

  WindowState? byId(int id) {
    for (final w in windows) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Top-most window that is not minimized.
  int? get topVisibleId => topVisible(windows);

  static int? topVisible(List<WindowState> list) {
    for (var i = list.length - 1; i >= 0; i--) {
      if (!list[i].isMinimized) return list[i].id;
    }
    return null;
  }
}

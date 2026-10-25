import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_registry/app_registry.dart';
import '../../theme/tokens.dart';
import '../models/resize_edges.dart';
import '../models/window_state.dart';
import '../window_controller.dart';
import 'title_button.dart';

/// Floating window chrome for desktop/tablet layout. Fills its parent
/// (the host positions it).
class WindowFrame extends ConsumerWidget {
  const WindowFrame({
    super.key,
    required this.window,
    required this.isFocused,
    required this.child,
  });

  final WindowState window;
  final bool isFocused;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiled = window.mode != WindowMode.normal;
    final radius = window.mode == WindowMode.normal ? Tokens.windowRadius : 0.0;

    final chrome = Material(
      color: Tokens.surface,
      elevation: isFocused ? 16 : 4,
      shadowColor: Colors.black,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: isFocused ? Tokens.accent : Tokens.outline),
      ),
      child: Column(
        children: [
          _TitleBar(window: window, isFocused: isFocused),
          Expanded(child: child),
        ],
      ),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!isFocused) ref.read(windowsProvider.notifier).focus(window.id);
      },
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            chrome,
            if (!tiled) ..._handles(window.id),
          ],
        ),
      ),
    );
  }

  static List<Widget> _handles(int id) {
    const edge = 8.0;
    const corner = 20.0;
    return [
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.topEdge,
        cursor: SystemMouseCursors.resizeUpDown,
        left: corner,
        right: corner,
        top: 0,
        height: edge,
      ),
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.bottomEdge,
        cursor: SystemMouseCursors.resizeUpDown,
        left: corner,
        right: corner,
        bottom: 0,
        height: edge,
      ),
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.leftEdge,
        cursor: SystemMouseCursors.resizeLeftRight,
        top: corner,
        bottom: corner,
        left: 0,
        width: edge,
      ),
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.rightEdge,
        cursor: SystemMouseCursors.resizeLeftRight,
        top: corner,
        bottom: corner,
        right: 0,
        width: edge,
      ),
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.topLeft,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        left: 0,
        top: 0,
        width: corner,
        height: corner,
      ),
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.topRight,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        right: 0,
        top: 0,
        width: corner,
        height: corner,
      ),
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.bottomLeft,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        left: 0,
        bottom: 0,
        width: corner,
        height: corner,
      ),
      _ResizeHandle(
        windowId: id,
        edges: ResizeEdges.bottomRight,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        right: 0,
        bottom: 0,
        width: corner,
        height: corner,
      ),
    ];
  }
}

class _ResizeHandle extends ConsumerWidget {
  const _ResizeHandle({
    required this.windowId,
    required this.edges,
    required this.cursor,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
  });

  final int windowId;
  final ResizeEdges edges;
  final MouseCursor cursor;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => ref
              .read(windowsProvider.notifier)
              .resizeBy(windowId, edges, d.delta),
        ),
      ),
    );
  }
}

class _TitleBar extends ConsumerStatefulWidget {
  const _TitleBar({required this.window, required this.isFocused});

  final WindowState window;
  final bool isFocused;

  @override
  ConsumerState<_TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends ConsumerState<_TitleBar> {
  Offset _lastLocal = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final w = widget.window;
    final ctrl = ref.read(windowsProvider.notifier);
    final icon = ref.watch(appRegistryProvider).byId(w.appId)?.icon ?? Icons.apps;
    final tiled = w.mode != WindowMode.normal;

    return Material(
      color: widget.isFocused ? Tokens.titleFocused : Tokens.titleUnfocused,
      child: SizedBox(
        height: Tokens.titleBarHeight,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => ctrl.toggleMaximize(w.id),
                onPanStart: (d) {
                  _lastLocal = d.localPosition;
                  final cur = ref.read(windowsProvider).byId(w.id);
                  final width = cur?.rect.width ?? 1;
                  final fraction = (d.localPosition.dx / width).clamp(0.0, 1.0);
                  ctrl.startDrag(w.id, fraction.toDouble());
                },
                onPanUpdate: (d) {
                  _lastLocal = d.localPosition;
                  ctrl.move(w.id, d.delta);
                },
                onPanEnd: (_) {
                  final cur = ref.read(windowsProvider).byId(w.id);
                  if (cur == null) return;
                  ctrl.dropAt(
                    w.id,
                    Offset(cur.rect.left + _lastLocal.dx,
                        cur.rect.top + _lastLocal.dy),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            TitleButton(
              icon: Icons.remove,
              tooltip: 'Minimize',
              onTap: () => ctrl.minimize(w.id),
            ),
            TitleButton(
              icon: tiled ? Icons.filter_none : Icons.crop_square,
              tooltip: tiled ? 'Restore' : 'Maximize',
              onTap: () => ctrl.toggleMaximize(w.id),
            ),
            TitleButton(
              icon: Icons.close,
              tooltip: 'Close',
              onTap: () => ctrl.close(w.id),
            ),
          ],
        ),
      ),
    );
  }
}

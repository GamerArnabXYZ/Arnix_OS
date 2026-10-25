import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_registry/app_registry.dart';
import '../models/window_state.dart';
import '../window_controller.dart';
import '../window_layout.dart';
import 'phone_window_frame.dart';
import 'window_frame.dart';

/// Renders every window. Phone: only the top visible window, fullscreen.
/// Desktop: floating windows in z-order. App content state survives
/// minimize and layout switches (GlobalKey per window).
class WindowHost extends ConsumerStatefulWidget {
  const WindowHost({super.key});

  @override
  ConsumerState<WindowHost> createState() => _WindowHostState();
}

class _WindowHostState extends ConsumerState<WindowHost> {
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(appRegistryProvider);
    final st = ref.watch(windowsProvider);
    final force = ref.watch(forceDesktopProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _lastSize) {
          _lastSize = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(windowsProvider.notifier).setDesktopSize(size);
            }
          });
        }

        final layout = layoutFor(size.width, forceDesktop: force);
        final topVisible = st.topVisibleId;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            for (final w in st.windows)
              _buildWindow(
                context,
                registry,
                w,
                phone: layout == ShellLayout.phone,
                visible: w.id == topVisible,
                focused: w.id == st.focusedId,
              ),
          ],
        );
      },
    );
  }

  Widget _buildWindow(
    BuildContext context,
    AppRegistry registry,
    WindowState w, {
    required bool phone,
    required bool visible,
    required bool focused,
  }) {
    final manifest = registry.byId(w.appId);
    final content = KeyedSubtree(
      key: GlobalObjectKey(w.id),
      child: manifest == null
          ? const SizedBox.shrink()
          : manifest.builder(context, w.id),
    );

    if (phone) {
      return Positioned.fill(
        key: ValueKey<int>(w.id),
        child: _hide(
          !visible,
          PhoneWindowFrame(window: w, child: content),
        ),
      );
    }
    return Positioned.fromRect(
      key: ValueKey<int>(w.id),
      rect: w.rect,
      child: _hide(
        w.isMinimized,
        WindowFrame(window: w, isFocused: focused, child: content),
      ),
    );
  }

  /// Keeps the subtree (and its state) alive but invisible and non-interactive.
  static Widget _hide(bool hidden, Widget child) {
    return Offstage(
      offstage: hidden,
      child: TickerMode(enabled: !hidden, child: child),
    );
  }
}

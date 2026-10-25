import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_registry/app_registry.dart';
import '../../core/theme/tokens.dart';
import '../../core/window_manager/models/window_state.dart';
import '../../core/window_manager/window_controller.dart';
import '../../core/window_manager/window_layout.dart';

/// Phase-1 temporary taskbar: app launchers + running windows + mode toggle.
/// Replaced by the full Puter-style taskbar/launcher in Phase 2.
class Dock extends ConsumerWidget {
  const Dock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(appRegistryProvider);
    final st = ref.watch(windowsProvider);
    final ctrl = ref.read(windowsProvider.notifier);
    final force = ref.watch(forceDesktopProvider);

    final running = [...st.windows]..sort((a, b) => a.id.compareTo(b.id));
    final topVisible = st.topVisibleId;

    return Material(
      color: Tokens.dockBg,
      child: SizedBox(
        height: Tokens.dockHeight,
        child: Row(
          children: [
            const SizedBox(width: 4),
            for (final app in registry.all)
              _DockButton(
                icon: app.icon,
                tooltip: 'Open ${app.title}',
                onTap: () => ctrl.open(app.id),
              ),
            const VerticalDivider(width: 17, indent: 12, endIndent: 12),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final w in running)
                    _WindowChip(
                      window: w,
                      icon: registry.byId(w.appId)?.icon ?? Icons.apps,
                      active: w.id == topVisible,
                      onTap: () => ctrl.toggleFromDock(w.id),
                    ),
                ],
              ),
            ),
            _DockButton(
              icon: force ? Icons.desktop_windows : Icons.smartphone,
              tooltip: force ? 'Desktop mode (on)' : 'Force desktop mode',
              onTap: () => ref.read(forceDesktopProvider.notifier).toggle(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 52,
          height: Tokens.dockHeight,
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.window,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final WindowState window;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dim = window.isMinimized;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Material(
        color: active ? Tokens.chipActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: Tokens.minTouch,
              maxWidth: 160,
              minHeight: Tokens.minTouch,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: dim ? Colors.white38 : null),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      window.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: dim ? Colors.white38 : null),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

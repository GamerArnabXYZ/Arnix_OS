import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/shell_settings.dart';
import '../../core/window_manager/widgets/window_host.dart';
import '../../core/window_manager/window_controller.dart';
import '../../core/window_manager/window_layout.dart';
import '../launcher/app_launcher.dart';
import '../launcher/launcher_panel.dart';
import '../overlays/context_menu.dart';
import '../taskbar/taskbar.dart';
import 'desktop_icons.dart';
import 'wallpapers.dart';

class DesktopShell extends ConsumerWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topId = ref.watch(windowsProvider.select((s) => s.topVisibleId));
    final launcherOpen = ref.watch(launcherOpenProvider);
    final force = ref.watch(forceDesktopProvider);
    final taskbarPosition =
        ref.watch(shellSettingsProvider.select((s) => s.taskbarPosition));

    // Android back: close launcher first, then send top window to background.
    return PopScope(
      canPop: topId == null && !launcherOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (launcherOpen) {
          ref.read(launcherOpenProvider.notifier).close();
        } else if (topId != null) {
          ref.read(windowsProvider.notifier).minimize(topId);
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final layout = layoutFor(constraints.maxWidth, forceDesktop: force);
            final position = layout == ShellLayout.phone
                ? TaskbarPosition.bottom
                : taskbarPosition;

            final area = Expanded(
              child: _DesktopArea(layout: layout, position: position),
            );
            final taskbar = Taskbar(position: position);
            final Widget content = switch (position) {
              TaskbarPosition.bottom => Column(children: [area, taskbar]),
              TaskbarPosition.left => Row(children: [taskbar, area]),
              TaskbarPosition.right => Row(children: [area, taskbar]),
            };

            // Wallpaper is edge-to-edge (behind status bar / notch);
            // everything interactive stays inside the safe area.
            return Stack(
              fit: StackFit.expand,
              children: [
                _Wallpaper(layout: layout),
                SafeArea(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopArea extends ConsumerWidget {
  const _DesktopArea({required this.layout, required this.position});

  final ShellLayout layout;
  final TaskbarPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcherOpen = ref.watch(launcherOpenProvider);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: DesktopIcons(layout: layout)),
        WindowHost(layout: layout),
        if (launcherOpen) LauncherLayer(layout: layout, position: position),
      ],
    );
  }
}

class _Wallpaper extends ConsumerWidget {
  const _Wallpaper({required this.layout});

  final ShellLayout layout;

  static String _label(TaskbarPosition p) => switch (p) {
        TaskbarPosition.bottom => 'Bottom',
        TaskbarPosition.left => 'Left',
        TaskbarPosition.right => 'Right',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index =
        ref.watch(shellSettingsProvider.select((s) => s.wallpaper)) %
            wallpapers.length;

    void menu(Offset p) {
      final settings = ref.read(shellSettingsProvider);
      final notifier = ref.read(shellSettingsProvider.notifier);
      final wm = ref.read(windowsProvider.notifier);
      unawaited(
        showActionMenu(
          context,
          anchor: anchorAt(p),
          actions: [
            MenuAction(
              label: 'Show desktop',
              icon: Icons.desktop_windows,
              onSelected: wm.minimizeAll,
            ),
            MenuAction(
              label: 'Change wallpaper',
              icon: Icons.wallpaper,
              onSelected: () => notifier.nextWallpaper(wallpapers.length),
            ),
            if (layout == ShellLayout.desktop) ...[
              const MenuAction.divider(),
              for (final pos in TaskbarPosition.values)
                if (pos != settings.taskbarPosition)
                  MenuAction(
                    label: 'Taskbar: ${_label(pos)}',
                    icon: Icons.dock,
                    onSelected: () => notifier.setTaskbarPosition(pos),
                  ),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(desktopSelectionProvider.notifier).select(null),
      onLongPressStart: (d) => menu(d.globalPosition),
      onSecondaryTapUp: (d) => menu(d.globalPosition),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: wallpapers[index].colors,
          ),
        ),
      ),
    );
  }
}

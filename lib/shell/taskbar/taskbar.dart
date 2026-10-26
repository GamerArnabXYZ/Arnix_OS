import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/shell_settings.dart';
import '../../core/theme/tokens.dart';
import '../../core/window_manager/window_controller.dart';
import '../../core/window_manager/window_layout.dart';
import '../launcher/app_launcher.dart';
import '../overlays/app_menu.dart';
import '../overlays/context_menu.dart';
import 'taskbar_items.dart';

/// Puter-style taskbar: Start (launcher), pinned + running apps grouped with
/// count badge, tray (clock + layout toggle). Bottom on phone; left/bottom/right
/// on desktop.
class Taskbar extends ConsumerWidget {
  const Taskbar({super.key, required this.position});

  final TaskbarPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vertical = position != TaskbarPosition.bottom;
    final axis = vertical ? Axis.vertical : Axis.horizontal;
    final items = ref.watch(taskbarItemsProvider);
    final launcherOpen = ref.watch(launcherOpenProvider);
    final force = ref.watch(forceDesktopProvider);

    return Material(
      color: Tokens.dockBg,
      child: SizedBox(
        width: vertical ? Tokens.taskbarThickness : null,
        height: vertical ? null : Tokens.taskbarThickness,
        child: Flex(
          direction: axis,
          children: [
            const SizedBox(width: 4, height: 4),
            _StartButton(
              open: launcherOpen,
              onTap: ref.read(launcherOpenProvider.notifier).toggle,
            ),
            if (vertical)
              const Divider(height: 17, indent: 12, endIndent: 12)
            else
              const VerticalDivider(width: 17, indent: 12, endIndent: 12),
            Expanded(
              child: ListView(
                scrollDirection: axis,
                children: [
                  for (final item in items)
                    _TaskbarButton(
                      key: ValueKey<String>(item.app.id),
                      item: item,
                      position: position,
                    ),
                ],
              ),
            ),
            const _TrayClock(),
            _TrayButton(
              icon: force ? Icons.desktop_windows : Icons.smartphone,
              tooltip: force ? 'Desktop mode (on)' : 'Force desktop mode',
              onTap: ref.read(forceDesktopProvider.notifier).toggle,
            ),
            const SizedBox(width: 4, height: 4),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Tooltip(
        message: 'Apps',
        triggerMode: TooltipTriggerMode.manual,
        child: Material(
          color: open ? Tokens.chipActive : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.apps, size: 28, color: Tokens.accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskbarButton extends ConsumerWidget {
  const _TaskbarButton({super.key, required this.item, required this.position});

  final TaskbarItem item;
  final TaskbarPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = item.app;
    final horizontal = position == TaskbarPosition.bottom;
    final count = item.windows.length;

    void openMenu(List<MenuAction> actions) {
      unawaited(
        showActionMenu(context, anchor: anchorOfWidget(context), actions: actions),
      );
    }

    void contextMenu() {
      final wm = ref.read(windowsProvider.notifier);
      openMenu([
        ...appMenuActions(ref, app),
        if (item.running) ...[
          const MenuAction.divider(),
          MenuAction(
            label: count > 1 ? 'Close all windows' : 'Close window',
            icon: Icons.close,
            onSelected: () => wm.closeAllOf(app.id),
          ),
        ],
      ]);
    }

    void onTap() {
      final wm = ref.read(windowsProvider.notifier);
      if (count == 0) {
        ref.read(appLauncherProvider).launch(app.id);
      } else if (count == 1) {
        wm.toggleFromDock(item.windows.first.id);
      } else {
        openMenu([
          for (final w in item.windows)
            MenuAction(
              label: '${w.title} #${w.id}',
              icon: w.isMinimized ? Icons.remove : Icons.crop_square,
              onSelected: () => wm.toggleFromDock(w.id),
            ),
        ]);
      }
    }

    final indicator = Align(
      alignment: switch (position) {
        TaskbarPosition.bottom => Alignment.bottomCenter,
        TaskbarPosition.left => Alignment.centerLeft,
        TaskbarPosition.right => Alignment.centerRight,
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        width: horizontal ? (item.hasFocus ? 20 : 8) : 3,
        height: horizontal ? 3 : (item.hasFocus ? 20 : 8),
        decoration: BoxDecoration(
          color: item.hasFocus ? Tokens.accent : Colors.white54,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Tooltip(
        message: app.title,
        triggerMode: TooltipTriggerMode.manual,
        child: Material(
          color: item.hasFocus ? Tokens.chipActive : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: contextMenu,
            onSecondaryTap: contextMenu,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  Center(child: Icon(app.icon, size: 26)),
                  if (item.running) Positioned.fill(child: indicator),
                  if (count > 1)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Tokens.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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

class _TrayButton extends StatelessWidget {
  const _TrayButton({
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
      triggerMode: TooltipTriggerMode.manual,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

class _TrayClock extends StatefulWidget {
  const _TrayClock();

  @override
  State<_TrayClock> createState() => _TrayClockState();
}

class _TrayClockState extends State<_TrayClock> {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        '${_two(_now.hour)}:${_two(_now.minute)}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

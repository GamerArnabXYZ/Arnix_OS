import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_registry/app_registry.dart';
import '../../core/settings/shell_settings.dart';
import '../../core/theme/tokens.dart';
import '../../core/window_manager/window_layout.dart';
import '../launcher/app_launcher.dart';
import '../overlays/app_menu.dart';
import '../overlays/context_menu.dart';

class DesktopSelectionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? appId) => state = appId;
}

final desktopSelectionProvider =
    NotifierProvider<DesktopSelectionNotifier, String?>(
  DesktopSelectionNotifier.new,
);

/// App shortcuts on the desktop (Phase 3 will source these from the VFS
/// Desktop folder). Phone: tap opens. Desktop: tap selects, double-tap opens.
class DesktopIcons extends ConsumerWidget {
  const DesktopIcons({super.key, required this.layout});

  final ShellLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(shellSettingsProvider.select((s) => s.desktop));
    final registry = ref.watch(appRegistryProvider);
    final selected = ref.watch(desktopSelectionProvider);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        direction: Axis.vertical,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final id in ids)
            if (registry.byId(id) case final app?)
              _DesktopIcon(
                key: ValueKey<String>(id),
                app: app,
                selected: selected == id,
                layout: layout,
              ),
        ],
      ),
    );
  }
}

class _DesktopIcon extends ConsumerWidget {
  const _DesktopIcon({
    super.key,
    required this.app,
    required this.selected,
    required this.layout,
  });

  final AppManifest app;
  final bool selected;
  final ShellLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = layout == ShellLayout.phone;

    void open() => ref.read(appLauncherProvider).launch(app.id);
    void menu(Offset p) {
      ref.read(desktopSelectionProvider.notifier).select(app.id);
      unawaited(
        showActionMenu(
          context,
          anchor: anchorAt(p),
          actions: appMenuActions(ref, app),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: phone
          ? open
          : () => ref.read(desktopSelectionProvider.notifier).select(app.id),
      onDoubleTap: phone ? null : open,
      onLongPressStart: (d) => menu(d.globalPosition),
      onSecondaryTapUp: (d) => menu(d.globalPosition),
      child: Container(
        width: 88,
        height: 96,
        decoration: BoxDecoration(
          color: selected ? const Color(0x334F8CFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Tokens.accent : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(app.icon, size: 36),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                app.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

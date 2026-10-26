import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_registry/app_registry.dart';
import '../../core/settings/shell_settings.dart';
import '../launcher/app_launcher.dart';
import 'context_menu.dart';

/// Shared right-click / long-press menu for an app (launcher, desktop, taskbar).
List<MenuAction> appMenuActions(WidgetRef ref, AppManifest app) {
  final launcher = ref.read(appLauncherProvider);
  final settings = ref.read(shellSettingsProvider);
  final notifier = ref.read(shellSettingsProvider.notifier);
  final pinned = settings.pinned.contains(app.id);
  final onDesktop = settings.desktop.contains(app.id);

  return [
    MenuAction(
      label: 'Open',
      icon: Icons.open_in_new,
      onSelected: () => launcher.launch(app.id),
    ),
    MenuAction(
      label: pinned ? 'Unpin from taskbar' : 'Pin to taskbar',
      icon: Icons.push_pin,
      onSelected: () => notifier.togglePinned(app.id),
    ),
    MenuAction(
      label: onDesktop ? 'Remove from desktop' : 'Add to desktop',
      icon: Icons.desktop_windows,
      onSelected: () => notifier.toggleOnDesktop(app.id),
    ),
  ];
}

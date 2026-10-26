import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/shell_settings.dart';
import '../../core/window_manager/window_controller.dart';

class LauncherOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void close() => state = false;
}

final launcherOpenProvider =
    NotifierProvider<LauncherOpenNotifier, bool>(LauncherOpenNotifier.new);

/// User-initiated app launch: opens a window, records "recent", closes launcher.
class AppLauncher {
  AppLauncher(this._ref);

  final Ref _ref;

  int? launch(String appId) {
    final id = _ref.read(windowsProvider.notifier).open(appId);
    if (id != null) {
      _ref.read(shellSettingsProvider.notifier).addRecent(appId);
      _ref.read(launcherOpenProvider.notifier).close();
    }
    return id;
  }
}

final appLauncherProvider = Provider<AppLauncher>((ref) => AppLauncher(ref));

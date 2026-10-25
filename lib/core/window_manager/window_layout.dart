import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';

enum ShellLayout { phone, desktop }

/// Debug/test toggle: force floating-window layout on a phone.
class ForceDesktopNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final forceDesktopProvider =
    NotifierProvider<ForceDesktopNotifier, bool>(ForceDesktopNotifier.new);

ShellLayout layoutFor(double width, {required bool forceDesktop}) {
  if (forceDesktop) return ShellLayout.desktop;
  return width < Tokens.phoneBreakpoint ? ShellLayout.phone : ShellLayout.desktop;
}

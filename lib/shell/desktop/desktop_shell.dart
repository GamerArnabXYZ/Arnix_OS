import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/window_manager/widgets/window_host.dart';
import '../../core/window_manager/window_controller.dart';
import '../dock/dock.dart';

class DesktopShell extends ConsumerWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topId = ref.watch(windowsProvider.select((s) => s.topVisibleId));

    // Android back = send top window to background (go home).
    return PopScope(
      canPop: topId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && topId != null) {
          ref.read(windowsProvider.notifier).minimize(topId);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Wallpaper(),
                    WindowHost(),
                  ],
                ),
              ),
              const Dock(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wallpaper extends StatelessWidget {
  const _Wallpaper();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Tokens.desktopTop, Tokens.desktopBottom],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/tokens.dart';
import '../models/window_state.dart';
import '../window_controller.dart';
import 'title_button.dart';

/// Fullscreen "card" window for phone layout.
class PhoneWindowFrame extends ConsumerWidget {
  const PhoneWindowFrame({
    super.key,
    required this.window,
    required this.child,
  });

  final WindowState window;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(windowsProvider.notifier);
    return Material(
      color: Tokens.surface,
      child: Column(
        children: [
          Material(
            color: Tokens.titleFocused,
            child: SizedBox(
              height: Tokens.phoneHeaderHeight,
              child: Row(
                children: [
                  TitleButton(
                    icon: Icons.keyboard_arrow_down,
                    tooltip: 'Minimize',
                    onTap: () => ctrl.minimize(window.id),
                  ),
                  Expanded(
                    child: Text(
                      window.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TitleButton(
                    icon: Icons.close,
                    tooltip: 'Close',
                    onTap: () => ctrl.close(window.id),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

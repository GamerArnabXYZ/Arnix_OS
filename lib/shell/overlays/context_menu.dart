import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

@immutable
class MenuAction {
  const MenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
  }) : divider = false;

  const MenuAction.divider()
      : label = '',
        icon = null,
        onSelected = null,
        divider = true;

  final String label;
  final IconData? icon;
  final VoidCallback? onSelected;
  final bool divider;
}

/// Zero-size anchor at a global pointer position.
Rect anchorAt(Offset globalPosition) =>
    Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0);

/// Anchor covering the widget that owns [context].
Rect anchorOfWidget(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Puter-style context menu using the built-in popup menu (touch-sized rows).
Future<void> showActionMenu(
  BuildContext context, {
  required Rect anchor,
  required List<MenuAction> actions,
}) async {
  if (actions.isEmpty) return;
  final overlay = Overlay.of(context).context.findRenderObject();
  if (overlay is! RenderBox) return;
  final position = RelativeRect.fromRect(anchor, Offset.zero & overlay.size);

  final choice = await showMenu<int>(
    context: context,
    position: position,
    items: <PopupMenuEntry<int>>[
      for (var i = 0; i < actions.length; i++)
        if (actions[i].divider)
          const PopupMenuDivider()
        else
          PopupMenuItem<int>(
            value: i,
            height: Tokens.minTouch,
            child: Row(
              children: [
                if (actions[i].icon != null) ...[
                  Icon(actions[i].icon, size: 20),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(actions[i].label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
    ],
  );
  if (choice != null) actions[choice].onSelected?.call();
}

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 48x48 touch-safe icon button used in window title bars.
class TitleButton extends StatelessWidget {
  const TitleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: Tokens.minTouch,
          height: Tokens.minTouch,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Design tokens. Touch-first: every tappable target is >= [minTouch].
abstract final class Tokens {
  // Sizes (dp)
  static const double minTouch = 48;
  static const double titleBarHeight = 48;
  static const double phoneHeaderHeight = 56;
  static const double dockHeight = 64;
  static const double windowRadius = 10;
  static const double phoneBreakpoint = 600;

  // Colors
  static const Color accent = Color(0xFF4F8CFF);
  static const Color desktopTop = Color(0xFF1B2A49);
  static const Color desktopBottom = Color(0xFF0B1020);
  static const Color surface = Color(0xFF161B26);
  static const Color outline = Color(0xFF2A3142);
  static const Color titleFocused = Color(0xFF212838);
  static const Color titleUnfocused = Color(0xFF1A1F2C);
  static const Color dockBg = Color(0xFF0E121C);
  static const Color chipActive = Color(0xFF26304A);
}

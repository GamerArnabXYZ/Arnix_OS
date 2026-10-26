import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

@immutable
class Wallpaper {
  const Wallpaper(this.name, this.colors);

  final String name;
  final List<Color> colors;
}

const List<Wallpaper> wallpapers = <Wallpaper>[
  Wallpaper('Midnight', <Color>[Tokens.desktopTop, Tokens.desktopBottom]),
  Wallpaper('Aurora', <Color>[Color(0xFF0F3D3E), Color(0xFF0B1020)]),
  Wallpaper('Ember', <Color>[Color(0xFF3D1F2B), Color(0xFF120A10)]),
  Wallpaper('Graphite', <Color>[Color(0xFF2A2F3A), Color(0xFF0C0E13)]),
];

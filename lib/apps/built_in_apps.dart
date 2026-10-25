import 'package:flutter/material.dart';

import '../core/app_registry/app_registry.dart';
import 'about/about_app.dart';
import 'hello/hello_app.dart';

/// Compile-time app list (Flutter AOT cannot load third-party code at runtime).
final List<AppManifest> builtInApps = [
  AppManifest(
    id: 'hello',
    title: 'Hello',
    icon: Icons.waving_hand,
    defaultSize: const Size(420, 320),
    builder: (context, windowId) => HelloApp(windowId: windowId),
  ),
  AppManifest(
    id: 'about',
    title: 'About',
    icon: Icons.info_outline,
    defaultSize: const Size(380, 300),
    singleInstance: true,
    builder: (context, windowId) => AboutApp(windowId: windowId),
  ),
];

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the content widget of an app window.
typedef AppBuilder = Widget Function(BuildContext context, int windowId);

/// Static description of a built-in app (Puter's app manifest, compile-time).
@immutable
class AppManifest {
  const AppManifest({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.defaultSize = const Size(480, 360),
    this.singleInstance = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final AppBuilder builder;
  final Size defaultSize;
  final bool singleInstance;
}

class AppRegistry {
  AppRegistry(Iterable<AppManifest> apps)
      : _apps = {for (final a in apps) a.id: a};

  final Map<String, AppManifest> _apps;

  AppManifest? byId(String id) => _apps[id];

  List<AppManifest> get all => List.unmodifiable(_apps.values);
}

/// Must be overridden in `ProviderScope` (see main.dart and tests).
final appRegistryProvider = Provider<AppRegistry>(
  (ref) => throw UnimplementedError('appRegistryProvider must be overridden'),
);

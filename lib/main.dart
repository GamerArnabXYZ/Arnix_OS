import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apps/built_in_apps.dart';
import 'core/app_registry/app_registry.dart';
import 'core/settings/kv_store.dart';
import 'core/theme/app_theme.dart';
import 'shell/desktop/desktop_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: wallpaper draws behind status bar / nav bar / notch.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appRegistryProvider.overrideWithValue(AppRegistry(builtInApps)),
        kvStoreProvider.overrideWithValue(PrefsKvStore(prefs)),
      ],
      child: const ArnixApp(),
    ),
  );
}

class ArnixApp extends StatelessWidget {
  const ArnixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arnix OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const DesktopShell(),
    );
  }
}

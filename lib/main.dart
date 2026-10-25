import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apps/built_in_apps.dart';
import 'core/app_registry/app_registry.dart';
import 'core/theme/app_theme.dart';
import 'shell/desktop/desktop_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        appRegistryProvider.overrideWithValue(AppRegistry(builtInApps)),
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

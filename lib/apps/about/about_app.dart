import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/window_manager/window_controller.dart';

class AboutApp extends ConsumerWidget {
  const AboutApp({super.key, required this.windowId});

  final int windowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(windowsProvider.select((s) => s.windows.length));
    final size = MediaQuery.sizeOf(context);
    final text = Theme.of(context).textTheme.bodyMedium;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Arnix OS', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Phase 2: Taskbar + Launcher', style: text),
          const SizedBox(height: 16),
          Text('Platform: ${defaultTargetPlatform.name}', style: text),
          Text(
            'Screen: ${size.width.round()} x ${size.height.round()} dp',
            style: text,
          ),
          Text('Open windows: $count', style: text),
          Text('This window id: $windowId', style: text),
        ],
      ),
    );
  }
}

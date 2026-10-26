import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/window_manager/window_controller.dart';

class HelloApp extends ConsumerStatefulWidget {
  const HelloApp({super.key, required this.windowId});

  final int windowId;

  @override
  ConsumerState<HelloApp> createState() => _HelloAppState();
}

class _HelloAppState extends ConsumerState<HelloApp> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size(48, 48);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 32),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello from window #${widget.windowId}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: buttonSize),
                  onPressed: () => setState(() => _count++),
                  child: Text('Tapped $_count times'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                  onPressed: () =>
                      ref.read(windowsProvider.notifier).open('hello'),
                  child: const Text('Open another window'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_registry/app_registry.dart';
import '../../core/settings/shell_settings.dart';
import '../../core/theme/tokens.dart';
import '../../core/window_manager/window_layout.dart';
import '../overlays/app_menu.dart';
import '../overlays/context_menu.dart';
import 'app_launcher.dart';

/// Scrim + anchored panel (Puter "start menu": search, recent, all apps).
class LauncherLayer extends ConsumerWidget {
  const LauncherLayer({super.key, required this.layout, required this.position});

  final ShellLayout layout;
  final TaskbarPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = layout == ShellLayout.phone;
    final alignment = phone
        ? Alignment.bottomCenter
        : (position == TaskbarPosition.right
            ? Alignment.bottomRight
            : Alignment.bottomLeft);

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: ref.read(launcherOpenProvider.notifier).close,
          child: const ColoredBox(color: Color(0x66000000)),
        ),
        Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: phone ? double.infinity : 440,
                maxHeight: 520,
              ),
              child: const LauncherPanel(),
            ),
          ),
        ),
      ],
    );
  }
}

class LauncherPanel extends ConsumerStatefulWidget {
  const LauncherPanel({super.key});

  @override
  ConsumerState<LauncherPanel> createState() => _LauncherPanelState();
}

class _LauncherPanelState extends ConsumerState<LauncherPanel> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(appRegistryProvider);
    final recentIds = ref.watch(shellSettingsProvider.select((s) => s.recent));
    final q = _query.trim().toLowerCase();

    final apps = registry.all
        .where((a) => q.isEmpty || a.title.toLowerCase().contains(q))
        .toList();
    final recent = q.isEmpty
        ? recentIds.map(registry.byId).whereType<AppManifest>().toList()
        : const <AppManifest>[];

    return Material(
      color: Tokens.surface,
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (_) {
                if (apps.isNotEmpty) {
                  ref.read(appLauncherProvider).launch(apps.first.id);
                }
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search apps',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recent.isNotEmpty) ...[
                    const _SectionTitle('Recent'),
                    _AppWrap(apps: recent),
                  ],
                  _SectionTitle(q.isEmpty ? 'All apps' : 'Results'),
                  if (apps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No apps found'),
                    )
                  else
                    _AppWrap(apps: apps),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _AppWrap extends StatelessWidget {
  const _AppWrap({required this.apps});

  final List<AppManifest> apps;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final a in apps) _AppTile(app: a)],
    );
  }
}

class _AppTile extends ConsumerWidget {
  const _AppTile({required this.app});

  final AppManifest app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void menu() => unawaited(
          showActionMenu(
            context,
            anchor: anchorOfWidget(context),
            actions: appMenuActions(ref, app),
          ),
        );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(appLauncherProvider).launch(app.id),
        onLongPress: menu,
        onSecondaryTap: menu,
        child: SizedBox(
          width: 88,
          height: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(app.icon, size: 30),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  app.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

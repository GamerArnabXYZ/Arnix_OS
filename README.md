# Arnix OS

100% native Flutter desktop-style OS shell. Design inspired by Puter (AGPL-3.0):
ideas only, no code ported. No WebView, no local server.

## Status
- Phase 1: Window Manager (phone = fullscreen cards, desktop = floating windows,
  snap, resize, minimize, maximize)
- Phase 2: Taskbar (pinned + running, grouped, badge), launcher with search and
  recents, desktop icons, context menus, wallpapers, persistence

## Layout
```
lib/core/{window_manager,app_registry,settings,theme}
lib/shell/{taskbar,launcher,desktop,overlays}
lib/apps/
```

## Build
Platform folders are generated in CI (`flutter create`) and patched for edge-to-edge
(`tools/patch_android.sh`). Push to `main`, download artifacts from the Actions tab.

Local: `flutter create --org com.gax --project-name arnix_os --platforms=android,windows,linux . && bash tools/patch_android.sh && flutter run`

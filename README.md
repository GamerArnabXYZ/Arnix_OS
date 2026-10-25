# Arnix OS

100% native Flutter desktop-style OS shell. Design inspired by Puter (AGPL-3.0):
ideas only, no code ported. No WebView, no local server.

## Status
Phase 1: Window Manager (phone = fullscreen cards, desktop = floating windows,
snap, resize, minimize, maximize).

## Build
Platform folders are generated in CI (`flutter create`). Push to `main` and
download artifacts from the Actions tab (APK / Linux / Windows).

Local: `flutter create --org com.gax --project-name arnix_os --platforms=android,windows,linux . && flutter run`

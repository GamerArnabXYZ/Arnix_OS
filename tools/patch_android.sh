#!/usr/bin/env bash
# Run after `flutter create`. Lets the app draw into the display cutout (notch)
# in landscape, so the wallpaper is truly edge-to-edge.
set -e
for f in android/app/src/main/res/values/styles.xml \
         android/app/src/main/res/values-night/styles.xml; do
  [ -f "$f" ] || continue
  grep -q windowLayoutInDisplayCutoutMode "$f" && continue
  sed -i '/<style name="\(LaunchTheme\|NormalTheme\)"/a\        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>' "$f"
done

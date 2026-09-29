#!/usr/bin/env bash
#
# 构建 macOS 版本并打包成可拖拽安装的 DMG。
#
#   ./tool/build_macos_dmg.sh
#
# 产物：build/轻记账-<版本>.dmg
set -euo pipefail

APP_NAME="轻记账"
VERSION="$(sed -n 's/^version: *//p' pubspec.yaml | head -1 | cut -d+ -f1)"
STAGE="build/dmg"
APP="build/macos/Build/Products/Release/${APP_NAME}.app"
DMG="build/${APP_NAME}-${VERSION}.dmg"

echo "==> 构建 macOS 版本"
env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build macos --release

echo "==> 打包 ${DMG}"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

echo
echo "完成：$(pwd)/${DMG}"
echo "打开 DMG，把「${APP_NAME}」拖进 Applications 即可。"

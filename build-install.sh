#!/bin/bash
# 一键：生成工程 → 构建 Release → 安装到 /Applications → 注册并启用扩展 → 重启 Finder
# 用法：./build-install.sh
set -euo pipefail

cd "$(dirname "$0")"

PROJECT="superRight.xcodeproj"
APP_NAME="superRight.app"
EXT_ID="com.smiler.superRight.FinderExtension"
DEST="/Applications/$APP_NAME"
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

echo "▶ 生成工程"
xcodegen generate >/dev/null

echo "▶ 构建 Release"
xcodebuild -project "$PROJECT" -scheme superRight -configuration Release \
  -destination 'platform=macOS' -allowProvisioningUpdates build >/dev/null

BUILT="$(find "$HOME/Library/Developer/Xcode/DerivedData/superRight-"*/Build/Products/Release \
  -maxdepth 1 -name "$APP_NAME" 2>/dev/null | head -1)"
[ -n "$BUILT" ] || { echo "✗ 未找到构建产物"; exit 1; }

echo "▶ 停掉旧扩展进程"
pkill -f "FinderExtension.appex/Contents/MacOS/FinderExtension" 2>/dev/null || true

echo "▶ 安装到 $DEST"
"$LSREG" -u "$DEST" 2>/dev/null || true
rm -rf "$DEST"
ditto "$BUILT" "$DEST"

echo "▶ 注册 + 启用扩展"
"$LSREG" -f "$DEST"
# 先退掉可能在运行的旧 App，否则 open 只会把旧窗口调到前台、看不到新界面。
osascript -e 'quit app "superRight"' 2>/dev/null || true
pkill -x superRight 2>/dev/null || true
open "$DEST"
pluginkit -e use -i "$EXT_ID" 2>/dev/null || true

echo "▶ 重启 Finder"
killall Finder 2>/dev/null || true

echo "✅ 完成。右键文件夹试试「在 <你的默认终端> 打开」。"

#!/bin/bash
# 编译并打包 SmokeLog（Universal：Apple Silicon + Intel），产出 .app / .zip / .dmg
set -euo pipefail
cd "$(dirname "$0")"

# 同时编译两种架构，否则拿到 Intel Mac 上会打不开
swift build -c release --disable-sandbox --arch arm64 --arch x86_64
BIN_DIR="$(swift build -c release --disable-sandbox --arch arm64 --arch x86_64 --show-bin-path)"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
APP="build/SmokeLog.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/SmokeLog" "$APP/Contents/MacOS/SmokeLog"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

if [ ! -f Resources/AppIcon.icns ]; then
    rm -rf build/AppIcon.iconset
    swift tools/makeicon.swift build/AppIcon.iconset
    iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# ad-hoc 签名（必须，否则另一台 Mac 上会被 Gatekeeper 直接拦）
codesign --force --deep --sign - "$APP" 2>/dev/null || true

# zip：跨机传输备用（签名与权限完整保留）
ditto -c -k --sequesterRsrc --keepParent "$APP" "build/SmokeLog-$VERSION.zip" 2>/dev/null || true

# dmg：对外分发用（拖拽安装）
STAGE="build/dmg-stage"
rm -rf "$STAGE" && mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "SmokeLog" -srcfolder "$STAGE" -ov -format UDZO -quiet "build/SmokeLog-$VERSION.dmg"
rm -rf "$STAGE"

# 顺带算一下校验和，发版时可以贴到 Release 说明里
(cd build && shasum -a 256 "SmokeLog-$VERSION.dmg" | tee "SmokeLog-$VERSION.dmg.sha256")

echo ""
echo "打包完成：${APP}（v${VERSION}）"
lipo -info "$APP/Contents/MacOS/SmokeLog" | sed 's/^/  /'
echo "分发包："
echo "  build/SmokeLog-${VERSION}.dmg"
echo "  build/SmokeLog-${VERSION}.zip"

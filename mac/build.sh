#!/bin/bash
# 编译并打包成可直接双击运行的 .app（Universal：Apple Silicon + Intel）
set -euo pipefail
cd "$(dirname "$0")"

# 同时编译两种架构，否则拿到 Intel Mac 上会打不开
swift build -c release --disable-sandbox --arch arm64 --arch x86_64
BIN_DIR="$(swift build -c release --disable-sandbox --arch arm64 --arch x86_64 --show-bin-path)"

APP="build/抽烟记录.app"
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

# ad-hoc 签名（必须，否则另一台 Mac 上会被 Gatekeeper 拦）
codesign --force --deep --sign - "$APP" 2>/dev/null || true

# 额外打一个 zip：跨机传输时用它，签名和权限能完整保留
ditto -c -k --sequesterRsrc --keepParent "$APP" "build/抽烟记录.zip" 2>/dev/null || true

echo "打包完成：$APP"
lipo -info "$APP/Contents/MacOS/SmokeLog" | sed 's/^/  /'
echo "分发包：build/抽烟记录.zip"

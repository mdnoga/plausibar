#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Plausibar"
BUNDLE_ID="com.plausibar.app"
VERSION="0.1.0"
BUILD_NUMBER="1"

cd "$(dirname "$0")/.."

UNIVERSAL="${UNIVERSAL:-0}"

APP_DIR="build/${APP_NAME}.app"

if [[ "${UNIVERSAL}" == "1" ]]; then
    echo "→ Building universal release binary (arm64 + x86_64)…"
    swift build -c release --arch arm64 --arch x86_64
    BIN_PATH=".build/apple/Products/Release/${APP_NAME}"
else
    echo "→ Building release binary (host arch)…"
    swift build -c release
    BIN_PATH=".build/release/${APP_NAME}"
fi

if [[ ! -f tools/AppIcon.icns ]]; then
    echo "→ Generating app icon…"
    swift tools/make-icon.swift tools/AppIcon.iconset
    iconutil -c icns tools/AppIcon.iconset -o tools/AppIcon.icns
fi

echo "→ Assembling ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"
cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp tools/AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"

cat > "${APP_DIR}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
    <key>NSHumanReadableCopyright</key><string>Copyright © 2026</string>
</dict>
</plist>
EOF

echo "→ Ad-hoc signing (Gatekeeper + Keychain access)…"
codesign --force --deep --sign - "${APP_DIR}"

echo
echo "Built: ${APP_DIR}"
echo
echo "Run:        open ${APP_DIR}"
echo "Install:    mv ${APP_DIR} /Applications/"

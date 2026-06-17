#!/bin/zsh
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
BUNDLE="$REPO_ROOT/macos/rulemak_cdh.bundle"
KEYLAYOUT="$BUNDLE/Contents/Resources/Rulemak-CDH.keylayout"
ICON="$BUNDLE/Contents/Resources/Rulemak-CDH.icns"
ICON_VERIFY="/tmp/rulemak-cdh-icon-verify.$$.iconset"
REGISTER_BIN="/tmp/rulemak-cdh-register-validate.$$"
COMPARE_BIN="/tmp/rulemak-cdh-compare-validate.$$"
ICON_BIN="/tmp/rulemak-cdh-icon-validate.$$"

cleanup() {
    rm -rf "$ICON_VERIFY" "$REGISTER_BIN" "$COMPARE_BIN" "$ICON_BIN"
}
trap cleanup EXIT

/usr/bin/plutil -lint "$BUNDLE/Contents/Info.plist" "$BUNDLE/Contents/version.plist"
/usr/bin/xmllint --noout --dtdvalid /System/Library/DTDs/KeyboardLayout.dtd "$KEYLAYOUT"
/usr/bin/iconutil -c iconset "$ICON" -o "$ICON_VERIFY" >/dev/null
/usr/bin/swiftc -framework Carbon "$SCRIPT_DIR/register-rulemak-cdh.swift" -o "$REGISTER_BIN"
/usr/bin/swiftc -framework Carbon "$SCRIPT_DIR/compare-shortcuts.swift" -o "$COMPARE_BIN"
/usr/bin/swiftc -framework AppKit "$SCRIPT_DIR/render-rulemak-icon.swift" -o "$ICON_BIN"

printf 'Rulemak-CDH bundle validation passed.\n'

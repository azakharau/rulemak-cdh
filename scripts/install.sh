#!/bin/zsh
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
BUNDLE_SRC="$REPO_ROOT/macos/rulemak_cdh.bundle"
KEYLAYOUT_SRC="$BUNDLE_SRC/Contents/Resources/Rulemak-CDH.keylayout"
REGISTER_SRC="$SCRIPT_DIR/register-rulemak-cdh.swift"
REGISTER_BIN="/tmp/rulemak-cdh-register.$$"
STAGE="/tmp/rulemak_cdh.bundle.$$"
ICON_VERIFY="/tmp/rulemak-cdh-icon-verify.$$.iconset"
DEST="/Library/Keyboard Layouts/rulemak_cdh.bundle"

cleanup() {
    rm -rf "$REGISTER_BIN" "$STAGE" "$ICON_VERIFY"
}
trap cleanup EXIT

fail() {
    printf 'Rulemak-CDH install failed: %s\n' "$*" >&2
    /usr/bin/osascript -e 'display alert "Rulemak-CDH install failed" message "'"$*"'" as warning' >/dev/null 2>&1 || true
    exit 1
}

notice() {
    printf '%s\n' "$*"
}

[[ "$(uname -s)" == "Darwin" ]] || fail "this installer only supports macOS"
[[ -d "$BUNDLE_SRC" ]] || fail "missing bundle: $BUNDLE_SRC"
[[ -f "$KEYLAYOUT_SRC" ]] || fail "missing keylayout: $KEYLAYOUT_SRC"
[[ -f "$REGISTER_SRC" ]] || fail "missing registration helper source: $REGISTER_SRC"

/usr/bin/plutil -lint "$BUNDLE_SRC/Contents/Info.plist" "$BUNDLE_SRC/Contents/version.plist" >/dev/null || fail "bundle plist validation failed"
/usr/bin/xmllint --noout --dtdvalid /System/Library/DTDs/KeyboardLayout.dtd "$KEYLAYOUT_SRC" || fail "keylayout XML validation failed"
[[ -f "$BUNDLE_SRC/Contents/Resources/Rulemak-CDH.icns" ]] || fail "missing Rulemak-CDH.icns"
/usr/bin/iconutil -c iconset "$BUNDLE_SRC/Contents/Resources/Rulemak-CDH.icns" -o "$ICON_VERIFY" >/dev/null || fail "icon validation failed"

notice "Building registration helper..."
/usr/bin/swiftc -framework Carbon "$REGISTER_SRC" -o "$REGISTER_BIN" || fail "could not build registration helper"

notice "Staging bundle..."
/usr/bin/ditto "$BUNDLE_SRC" "$STAGE"

notice "Installing Rulemak-CDH to /Library/Keyboard Layouts..."
/usr/bin/osascript <<APPLESCRIPT || fail "administrator install step was cancelled or failed"
do shell script "rm -rf '/Library/Keyboard Layouts/rulemak_cdh.bundle' && /usr/bin/ditto '$STAGE' '/Library/Keyboard Layouts/rulemak_cdh.bundle' && /usr/sbin/chown -R root:wheel '/Library/Keyboard Layouts/rulemak_cdh.bundle' && /bin/chmod -R go+rX '/Library/Keyboard Layouts/rulemak_cdh.bundle' && /usr/bin/xattr -cr '/Library/Keyboard Layouts/rulemak_cdh.bundle' && /usr/bin/touch '/Library/Keyboard Layouts' '/Library/Keyboard Layouts/rulemak_cdh.bundle'" with administrator privileges
APPLESCRIPT

notice "Registering and selecting input source..."
if ! "$REGISTER_BIN" "$DEST"; then
    /usr/bin/open 'x-apple.systempreferences:com.apple.Keyboard-Settings.extension?TextInput' >/dev/null 2>&1 || true
    fail "bundle is installed, but macOS did not enable/select the input source automatically. Open Keyboard Settings > Input Sources and add Rulemak-CDH once."
fi

/usr/bin/plutil -lint "$DEST/Contents/Info.plist" "$DEST/Contents/version.plist" >/dev/null || fail "installed plist validation failed"
/usr/bin/xmllint --noout --dtdvalid /System/Library/DTDs/KeyboardLayout.dtd "$DEST/Contents/Resources/Rulemak-CDH.keylayout" || fail "installed keylayout validation failed"

/usr/bin/killall TextInputMenuAgent 2>/dev/null || true
/usr/bin/killall SystemUIServer 2>/dev/null || true

notice ""
notice "Rulemak-CDH installed and selected."
notice "If the input menu does not update immediately, log out and log back in."
/usr/bin/osascript -e 'display notification "Rulemak-CDH installed and selected" with title "Rulemak-CDH"' >/dev/null 2>&1 || true

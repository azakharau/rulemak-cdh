#!/bin/zsh
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$REPO_ROOT/macos/rulemak_cdh.bundle/Contents/Info.plist")"
NAME="Rulemak-CDH-${VERSION}"
STAGE="/tmp/${NAME}.dmgroot"
DMG_RW="/tmp/${NAME}.rw.dmg"
DMG_OUT="$REPO_ROOT/dist/${NAME}.dmg"
KL_ALIAS_NAME="Keyboard Layouts"

cleanup() {
    /usr/bin/hdiutil detach "/Volumes/${NAME}" -quiet >/dev/null 2>&1 || true
    rm -rf "$STAGE" "$DMG_RW"
}
trap cleanup EXIT

"$SCRIPT_DIR/validate.sh"

rm -rf "$STAGE" "$DMG_RW" "$DMG_OUT"
mkdir -p "$STAGE" "$REPO_ROOT/dist"

/usr/bin/ditto "$REPO_ROOT/macos/rulemak_cdh.bundle" "$STAGE/rulemak_cdh.bundle"
cat > "$STAGE/README.txt" <<'EOF'
Rulemak-CDH install

Drag rulemak_cdh.bundle onto Keyboard Layouts.
Finder will ask for an administrator password because this installs into /Library.

After copying, log out and log back in if Rulemak-CDH does not appear in Input Sources.
EOF

/usr/bin/osascript <<APPLESCRIPT
tell application "Finder"
    make new alias file at POSIX file "$STAGE" to POSIX file "/Library/Keyboard Layouts" with properties {name:"$KL_ALIAS_NAME"}
end tell
APPLESCRIPT

/usr/bin/hdiutil create -volname "$NAME" -srcfolder "$STAGE" -ov -format UDRW "$DMG_RW" >/dev/null

MOUNT_POINT="$(/usr/bin/hdiutil attach "$DMG_RW" -readwrite -noverify -noautoopen | /usr/bin/awk 'index($0, "/Volumes/") { print substr($0, index($0, "/Volumes/")); exit }')"
[[ -n "$MOUNT_POINT" ]] || {
    printf 'Could not mount temporary DMG\n' >&2
    exit 1
}

/usr/bin/osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 720, 430}
        set arrangement of icon view options of container window to not arranged
        set icon size of icon view options of container window to 72
        set position of item "rulemak_cdh.bundle" of container window to {135, 135}
        set position of item "$KL_ALIAS_NAME" of container window to {385, 135}
        set position of item "README.txt" of container window to {260, 245}
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
APPLESCRIPT

/bin/rm -rf "$MOUNT_POINT/.fseventsd"
/usr/bin/hdiutil detach "$MOUNT_POINT" -quiet
/usr/bin/hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUT" >/dev/null
/usr/bin/hdiutil verify "$DMG_OUT" >/dev/null

printf '%s\n' "$DMG_OUT"

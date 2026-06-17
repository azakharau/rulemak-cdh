#!/bin/zsh
set -euo pipefail

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

/usr/bin/osascript <<'APPLESCRIPT'
do shell script "rm -rf '/Library/Keyboard Layouts/rulemak_cdh.bundle' && /usr/bin/touch '/Library/Keyboard Layouts'" with administrator privileges
APPLESCRIPT

/usr/bin/killall TextInputMenuAgent 2>/dev/null || true
/usr/bin/killall SystemUIServer 2>/dev/null || true

printf 'Rulemak-CDH removed from /Library/Keyboard Layouts.\n'
printf 'If it still appears in Input Sources, remove it once in Keyboard Settings and log out/log in.\n'


# Rulemak-CDH

Rulemak-CDH is a Russian phonetic keyboard layout for macOS. It adapts the Rulemak Cyrillic mapping to Colemak-DH / Codemak-DH letter positions, so Russian letters follow the same typing pattern as a Colemak-DH-style Latin layer.

It is packaged for macOS input sources for Rulemak-on-Colemak-DH / Codemak-DH.

## Install on macOS

### Homebrew

```sh
brew install --cask azakharau/tap/rulemak-cdh
```

### GitHub Release DMG

Download `Rulemak-CDH-1.0.6.dmg` from the [latest GitHub Release](https://github.com/azakharau/rulemak-cdh/releases/tag/v1.0.6), then:

1. Open the DMG.
2. Drag `rulemak_cdh.bundle` onto `Keyboard Layouts`.
3. Enter the administrator password when Finder asks.

The DMG installs the bundle into `/Library/Keyboard Layouts` using normal Finder drag-and-drop.

If macOS does not refresh the input menu immediately, log out and log back in.

Developer install is also available:

```sh
make install
```

## Uninstall

Remove:

```sh
sudo rm -rf /Library/Keyboard\ Layouts/rulemak_cdh.bundle
```

Then remove `Rulemak-CDH` from Input Sources if macOS still lists it, and log out/log back in.

## Validate

```sh
make validate
```

This checks:

- `Info.plist`
- `version.plist`
- `Rulemak-CDH.keylayout` against Apple's KeyboardLayout DTD
- `Rulemak-CDH.icns`

## Mapping

Rulemak-CDH uses a Colemak-DH/Codemak-DH adaptation of Rulemak. The macOS input source maps Colemak-DH-style Latin positions to Rulemak Cyrillic output.

```text
Q -> я   W -> ж   F -> ф   P -> п   B -> б
A -> а   R -> р   S -> с   T -> т   G -> г
Z -> з   X -> х   C -> ц   D -> д   V -> в
J -> й   L -> л   U -> у   Y -> ы   ; -> ю
M -> м   N -> н   E -> е   I -> и   O -> о   ' -> ь
K -> к   H -> ч
` -> ё   = -> ъ   \ -> э   [ -> ш   ] -> щ
```

See [docs/mapping.md](docs/mapping.md) for the full table and design notes.

## Shortcuts

Command shortcuts are routed through the Latin key map, so common macOS shortcuts keep working while `Rulemak-CDH` is active:

```text
Cmd+C Cmd+V Cmd+Z Cmd+Shift+Z Cmd+A Cmd+S Cmd+F
```

`scripts/compare-shortcuts.swift` compares the installed layout with macOS `Russian - PC` through `UCKeyTranslate`. The expected result is zero mismatches for printable `Cmd` and `Cmd+Shift` shortcuts. A full byte-for-byte match is not expected for `Control`, `Option`, `Backspace`, `Esc`, and arrow keys because Apple's `Russian - PC` layout returns C0 control codes there, while this bundle stays valid XML and uses normal/delete/function-key outputs.

## Files

```text
macos/rulemak_cdh.bundle/          macOS keyboard layout bundle
scripts/build-dmg.sh                release DMG builder
scripts/compare-shortcuts.swift     Russian - PC shortcut parity diagnostic
scripts/install.sh                  developer installer
scripts/register-rulemak-cdh.swift  Text Input Services registration helper
scripts/render-rulemak-icon.swift   reproducible icon renderer
```

## License

GPL-2.0-only. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

# Security

This project installs a macOS keyboard layout bundle. It does not run a persistent daemon, background process, or network service.

The installer compiles and runs a small local Text Input Services registration helper from `scripts/register-rulemak-cdh.swift`. The helper registers, enables, and selects the installed input source.

If you find a security issue, please open a private GitHub security advisory or contact the repository owner.

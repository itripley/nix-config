# Documentation

This repo turns DESKTOP-OLIVIA (Windows 11) into a NixOS 26.05 system that dual-boots alongside the
existing Windows install. These docs record **what** was set up, **how** it works, and **why** each
choice was made, so the config can be maintained without re-deriving any of it.

| Doc | Read it when you want to know… |
|---|---|
| [INVENTORY.md](INVENTORY.md) | what was found on the Windows machine (hardware, disks, network, apps, dotfiles) and how it was gathered. This is the evidence behind every decision. |
| [DESIGN.md](DESIGN.md) | why the overall shape is what it is: dual-boot target, disk layout, boot loader, flake inputs, stable vs unstable, home-manager, repo structure |
| [MODULES.md](MODULES.md) | what each file and setting does, and why it's there |
| [MIGRATION.md](MIGRATION.md) | where every Windows app went: same app, Linux replacement, or stays on Windows |
| [FEDORA.md](FEDORA.md) | what was taken from the old Fedora 43 install (theme, tiling, apps), the conflicts with the Windows-based setup and how each was decided |
| [FIREFOX.md](FIREFOX.md) | how the Firefox profile (extensions + their data, Sidebery, themes, userChrome) is carried over, and why it's done this way |
| [VERIFICATION.md](VERIFICATION.md) | how the config was checked before install, what broke and how it was fixed, and what is still untested |
| [OPERATIONS.md](OPERATIONS.md) | day-to-day use (rebuild, update, add apps, roll back) and troubleshooting |

Installation steps are in the top-level [README](../README.md).

## Status (2026-11-08)

- **Installed** on the Samsung 850 EVO and booting; `hardware-configuration.nix` is the generated one.
- The install hit four upstream build failures (vscode, openssl 1.1 for Sublime, codex, the neovim
  module). They're fixed in `overlays/build-fixes.nix` and `dev.nix`, and the full system builds
  with every app. See [VERIFICATION.md](VERIFICATION.md#first-real-build-2026-11-08).
- Post-install steps done: SSH keys, WezTerm wallpapers, Firefox profile migration, plex-mpv-shim
  `allow_http`, Adaptive Sync. Logins (NetBird, WARP, Steam, …) and a few hardware checks remain;
  see [VERIFICATION.md](VERIFICATION.md#still-to-check-by-hand).

## Conventions

- Windows-side paths are written as they appear on Windows (`C:\Users\olivi\…`). The Windows user
  is `olivi`; the NixOS user is `olivia`.
- "HM" = home-manager. "nixpkgs" = the pinned `nixos-26.05` branch unless stated otherwise.
- Comments in the `.nix` files explain the *what* briefly. These docs carry the full *why*.

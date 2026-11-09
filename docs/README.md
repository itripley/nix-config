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
| [VERIFICATION.md](VERIFICATION.md) | how the config was checked before install, what broke during and after the install and how it was fixed, what was checked on the real machine, and what is still to check by hand |
| [OPERATIONS.md](OPERATIONS.md) | day-to-day use (rebuild, update, add apps, roll back), keyboard shortcuts, VPN toggles (NetBird/WARP), theme upkeep, and troubleshooting |

Installation steps are in the top-level [README](../README.md).

## Status (2026-11-09)

- **Installed** on the Samsung 850 EVO and in daily use; `hardware-configuration.nix` is the generated one.
- Every app from the original lists builds. Upstream build failures are patched in
  `overlays/build-fixes.nix` ([VERIFICATION.md](VERIFICATION.md#first-real-build-2026-11-08)).
- Done after first boot: SSH keys, WezTerm (package + wallpapers), Firefox profile migration,
  plex-mpv-shim `allow_http`, Adaptive Sync, NetBird on the self-hosted server (exit node off),
  WARP registered, tray toggles for both, and the old **Fedora** setup (theme, Krohnkite, Ulauncher,
  apps; [FEDORA.md](FEDORA.md)).
- Open: the `github-artlivia` deploy key is rejected by GitHub; a few hand checks
  ([VERIFICATION.md](VERIFICATION.md#still-to-check-by-hand)); remaining app logins (Steam, Signal, …).

## History

| Date | What happened | Details |
|---|---|---|
| 2026-11-08 | Config written on Windows from an inventory of the machine; evaluated through Docker on Unraid | [INVENTORY.md](INVENTORY.md), [VERIFICATION.md](VERIFICATION.md) |
| 2026-11-08 | Installed from the Philips USB. Build failures forced commenting out apps during the install. | [VERIFICATION.md](VERIFICATION.md#first-real-build-2026-11-08) |
| 2026-11-08 | Failures diagnosed on the installed system: vscode, openssl 1.1 (Sublime), codex, neovim module. Fixed in an overlay; all apps back. Post-install steps done. | `909310b` |
| 2026-11-08 | WezTerm package added (only its config had been linked) | `bb89df5` |
| 2026-11-08 | NetBird pointed at the self-hosted server, restarted on config changes, exit node deselected | `8628c39`, `93865f2` |
| 2026-11-09 | NetBird tray app autostarts (WARP's already did) | `7644365` |
| 2026-11-09 | Old Fedora setup brought over: theme, Krohnkite, Ulauncher (layout switch → Alt+Shift), apps | `0ef7162`, [FEDORA.md](FEDORA.md) |
| 2026-11-09 | Serein (native Discord client) added as a flake input | DESIGN §4 |
| 2026-11-09 | WARP tray: Cloudflare's Zero Trust-only `warp-taskbar` replaced by warp-cloudflare-gui (consumer on/off) | `cc26af0` |

## Conventions

- Windows-side paths are written as they appear on Windows (`C:\Users\olivi\…`). The Windows user
  is `olivi`; the NixOS user is `olivia`.
- "HM" = home-manager. "nixpkgs" = the pinned `nixos-26.05` branch unless stated otherwise.
- Comments in the `.nix` files explain the *what* briefly. These docs carry the full *why*.

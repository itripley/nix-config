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
| [OPERATIONS.md](OPERATIONS.md) | day-to-day use (rebuild, update, add apps, roll back), keyboard shortcuts, VPN toggles (NetBird/WARP), theme upkeep, troubleshooting, and leftover data from removed apps |

Installation steps are in the top-level [README](../README.md).

## Status (2026-11-09)

- **Installed** on the Samsung 850 EVO and in daily use; `hardware-configuration.nix` is the generated one.
- Every app from the original lists builds. Upstream build failures are patched in
  `overlays/build-fixes.nix` ([VERIFICATION.md](VERIFICATION.md#first-real-build-2026-11-08)).
- Done after first boot: SSH keys, WezTerm (package + wallpapers), Firefox profile migration,
  plex-mpv-shim `allow_http`, Adaptive Sync, NetBird on the self-hosted server (exit node off),
  WARP registered, tray toggles for both, and the old **Fedora** setup (theme, Krohnkite, Ulauncher,
  apps; [FEDORA.md](FEDORA.md)).
- The 2026-11-09 app changes (PhotoCraft + FilmCraft, Claude Desktop, 44 apps removed) are
  **switched to**; the running system was byte-identical to that commit's build. Their hand checks
  are in [VERIFICATION.md](VERIFICATION.md#app-changes-2026-11-09).
- **Audit fixes (2026-11-09, branch `audit-fixes`) build but are not switched to yet.** Apply them
  with `nh os boot` and reboot (the amdgpu overdrive kernel parameter needs a reboot). Do the one-time
  steps and checks in [VERIFICATION.md](VERIFICATION.md#audit-2026-11-09) first.
- Open: the `github-artlivia` deploy key is rejected by GitHub; a few hand checks
  ([VERIFICATION.md](VERIFICATION.md#still-to-check-by-hand)); remaining app logins (Steam, Bitwarden, …).

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
| 2026-11-09 | Serein (native Discord client) added as a flake input | `5d2f60a`, DESIGN §4 |
| 2026-11-09 | PhotoCraft and FilmCraft (ArtCraft) added through the artcraft-nix flake's module | `3c298f4`, DESIGN §4 |
| 2026-11-09 | 43 apps removed (Zen, the JDownloader/Stremio Flatpaks, most chat, image, audio and Wine tools, codex, opencode, …), plus what only they used: Zen input, Thunar shortcut, Vesktop autostart, libvirtd, codex build fix | `1aba8c9`, DESIGN §8 |
| 2026-11-09 | Warehouse removed | `663b28e` |
| 2026-11-09 | Claude Desktop (official Linux beta) added from the claude-desktop-nix flake | `9be83f4`, DESIGN §4 |
| 2026-11-09 | WARP tray: Cloudflare's Zero Trust-only `warp-taskbar` replaced by warp-cloudflare-gui (consumer on/off) | `cc26af0` |
| 2026-11-09 | Best-practice audit. Fixes: root-only `trusted-users`, no legacy channels, `build-vm` works, LACT overdrive, `nix fmt`/`nix flake check`/`nix develop` + CI, warp-gui moved to `pkgs/`, shared nixpkgs config, no hardcoded uid/path, closure 43.1 → 40.6 GiB (orca/speechd, KDE PIM, extra JDKs, second .NET SDK) | branch `audit-fixes`, [VERIFICATION.md](VERIFICATION.md#audit-2026-11-09) |

## Conventions

- Windows-side paths are written as they appear on Windows (`C:\Users\olivi\…`). The Windows user
  is `olivi`; the NixOS user is `olivia`.
- "HM" = home-manager. "nixpkgs" = the pinned `nixos-26.05` branch unless stated otherwise.
- Comments in the `.nix` files explain the *what* briefly. These docs carry the full *why*.

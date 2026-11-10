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
| [MACOS.md](MACOS.md) | the MacBook (`macbook-olivia`, nix-darwin): what was on it, where each app and setting went, progress, what stays manual |
| [OPERATIONS.md](OPERATIONS.md) | day-to-day use (rebuild, update, add apps, roll back), keyboard shortcuts, VPN toggles (NetBird/WARP), theme upkeep, troubleshooting, and leftover data from removed apps |

Installation steps are in the top-level [README](../README.md).

## Status (2026-11-09)

- **MacBook added (2026-11-10):** `darwinConfigurations.macbook-olivia` (nix-darwin) is switched to
  (generation 7: hostname, Nix management, home-manager, CLI packages, shell/git/ssh/neovim/WezTerm, Homebrew declared, macOS defaults, Touch ID sudo, fonts). The remaining steps are tracked in [MACOS.md](MACOS.md#steps).
- **Installed** on the Samsung 850 EVO and in daily use; `hardware-configuration.nix` is the generated one.
- Every app from the original lists builds. Upstream build failures are patched in
  `overlays/build-fixes.nix` ([VERIFICATION.md](VERIFICATION.md#first-real-build-2026-11-08)).
- Done after first boot: SSH keys, WezTerm (package + wallpapers), Firefox profile migration,
  plex-mpv-shim `allow_http`, Adaptive Sync, NetBird on the self-hosted server (exit node off),
  WARP registered, tray toggles for both, and the old **Fedora** setup (theme, Krohnkite, Ulauncher (now Vicinae),
  apps; [FEDORA.md](FEDORA.md)).
- The 2026-11-09 app changes (PhotoCraft + FilmCraft, Claude Desktop, 44 apps removed) are
  **switched to**; the running system was byte-identical to that commit's build. Their hand checks
  are in [VERIFICATION.md](VERIFICATION.md#app-changes-2026-11-09).
- **Audit fixes (2026-11-09) are committed, booted and in use:** the one-time root steps were done,
  and the kernel command line has `amdgpu.ppfeaturemask`. The hand checks are in
  [VERIFICATION.md](VERIFICATION.md#audit-2026-11-09).
- **Everything after the audit is switched to but not committed yet** (Vicinae, Obsidian, VS Code
  extensions, TX-02, WezTerm tabs, the Serein patch, the idle-static fix). On 2026-11-09 the running
  system was exactly the working tree's build. The idle-static fix still needs a **reboot** for its
  kernel-module half (`power_save` is still 10); the WirePlumber half is live.
- **Not switched to yet: the Windows settings sweep** (mpv, plex-mpv-shim, OBS plugins, Chromium
  extensions, RGB colors). Builds; needs `nh os switch`. Its hand steps for plex-mpv-shim, Pear Desktop
  and Claude Code are done; Prism is left ([OPERATIONS.md](OPERATIONS.md#settings-copied-from-windows-by-hand)).
- **Open: audio routing doesn't work.** As of 2026-11-09 Olivia can't get the routing she wants out of
  the Game/Music/Chat sinks, EasyEffects, linuxmeeter (since uninstalled) and qpwgraph together. Observed state and next
  steps: [VERIFICATION.md](VERIFICATION.md#audio-routing-not-working-2026-11-09).
- **Obsidian (2026-11-09) works:** LiveSync pulled the vault, plugins and settings in place.
- **Open: `vicinae.service` restart-loops.** An older Vicinae server (0.23.2, from before the flake
  input) is still running outside the unit, so the unit's server exits with "A server is already
  running". Log out and back in once ([OPERATIONS.md](OPERATIONS.md#troubleshooting)).
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
| 2026-11-09 | Best-practice audit. Fixes: root-only `trusted-users`, no legacy channels, `build-vm` works, LACT overdrive, `nix fmt`/`nix flake check`/`nix develop` + CI, warp-gui moved to `pkgs/`, shared nixpkgs config, no hardcoded uid/path, closure 43.1 → 40.6 GiB (orca/speechd, KDE PIM, extra JDKs, second .NET SDK) | `b96c7e4`…`18fdfd7`, [VERIFICATION.md](VERIFICATION.md#audit-2026-11-09) |
| 2026-11-09 | linuxmeeter (Voicemeeter-style PipeWire mixer) packaged in `pkgs/` and added | never committed, [VERIFICATION.md](VERIFICATION.md#app-changes-2026-11-09) |
| 2026-11-09 | Audio routing reported as not working; live graph recorded, not fixed yet | [VERIFICATION.md](VERIFICATION.md#audio-routing-not-working-2026-11-09) |
| 2026-11-09 | Idle static on the speakers: HDA power saving off, analog output never suspended | `audio.nix` |
| 2026-11-09 | linuxmeeter uninstalled (package recipe removed too; it was never committed) | [VERIFICATION.md](VERIFICATION.md#app-changes-2026-11-09) |
| 2026-11-09 | Ulauncher replaced by Vicinae from its own flake + cachix, per its NixOS and KDE guides (Meta+Space, Meta+V clipboard, blur, focus, input server) | `plasma.nix`, DESIGN §4 |
| 2026-11-09 | Serein: minimum window size patched from 760×520 to 400×300 (hard-coded, no setting) | `apps.nix`, [VERIFICATION.md](VERIFICATION.md#problems-found-after-first-boot-2026-11-0809) #17 |
| 2026-11-09 | Obsidian: the weblivia vault's 19 plugins and 6 themes packaged (pinned to the Windows versions), settings and snippets declared, LiveSync settings seeded from a private file so it pulls the notes | `obsidian.nix`, `pkgs/obsidian-plugins`, [VERIFICATION.md](VERIFICATION.md#obsidian-vault-2026-11-09) |
| 2026-11-09 | VS Code: all 42 Windows extensions (+ nix-ide) declared from the marketplace at the Windows versions, instead of 8 from nixpkgs + Settings Sync | `pkgs/vscode-marketplace`, [VERIFICATION.md](VERIFICATION.md#vs-code-extensions-2026-11-09) |
| 2026-11-09 | TX-02 font for WezTerm and Obsidian: files in gitignored `dotfiles/fonts/`, linked into `~/.local/share/fonts` | `default.nix`, `dotfiles/wezterm/config/fonts.lua` |
| 2026-11-09 | WezTerm: fancy tab bar on, with a close × on each tab (`show_close_tab_button_in_tabs = true`) and the title bar kept dark when unfocused; tab titles lost their rounded ends and own colours so the fancy bar draws the tabs | `dotfiles/wezterm/config/appearance.lua`, `events/tab-title.lua` |
| 2026-11-09 | Virtual desktops: 3 rows (one column) instead of 1, as changed in the KDE GUI, so the next switch keeps it | `plasma.nix` |
| 2026-11-09 | Windows settings sweep: mpv and plex-mpv-shim configs, OBS plugins, Chromium extensions, OpenRGB lowpink colors declared; logins and app state left as hand steps | `mpv.nix`, `apps.nix`, `services.nix`, [VERIFICATION.md](VERIFICATION.md#windows-settings-sweep-2026-11-09) |
| 2026-11-10 | MacBook: Nix installed (NixOS installer), nix-darwin bootstrapped as `macbook-olivia`; repo tooling and checks now also cover aarch64-darwin; desktop drv unchanged | `2256d0e`, [MACOS.md](MACOS.md), DESIGN §11 |
| 2026-11-10 | MacBook: home-manager added for `olivi` (generation 2), HM settings shared with the desktop via `homeManagerModule`; rollback rehearsed | `39c8bbd`, [MACOS.md](MACOS.md#checked) |
| 2026-11-10 | Shared home-manager modules start: `home/shared/cli.nix` (12 CLI tools moved from `dev.nix`/`apps.nix`, desktop package set unchanged); the Mac gets its own CLI list (`home/darwin/cli.nix`) | `13f0528`, MODULES.md |
| 2026-11-10 | Shared home-manager modules for fish, git/ssh and neovim (desktop package set unchanged). The Mac's zsh, fish, git, ssh and dotfile links moved to home-manager, with Nix ahead of Homebrew on PATH; nixpkgs WezTerm replaces the 20240203 release, which rejected the config | `fa820cb`, [MACOS.md](MACOS.md#checked) |
| 2026-11-10 | MacBook: Homebrew declared (28 casks, 24 brews, 3 trusted taps, Keynote); activation never upgrades or removes, so nothing changed on disk. Taphouse is no longer in the App Store and stays manual | `286d6f5`, [MACOS.md](MACOS.md#checked) |
| 2026-11-10 | MacBook: docker uses the Nix buildx/compose plugins (Homebrew plugin dir removed from `~/.docker/config.json`). macOS defaults declared (Dock, Finder, trackpad, clock, Stage Manager); all 34 values matched the live ones, only the Dock list was rewritten | `a252741`, [MACOS.md](MACOS.md#checked) |
| 2026-11-10 | MacBook: Touch ID for sudo from nix-darwin (`touchIdAuth` + `pam_reattach` for tmux); the hand-written `sudo_local` was recognised by hash and moved aside | `9607781`, [MACOS.md](MACOS.md#checked) |
| 2026-11-10 | MacBook: JetBrainsMono Nerd Font from nixpkgs (`/Library/Fonts/Nix Fonts`); the 96 hand-installed copies moved to the backup folder | `996c8e0`, [MACOS.md](MACOS.md#checked) |

## Conventions

- Windows-side paths are written as they appear on Windows (`C:\Users\olivi\…`). The Windows user
  is `olivi`; the NixOS user is `olivia`.
- "HM" = home-manager. "nixpkgs" = the pinned `nixos-26.05` branch unless stated otherwise (`nixpkgs-26.05-darwin` on the Mac).
- Comments in the `.nix` files explain the *what* briefly. These docs carry the full *why*.

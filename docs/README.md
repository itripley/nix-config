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
  WARP registered, tray toggles for both, and the old **Fedora** setup (theme, Krohnkite, Ulauncher (now Vicinae),
  apps; [FEDORA.md](FEDORA.md)).
- The 2026-11-09 app changes (PhotoCraft + FilmCraft, Claude Desktop, 44 apps removed) are
  **switched to**; the running system was byte-identical to that commit's build. Their hand checks
  are in [VERIFICATION.md](VERIFICATION.md#app-changes-2026-11-09).
- **Audit fixes (2026-11-09) are committed, booted and in use:** the one-time root steps were done,
  and the kernel command line has `amdgpu.ppfeaturemask`. The hand checks are in
  [VERIFICATION.md](VERIFICATION.md#audit-2026-11-09).
- **Everything after the audit is committed, booted and in use** (Vicinae, Obsidian, VS Code
  extensions, TX-02, WezTerm tabs, the Serein patch, the idle-static fix). After the 2026-11-09
  reboot the running system was exactly that commit's build, and `power_save` is `0`.
- **Not switched to yet:** the Fedora login screen (SilentSDDM, `desktop.nix`), and Fedora's power
  settings and Breeze for GTK apps (`plasma.nix`). Builds; needs `nh os switch` and a reboot.
- **Not switched to yet: the Windows settings sweep** (mpv, plex-mpv-shim, OBS plugins, Chromium
  extensions, RGB colors). Builds; needs `nh os switch`. Its hand steps for plex-mpv-shim, Pear Desktop
  and Claude Code are done; Prism is left ([OPERATIONS.md](OPERATIONS.md#settings-copied-from-windows-by-hand)).
- **Open: audio routing doesn't work.** As of 2026-11-09 Olivia can't get the routing she wants out of
  the Game/Music/Chat sinks, EasyEffects, linuxmeeter (since uninstalled) and qpwgraph together. Observed state and next
  steps: [VERIFICATION.md](VERIFICATION.md#audio-routing-not-working-2026-11-09).
- **Obsidian (2026-11-09) works:** LiveSync pulled the vault, plugins and settings in place.
- `vicinae.service` no longer restart-loops: after the reboot it's active with 0 restarts and
  `vicinae ping` answers.
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
| 2026-11-09 | Second Fedora sweep (RPM database + config diffs): Fedora's power settings (never sleep, dim 15 min, screen off 30 min) and Breeze for GTK apps added; the rest recorded | `plasma.nix`, [FEDORA.md](FEDORA.md#second-pass-2026-11-09) |
| 2026-11-09 | Login screen from Fedora: SilentSDDM (`rei` preset, own background, JetBrainsMono, round avatar) via its flake's NixOS module; art pulled in with `requireFile` | `flake.nix`, `desktop.nix`, [VERIFICATION.md](VERIFICATION.md#login-screen-2026-11-09) |
| 2026-11-09 | Windows settings sweep: mpv and plex-mpv-shim configs, OBS plugins, Chromium extensions, OpenRGB lowpink colors declared; logins and app state left as hand steps | `mpv.nix`, `apps.nix`, `services.nix`, [VERIFICATION.md](VERIFICATION.md#windows-settings-sweep-2026-11-09) |
| 2026-11-09 | Firefox: native sidebar showed next to Sidebery because Firefox 159 renamed `#sidebar-main` to `#sidebar-container`; `userChrome.css` hides both | `dotfiles/firefox/userChrome.css`, [FIREFOX.md](FIREFOX.md#userchromecss-inactive-on-windows-active-on-nixos) |
| 2026-11-09 | EasyEffects: AirPods Max EQ preset (oratory1990) in `home/olivia/easyeffects.nix` | [MODULES.md](MODULES.md#homeoliviaeasyeffectsnix) |
| 2026-11-09 | plex-mpv-shim: uneven motion on 24p content fixed with `interpolation=yes` + `tscale=oversample` (23.976 fps doesn't divide 165 Hz or 75 Hz; 0 frames were dropped, the cadence was uneven) | `plex-mpv-shim/mpv.conf`, [MODULES.md](MODULES.md#homeoliviampvnix) |

## Conventions

- Windows-side paths are written as they appear on Windows (`C:\Users\olivi\…`). The Windows user
  is `olivi`; the NixOS user is `olivia`.
- "HM" = home-manager. "nixpkgs" = the pinned `nixos-26.05` branch unless stated otherwise.
- Comments in the `.nix` files explain the *what* briefly. These docs carry the full *why*.

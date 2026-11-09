# Verification

What was checked before install, how, what it found, and what remains unproven.

## Why the check runs on the Unraid server

Nix doesn't run natively on Windows, so the config has to be evaluated somewhere Linux-y. Two local
options were tried and both failed because the Windows hypervisor isn't running on the current boot
(details in [INVENTORY.md](INVENTORY.md#windows-side-issue-found-along-the-way)):

| Tried | Result |
|---|---|
| Docker Desktop (local) | engine never starts; API returns HTTP 500, no `docker-desktop` WSL distro |
| NixOS-WSL 2605.7.2 (image downloaded, sha256 verified) | `wsl --install` fails with `HCS_E_HYPERV_NOT_INSTALLED` |
| **Docker on the Unraid server** (Engine 29.8.2, 192.168.1.65, over SSH) | ✅ works, and is the method used |

## How `scripts/verify.ps1` works

1. `git add -A`, because flakes only see tracked files.
2. Tars the tracked files (plus a small `run.sh`) on Windows.
3. Streams the tar over SSH (`~/.ssh/id_unraid`) into `docker run -i --rm nixos/nix`. Nothing is
   written to the server's disks except the Docker volume below.
4. Inside the container:
   `nix eval --raw path:.#nixosConfigurations.desktop-olivia.config.system.build.toplevel.drvPath`.
   This evaluates the **entire system** (every module, option, package and generated file) without
   building or downloading the packages themselves.
5. Prints warnings and `OK: /nix/store/…-nixos-system-desktop-olivia-26.05….drv`, or the error with
   its location in the repo.

`path:.` is used instead of `.` so Nix reads a plain directory: no `.git` is sent, which avoids git's
"dubious ownership" checks in the container.

**Server footprint:** the `nixos/nix` image (~500 MB) and the `nixos-eval-store` volume (~1.1 GB),
which caches downloaded sources so re-runs are fast. Remove both with
`docker volume rm nixos-eval-store && docker rmi nixos/nix` on the server.

## What was found and fixed

| # | Problem | Found by | Fix | Why this fix |
|---|---|---|---|---|
| 1 | `blender-hip` has been removed from nixpkgs (2026-01) | full eval | `pkgsRocm.blender` | The replacement the removal notice names; still the HIP/ROCm build for the 7800 XT. |
| 2 | `openssl-1.1.1w` is insecure, required by `sublime4` | eval, then a per-package probe that forces each package's derivation | permit exactly `openssl-1.1.1w` | Keeps Sublime Text working; scoped by exact name and documented so it's removed with Sublime. |
| 3 | `programs.ssh.matchBlocks` deprecated in HM 26.05 | eval warning | rewritten as `programs.ssh.settings` with OpenSSH directive names | Read the pinned HM module to get the new schema. The system derivation hash was **identical** before and after, proving the generated `~/.ssh/config` is unchanged. |

**Package probe:** all 116 package names (system, user, VS Code extensions, fonts, unstable CLIs) were
checked individually against the pinned nixpkgs for missing, removed, broken/insecure, or
throwing on evaluation. Only #1 and #2 failed.

## Firefox-specific checks

- Evaluated and printed the generated files: `configPath = .config/mozilla/firefox`, `profiles.ini`
  (profile `default-release` → `9ylnf32e.default-release`, default), `user.js` (the three prefs),
  exactly one Firefox (159.0.1) installed, Bitwarden native host passed to the wrapper.
- Pinned nixpkgs Firefox = **159.0.1**, the same as Windows, so the profile can move.
- Read the nixpkgs Firefox wrapper: it sets `MOZ_LEGACY_PROFILES=1` (uses `profiles.ini`, good) and
  `MOZ_ALLOW_DOWNGRADE=1` (no downgrade protection, hence the script's own version guard).
- The migration script was tested on a mock profile; results are in [FIREFOX.md](FIREFOX.md#testing-done-and-not-done).

## Current result

```
OK: /nix/store/…-nixos-system-desktop-olivia-26.05.20261105.c56a87d.drv
```

Zero warnings, zero errors against `flake.lock`. Pinned revisions:

| Input | Branch | Rev |
|---|---|---|
| nixpkgs | nixos-26.05 | `c56a87d8` |
| nixpkgs-unstable | nixos-unstable | `f4a03c00` |
| home-manager | release-26.05 | `24f21905` |
| plasma-manager | | `a19a2a02` |
| disko | | `cedd626e` |
| nix-flatpak | | `02656785` |
| zen-browser | | `5f45f55b` |

## First real build (2026-11-08)

The install itself hit build failures, and to get a bootable system a set of apps in `apps.nix`
and `neovim`/`vscode` in `dev.nix` were commented out. Back on the installed system, the original
config was rebuilt with `nix build --keep-going` to find which packages really fail. Most of the
disabled apps built fine. Only these failed, all because of upstream bugs:

| # | Package | Error | Cause | Fix |
|---|---|---|---|---|
| 4 | `vscode` 1.144.0 | `rm: cannot remove 'resources/app/node_modules/@vscode/ripgrep/bin/rg'` | VS Code moved ripgrep to `@vscode/ripgrep-universal/bin/linux-x64/rg`; nixpkgs' `postPatch` still uses the old path | `overlays/build-fixes.nix`: link nixpkgs' ripgrep at the new paths |
| 5 | `openssl-1.1.1w` → `sublime4` | `30-test_afalg.t ... Failed: 1` | the test uses the running kernel's AF_ALG socket, which Linux 7.3 handles differently | drop that one test |
| 6 | `unstable.codex` 0.167.0 | `AWS_LC_SYS_USE_SYSTEM=1 requires a system-installed AWS-LC`, then `zstd-sys: Can't probe for zstd in pkg-config` | nixpkgs' new `cargoUseSystemLibs` hook forces system C libraries; codex's inputs weren't updated | `dontCargoUseSystemLibs = true` |
| 7 | `programs.neovim` | `Error installing file '.config/nvim/init.lua' outside $HOME` | HM 26.05 always writes `nvim/init.lua`, but `~/.config/nvim` is a live link to `dotfiles/nvim` | `sideloadInitLua = true` (HM passes its lines through the wrapper) |

#7 only showed up after #4–#6 were fixed, because `home-manager-files` is built after the packages.
`makemkv` logs `curl: (22) ... 404` but succeeds: its fetcher falls back to `makemkv.com/download/old/`.
codex is not in the binary cache (it fails on Hydra too), so it compiles locally (~10 min).

After the fixes, the full system (`config.system.build.toplevel`) with **every** app from the
original lists builds.

## Problems found after first boot (2026-11-08/09)

| # | Problem | Cause | Fix | Commit |
|---|---|---|---|---|
| 8 | WezTerm not installed | the original config linked `~/.config/wezterm` but never added the package | `wezterm` in `dev.nix` (plain package; `programs.wezterm` would write `wezterm.lua` into the live link) | `bb89df5` |
| 9 | `netbird up` logged in to NetBird's cloud (`LoginFailed`) | the server is self-hosted at `netbird.weblivia.dev` (found in Windows' `C:\ProgramData\Netbird\default.json`) | `services.netbird.clients.default.config.ManagementURL` | `8628c39` |
| 10 | After `nh os switch`, `netbird up` *still* went to the cloud | the module merges `config.d/50-nixos.json` only when the daemon starts, and a switch doesn't restart it when only that file changes | `systemd.services.netbird.restartTriggers` on that file. (The login was done once with `--management-url`, which also persists.) | `93865f2` |
| 11 | No internet while NetBird is connected | the server pushes **Exit Node (unraid)** (`0.0.0.0/0`, `::/0`); the client auto-selected it, the unraid peer never answered, so all traffic hit WireGuard with no peer (`write: required key not available`) | `netbird networks deselect "Exit Node (unraid)" "Exit Node (unraid)-v6"`, exactly what Windows' `state.json` had. Stored in `/var/lib/netbird/state.json`. | `93865f2` (docs) |
| 12 | No graphical VPN toggle for NetBird | WARP's `warp-taskbar` autostarts from its package; NetBird's tray app doesn't, and a second plain `netbird-ui` in `apps.nix` duplicated the menu entry | `makeAutostartItem` for the module's wrapped `netbird-ui`; dropped the duplicate | `7644365` |
| 13 | Fedora migration: `electron-41.10.7` refused as insecure | stable `ente-desktop` 1.7.22 is pinned to an EOL Electron | `unstable.ente-desktop` (1.7.27) | `0ef7162` |
| 14 | Fedora migration: `wineWowPackages` deprecation warning | renamed in 26.05 | `wineWow64Packages.stable` | `0ef7162` |
| 15 | No WARP on/off switch in the tray | `warp-taskbar` is Zero Trust only: with a free registration each click opens a team sign-in | `home/olivia/warp-gui.nix`: packaged warp-cloudflare-gui, `warp-taskbar` autostart hidden | (uncommitted) |

Other things checked along the way:
- The NetBird tray app (`netbird-ui`) and the CLI both default to the module's socket
  `unix:///var/run/netbird/sock`, so the plain package wasn't broken, just redundant.
- Fedora's Krohnkite binds `Meta+,` / `Meta+\` / `Meta+|` were Krohnkite's own defaults (decoded from
  `kglobalshortcutsrc` escaping), so they're left for Krohnkite to register.
- plasma-manager splits `configFile` group names on `/`, so `"Greeter/Wallpaper/<plugin>/General"`
  becomes `[Greeter][Wallpaper][<plugin>][General]` (checked in the generated `data.json`).
- The theme artwork links point at `themes/art/` through the store (`mkOutOfStoreSymlink`), and only
  `art/.gitkeep` is tracked by git.

## Checked on the installed system (2026-11-08)

| Area | Result |
|---|---|
| Disk id / disko | ✅ installed on the Samsung, Windows NVMe untouched |
| Display | ✅ DP-1 2560×1440 @ 165 Hz picked automatically; Adaptive Sync set to *Automatic* (`kscreen-doctor output.DP-1.vrrpolicy.automatic`). A second 1600×1200 @ 75 Hz monitor is on DP-2. |
| Services | ✅ `lactd`, `ollama`, `openrgb`, `docker`, `netbird`, `cloudflare-warp` running; no failed units |
| NetBird | ✅ logged in to `netbird.weblivia.dev`; Management, Signal and 2/2 relays connected, 2/5 peers; internet works with it up (exit node deselected). Tray app autostarts. |
| WARP | ✅ registered (free account); `warp-cli` works. ✅ confirmed `warp-taskbar` is Zero Trust only (no switch for the free account); replaced by `warp-gui.nix`, whose tray icon was checked to register with Plasma. Don't connect WARP and NetBird at the same time (both change routing and DNS). |
| PipeWire virtual sinks | ✅ `virtual_game`, `virtual_music`, `virtual_chat` exist. Newer `wpctl status` lists them under **Filters**, not Sinks. |
| SMB mounts | ✅ `/mnt/unraid/*` automount with the credentials file |
| `/mnt/windows` | ✅ mounted read-only (ntfs3) |
| Flatpaks | ✅ JDownloader and Stremio installed |
| SSH | ✅ `ssh unraid` works. ❌ `github-artlivia`: GitHub rejects the deploy key (`Permission denied (publickey)`); re-add `id_ed25519_artlivia.pub` as a deploy key on `itripley/artlivia`. |
| Firefox migration | ✅ script ran: 126 profile add-ons (22 enabled). Opening it in Firefox is still to be checked. |

## Still to check by hand

| Area | How |
|---|---|
| Plasma shortcuts | System Settings → Shortcuts; adjust `plasma.nix` if a KWin action name differs. |
| ROCm in Resolve / Blender / Ollama | Render with HIP in Blender, run a model and check `ollama ps` shows GPU. |
| Seiren Mini + EasyEffects | Record a test clip. |
| Firefox | Open it: add-ons, Sidebery panels, logins and tabs should all be there. |
| Fedora theme (after `nh os switch` + re-login) | Catppuccin colors, Klassy borders, Lain splash, Bocchi cursor, per-screen wallpapers, animated lock screen (Meta+L). |
| Krohnkite | New windows tile; Meta+H/J/K focus, Meta+Shift+H/J/K/L move. If not, System Settings → Window Management → KWin Scripts → Krohnkite. |
| Ulauncher | Meta+Space opens it; Alt+Shift switches pt/us. |
| GNOME Boxes | Needs the `libvirtd` group, so a re-login after the switch. |
| `github-artlivia` deploy key | Re-add the public key on GitHub, then `git ls-remote git@github-artlivia:itripley/artlivia.git`. |

After any edit, build before switching: `nh os build` (or `nh os switch`, which stops on errors
before activating). `scripts/verify.ps1` is still useful when editing from Windows.

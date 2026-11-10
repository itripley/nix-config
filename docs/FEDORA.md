# Fedora migration

The old Linux install (Fedora 43 KDE Plasma, home `olivi`) is on the 119 GB drive mounted at
`/run/media/olivia/fedora` (btrfs subvolumes `root` and `home`). This records what was found there
(2026-11-09), where each piece went, and what was left behind on purpose.

## How it was inventoried

| Source | What it gave |
|---|---|
| `root/usr/lib/sysimage/libdnf5/packages.toml` | the 86 packages marked as installed by the user |
| `root/usr/lib/sysimage/libdnf5/transaction_history.sqlite` (read from a copy) | every `dnf install/remove` command, in order: 65 transactions |
| `root/etc/yum.repos.d/` | third-party repos and COPRs (WezTerm nightly, Zen, lazygit, NoiseTorch, walker, i3lock-color, davinci-helper, …) |
| `root/var/lib/flatpak/app/` | 12 system Flatpaks |
| `root/etc/systemd/system/*.wants` | enabled services: docker, tailscaled, warp-svc, virtqemud, nvidia-powerd, tuned |
| `home/olivi/.config`, `.local/share`, `.icons` | Plasma theme, KWin scripts/effects, shortcuts, autostart, app configs |

## Decisions on conflicts

| Conflict | Fedora | NixOS before | Chosen |
|---|---|---|---|
| Desktop look | Catppuccin Macchiato, Klassy, Lain splash, Bocchi cursor, cube/translucency/kinetic effects | Breeze Dark (from Windows) | **Fedora look** |
| Tiling keys | Krohnkite on Meta+H/J/K/L (+Shift move, +Ctrl resize) | Windows komorebi binds on Alt+H/J/K/L and Alt+Shift+H/J/K/L | **Krohnkite on Meta**. The Alt binds are reset to KDE defaults; Alt+Q close and Alt+M minimize are kept. |
| Super+Space | Ulauncher | switch keyboard layout (as on Windows) | **Ulauncher**, later replaced by **Vicinae** on the same key. Layout switch moved to **Alt+Shift**. |
| Default browser | Zen | Firefox (Windows profile migrated) | **Firefox** stays. Zen was installed until 2026-11-09; its Fedora profile was not copied. |
| Tailscale | installed and enabled | NetBird | **not added** (NetBird replaced it) |
| NoiseTorch | installed | EasyEffects (RNNoise) | **not added**: two noise filters would stack |
| chezmoi | managed `itripley/dotfiles` | this repo live-links wezterm/nvim/fastfetch | **not added**. The three configs are byte-identical in both places, and `chezmoi apply` would write into this repo through the live links. |

## Where everything went

### Plasma look (`home/olivia/plasma.nix`, files in `home/olivia/themes/`)

| Fedora | NixOS |
|---|---|
| `~/.local/share/color-schemes/CatppuccinMacchiato.colors` | `themes/color-schemes/`, `workspace.colorScheme` |
| Klassy decoration (`klassyrc`) | `klassy` (system), `workspace.windowDecorations`, `configFile.klassyrc` |
| `breezerc` ShadowSize=None | `configFile.breezerc` |
| Plasma style "default", icons breeze-dark | `workspace.theme`, `workspace.iconTheme` |
| Splash "Lain" (look-and-feel package, only used as splash) | `themes/art/Lain`, `workspace.splashScreen.theme` |
| Cursor Bocchi-The-Cursor-Alt-Cross, size 24 | `themes/art/…`, `workspace.cursor` |
| Wallpapers (screen 0 `GpIWw6Ma4AAXh2A.png`, screen 1 `D2uFrIz.png`) | `themes/art/wallpapers/`, `workspace.wallpaper` (per screen) |
| Krohnkite script + gaps | `kdePackages.krohnkite` (system), `configFile.kwinrc."Script-krohnkite"` |
| Effects: cube (with skybox image), translucency, kinetic_maximize | `configFile.kwinrc.Plugins` / `Effect-*`, `themes/kwin-effects/kinetic_maximize` |
| 3 virtual desktops, 1 row | `kwin.virtualDesktops` (now 3 rows, one column, since 2026-11-09) |
| Tiling padding 4 | `configFile.kwinrc.Tiling` |
| Animated lock screen (Smart Video Wallpaper Reborn + `~/Videos/lockscreen.gif`) | `themes/plasma-wallpapers/…`, `kdePackages.qtmultimedia` (system), `configFile.kscreenlockerrc` |
| WezTerm as KDE's terminal | `configFile.kdeglobals.General` |
| Meta+Return WezTerm, Meta+F Thunar | `shortcuts."services/…"._launch` |

Not carried over: the "Lagtrain" global theme and "Layan" Aurorae theme (installed but not in use),
the kinetic_scale/kinetic_squash effects and wobbly windows (configured but switched off), Klassy's
auto-generated icon themes, and the panel layout (stock Plasma: two floating panels; set it up in the
GUI if the defaults differ).

**Artwork stays out of git.** The repo is public, so the splash, cursor (no license file), wallpapers
and GIF live in the gitignored `themes/art/` like the WezTerm backdrops. `themes/README.md` has the
copy commands for a fresh checkout. The colors (MIT), Krohnkite (MIT, from nixpkgs), kinetic effect
and video-wallpaper plugin (GPL) are code and are committed.

### Apps

| Fedora | NixOS |
|---|---|
| wezterm, zen-browser, git, fish, neovim, lazygit, fastfetch, lutris, steam, obs-studio, docker, cloudflare-warp, dotnet-sdk | already in the config |
| Flatpaks: Bitwarden, Tidal-hifi, Plexamp, VS Code, Vesktop, LocalSend, Prism Launcher, Plex | already in the config (as nixpkgs packages) |
| ulauncher | replaced by Vicinae: `vicinae` flake input + `programs.vicinae` (`plasma.nix`), Meta+Space through `hotkeys.commands` → `vicinae toggle` |
| thunar, btop, w3m, gnome-boxes, distrobox, pokemon-colorscripts | `apps.nix` (btop and pokemon-colorscripts are in `home/shared/` since 2026-11-10) |
| ente (Ente Photos rpm) | `unstable.ente-desktop` (stable's 1.7.22 is pinned to EOL Electron 41) |
| Flatpaks DistroShelf, Warehouse, High Tide | `distroshelf`, `warehouse`, `high-tide` from nixpkgs |
| wine, winetricks | `wineWow64Packages.stable`, `winetricks` |
| cargo, go, lazydocker (~/.local/bin) | `rustup`, `go`, `lazydocker` (`home/shared/cli.nix`); `~/.cargo/bin` and `~/go/bin` on PATH (`home/shared/shell.nix`) |
| virtqemud (GNOME Boxes VMs) | `virtualisation.libvirtd` + `libvirtd` group |
| fish greeting `pokemon-colorscripts -r` | `programs.fish.functions.fish_greeting` (`home/shared/shell.nix`) |
| Vesktop at login | `xdg.autostart.entries` (`default.nix`) |

Copied once into the home folder (app state, not config, so not in the repo): Ulauncher's
settings and its 4 extensions (File Search, Process Murderer, Bitwarden Search, Terminal Runner;
now unused, since Vicinae replaced Ulauncher), and Thunar's `accels.scm`/`uca.xml`. Thunar's "Open Terminal Here" was changed from `exo-open` (not
installed) to `wezterm start --cwd %f`.

### Left behind

| Fedora | Why |
|---|---|
| NVIDIA driver, CUDA, `nvidia-powerd` | this machine has an AMD GPU now |
| i3lock-color, dunst, feh, xrdb/xset, swaylock, zig, `*-devel` headers | an X11 lock-screen build experiment; not used on Plasma Wayland. Use `nix shell` for build deps. |
| dnf tooling (yumex, dnf5daemon), `apt`, Fedora/RPM Fusion repos | NixOS manages packages |
| davinci-helper, python3.11, libxcrypt-compat | Resolve's install helper; `davinci-resolve` is packaged |
| python3-pyqt6, gtk4/pydantic/pygobject | dev deps for a one-off project; use a `nix shell` or a flake dev shell |
| Tailscale, NoiseTorch, chezmoi, Zen as default | see decisions above |
| FireDragon (Flatpak) | not in nixpkgs. Add `org.garudalinux.firedragon` to `flatpak.nix` if wanted. |
| Arch OS Manager autostart | an Arch tool, not Fedora; does nothing here |
| `tuned` | `power-profiles-daemon` (Plasma's default) covers it |

### Not copied, worth knowing about

| What | Where on the Fedora drive | Notes |
|---|---|---|
| Zen browser profile (release, Zen 1.17.6b) | `home/olivi/.zen` (39 MB) | Zen was removed on 2026-11-09. (It was at 1.24.1b here, so the profile would have upgraded fine.) |
| A second, older Zen profile **with cookies, `logins.json` and `key4.db`** | committed in the private `itripley/dotfiles` repo (`dot_config/zen/`) | Private repo, but those are saved passwords and live sessions. Consider removing them from that repo's history. |
| GNOME Boxes VMs | `home/olivi/.local/share/gnome-boxes` (12 GB) | GNOME Boxes was removed on 2026-11-09; they'd need it (and libvirtd) back |
| Affinity (Wine) | `home/olivi/.AffinityLinux` | its own Wine build and prefix; reinstall rather than copy |
| Display scale | Fedora: 1.25 (main) / 1.2 (second) | NixOS currently 1.1 / 1. Set in System Settings → Display; not managed by the config. |
| Default text editor | Fedora: Sublime for text/JSON/YAML/Markdown | Set in System Settings → Default Applications. Declaring it with `xdg.mimeApps` would make `mimeapps.list` read-only for the GUI. |

**2026-11-09:** Zen, Thunar (and its Meta+F shortcut), w3m, Ente, GNOME Boxes (and libvirtd),
distrobox, DistroShelf, Warehouse, Wine, winetricks and the Vesktop autostart were removed again. The tables above
record the migration as it was done.

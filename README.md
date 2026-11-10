# nixos-config — desktop-olivia + macbook-olivia

NixOS 26.05 flake for DESKTOP-OLIVIA, dual-booting with the existing Windows 11 install.
The MacBook (M1) is a second host, `darwinConfigurations.macbook-olivia` (nix-darwin): see [macOS](#macos).
Generated from an inventory of the Windows machine (hardware, apps, dotfiles, network setup).

| | |
|---|---|
| CPU / GPU | Ryzen 7 7700X / Radeon RX 7800 XT (amdgpu + ROCm, LACT) |
| Desktop | KDE Plasma 6 (Wayland), Catppuccin Macchiato + Klassy, Krohnkite tiling, pt + us layouts (Alt+Shift) |
| NixOS disk | Samsung 850 EVO 500GB — btrfs, own ESP, systemd-boot |
| Windows disk | Fanxiang S770 1TB — untouched, mounted read-only at `/mnt/windows` |
| Unraid | `//192.168.1.65/{appdata,downloads,files}` → `/mnt/unraid/*` (automount) |

```
flake.nix                      inputs + nixosConfigurations.desktop-olivia + darwinConfigurations.macbook-olivia (+ packages, formatter, checks, devShells)
hosts/desktop-olivia/          configuration.nix, disko.nix, hardware-configuration.nix (generated at install)
hosts/macbook-olivia/          configuration.nix: the Mac (nix-darwin): hostname, Nix, Touch ID, fonts
overlays/                      build-fixes.nix (upstream build workarounds), packages.nix (adds pkgs/)
pkgs/                          packages written for this repo (warp-cloudflare-gui, obsidian-plugins, vscode-marketplace)
modules/nixos/                 boot, amd, desktop, audio, networking, storage, gaming, services
modules/darwin/                homebrew (casks, brews, App Store), defaults (Dock, Finder, trackpad, …)
home/shared/                   home-manager modules both machines use: CLI tools, fish, git/ssh, neovim, dotfile links
home/darwin/                   home-manager for the Mac user (olivi): zsh, Mac CLI tools, git additions
home/olivia/                   home-manager: apps, dev (git/ssh/nvim/vscode), firefox, plasma, flatpak, warp-gui, obsidian
home/olivia/dotfiles/          wezterm, nvim (LazyVim), fastfetch, firefox userChrome — copied from Windows; fonts/ (gitignored)
home/olivia/themes/            Plasma theme from the old Fedora install (artwork in art/, gitignored)
scripts/                       verify.ps1 (check from Windows), migrate-firefox-profile.sh (run on NixOS)
docs/                          full documentation: what, how and why
```

## Documentation

| | |
|---|---|
| [docs/README.md](docs/README.md) | index and current status |
| [docs/INVENTORY.md](docs/INVENTORY.md) | what was found on Windows: the evidence behind every choice |
| [docs/DESIGN.md](docs/DESIGN.md) | why: dual-boot, disk layout, boot, flake inputs, structure |
| [docs/MODULES.md](docs/MODULES.md) | every file and setting, what it does and why |
| [docs/MIGRATION.md](docs/MIGRATION.md) | every Windows app and where it went |
| [docs/FIREFOX.md](docs/FIREFOX.md) | the Firefox profile migration |
| [docs/FEDORA.md](docs/FEDORA.md) | what came over from the old Fedora install, and the conflicts |
| [docs/VERIFICATION.md](docs/VERIFICATION.md) | how it was checked, what broke and was fixed (before and after install), what to check by hand |
| [docs/MACOS.md](docs/MACOS.md) | the MacBook: inventory, migration steps, what was checked, what stays manual |
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | day-to-day use, keyboard shortcuts, VPN toggles, theme, troubleshooting |

## Before you start (in Windows)

1. **Back up anything on the Samsung 850 EVO.** It currently holds two partitions Windows can't
   read (457GB + 8.8GB — likely an old Linux install). The install **erases the whole disk**.
2. **Turn off Fast Startup** (it's currently on): Control Panel → Power Options → "Choose what the
   power buttons do" → untick *Turn on fast startup*. Or in an admin shell: `powercfg /h off`.
   Otherwise Windows leaves C: locked and Linux can't mount it.
3. After any edit, check the config still evaluates: `pwsh -File scripts\verify.ps1`.
   It runs `nix eval` in a throwaway `nixos/nix` container on the Unraid server's Docker over SSH
   (key `~/.ssh/id_unraid`); the Nix store is cached in the server's `nixos-eval-store` volume.
4. Commit and `git push` any changes. The installer clones from
   [github.com/itripley/nixos-config](https://github.com/itripley/nixos-config), so unpushed edits won't be there.
5. Installer: the **Philips portable SSD** already has the NixOS graphical ISO flashed on it.
   Any recent NixOS ISO works: `nixos-install --flake` uses the pinned nixpkgs from `flake.lock`,
   not the ISO's. It can stay plugged in during the install, because disko only targets the
   Samsung disk (by serial). To reuse the drive for storage afterwards, delete its partitions
   (Disk Management or `diskpart` → `clean`) and reformat it.

## Install

Boot the USB from the ASUS boot menu (**F8**), connect to the network, open a terminal:

```sh
git clone https://github.com/itripley/nixos-config ~/nixos-config && cd ~/nixos-config
# (if git is missing on the ISO: nix-shell -p git, then run the line above)

# 0. Make sure the config evaluates BEFORE touching any disk (prints a /nix/store/...drv path)
nix --experimental-features "nix-command flakes" eval --raw \
  .#nixosConfigurations.desktop-olivia.config.system.build.toplevel.drvPath

# 1. CHECK the disk id. It must be the 500GB Samsung — if the name differs, fix disko.nix first.
ls -l /dev/disk/by-id/ | grep Samsung

# 2. Partition + format + mount the Samsung disk (destructive, Samsung only)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount hosts/desktop-olivia/disko.nix

# 3. Hardware config for this machine (overwrites the committed one; normally identical)
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/desktop-olivia/
# The generated stock config isn't used; left there, a plain `nixos-rebuild` without --flake would build it
sudo rm /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/hardware-configuration.nix
git add -A

# 4. SMB credentials for the Unraid shares (not stored in the repo)
sudo install -m 600 /dev/null /mnt/etc/nixos/smb-secrets
printf 'username=YOUR_USER\npassword=YOUR_PASS\n' | sudo tee /mnt/etc/nixos/smb-secrets >/dev/null

# 5. Install
# --no-channel-copy: the flake pins nixpkgs, so don't copy the ISO's channel for root
sudo nixos-install --flake .#desktop-olivia --no-channel-copy
sudo nixos-enter --root /mnt -c 'passwd olivia'

# 6. Keep the repo where the config expects it (dotfile links + `nh` point here)
sudo cp -r ~/nixos-config /mnt/home/olivia/ && sudo nixos-enter --root /mnt -c 'chown -R olivia:users /home/olivia/nixos-config'
reboot
```

## After first boot

- **Boot order:** the installer makes NixOS (systemd-boot) the default. Pick Windows from **F8** at
  power-on. To get a Windows entry in the systemd-boot menu instead, see
  `boot.loader.systemd-boot.windows` (needs the EFI shell handle of the Windows ESP).
- **SSH keys:** `mkdir -m700 ~/.ssh && cp /mnt/windows/Users/olivi/.ssh/id_* ~/.ssh/ && chmod 600 ~/.ssh/id_*`
  (hosts `github-artlivia` and `unraid` are already configured).
- **Firefox profile:** close Firefox (on Windows too, before rebooting), then run
  `~/nixos-config/scripts/migrate-firefox-profile.sh`. It copies the whole Windows profile from
  `/mnt/windows` into `~/.config/mozilla/firefox/9ylnf32e.default-release`. That brings over all
  add-ons with their settings and data (Sidebery panels, uBlock filters, ScriptCat scripts…), themes,
  logins, cookies, history and open tabs. It refuses if Windows' Firefox is newer than NixOS'; run
  `nh os switch --update` first in that case. See [docs/FIREFOX.md](docs/FIREFOX.md).
- **WezTerm wallpapers:** `cp /mnt/windows/Users/olivi/.config/wezterm/backdrops/* ~/nixos-config/home/olivia/dotfiles/wezterm/backdrops/`
- **plex-mpv-shim:** run it once, then set `"allow_http": true` in `~/.config/plex-mpv-shim/conf.json`
  (Plex desktop casts use plain HTTP).
- **Monitor:** System Settings → Display → set 2560×1440 @ 165 Hz and Adaptive Sync "Automatic" if not picked.
- **NetBird** (self-hosted, `networking.nix`): `netbird up` (add `--setup-key <key>` if SSO isn't
  set up), then **turn off the server's exit node** or the internet stops working while connected:
  `netbird networks deselect "Exit Node (unraid)" "Exit Node (unraid)-v6"`. Check with
  `netbird status` and `netbird networks list`.
- **WARP:** `warp-cli registration new`, then `warp-cli connect` / `disconnect` (or the *Cloudflare Warp*
  tray icon from `home/olivia/warp-gui.nix`; Cloudflare's own tray app is Zero Trust only). Don't run it at the
  same time as NetBird.
- **Other logins:** Steam, Heroic, Bitwarden, Claude Desktop, VS Code Settings Sync (settings only; the
  extensions are declared in `dev.nix`).
- **Obsidian:** copy the LiveSync and Paperless settings into `~/.config/obsidian-seed/` *before*
  opening Obsidian, then switch: [docs/OPERATIONS.md](docs/OPERATIONS.md#obsidian).
- **TX-02 font** (licensed, gitignored): copy its `.otf` files into `home/olivia/dotfiles/fonts/TX-02/`.
  WezTerm and Obsidian use it.
- **Fedora theme artwork** (gitignored): with the Fedora drive plugged in, run the copy commands in
  [home/olivia/themes/README.md](home/olivia/themes/README.md), then log out and back in.
- **Push from NixOS:** `gh auth login` once, then `git push` works over HTTPS.
- **PrivadoVPN:** no Linux app — download its WireGuard/OpenVPN configs and import them in
  System Settings → Wi-Fi & Networking.

## Day-to-day

```sh
nh os switch          # rebuild + activate (alias for nixos-rebuild switch --flake ~/nixos-config)
nh os switch --update # update flake inputs, then rebuild
nh clean all          # GC old generations (also runs automatically)
nix flake check       # evaluate the whole system + lint (~15 s; CI runs it too)
nix fmt               # format the .nix files
```

Edit `home/olivia/apps.nix` to add/remove apps. Search packages at https://search.nixos.org.
nvim / wezterm / fastfetch configs are live symlinks into this repo — edit them in place, no rebuild needed.
Keyboard shortcuts, VPN toggles and theme notes: [docs/OPERATIONS.md](docs/OPERATIONS.md).

## macOS

`macbook-olivia` is nix-darwin + home-manager for the user `olivi`, with Homebrew for GUI apps.
Details and the migration log: [docs/MACOS.md](docs/MACOS.md).

### Rebuild

```sh
cd ~/nixos-config
sudo darwin-rebuild switch --flake .#macbook-olivia   # activation runs as root
nix flake check                                      # evaluate the Mac config + lint, no root
nix build .#darwinConfigurations.macbook-olivia.system   # build without activating
```

A switch applies the system, home-manager, the declared Homebrew apps and the macOS defaults. It
installs missing casks and brews but never upgrades or removes them; `brew upgrade` is manual.
Settings declared in `modules/darwin/defaults.nix` that are changed in System Settings are put back
on the next switch.

### Update flake inputs

Update one named input at a time, then build and compare before switching:

```sh
nix flake update nixpkgs-darwin     # Mac packages only; also nix-darwin, nixpkgs-unstable, home-manager
nix build .#darwinConfigurations.macbook-olivia.system
nix run nixpkgs#nvd -- diff /run/current-system ./result
sudo darwin-rebuild switch --flake .#macbook-olivia
```

`home-manager` and `nixpkgs-unstable` are shared with the desktop: updating them changes both
machines, so the desktop needs a `nh os switch` too.

### Add a package

| What | Where |
|---|---|
| CLI tool on both machines | `home/shared/cli.nix` (check the desktop too, see CLAUDE.md) |
| CLI tool on the Mac only | `home/darwin/cli.nix` (`pkgs.unstable.<name>` if stable is too old) |
| GUI app | a cask in `modules/darwin/homebrew.nix` (`brew search --cask <name>`) |
| App Store app | `masApps` in `modules/darwin/homebrew.nix` (ID from `mas list` or `mas search`) |
| macOS setting | `modules/darwin/defaults.nix` |

Then `nix fmt`, `nix flake check`, and switch. New files need `git add` first, because flakes
ignore untracked files. Search for packages at https://search.nixos.org (choose the 26.05 channel).

### Roll back

```sh
sudo darwin-rebuild --list-generations
sudo darwin-rebuild --rollback                       # back one generation (system + home-manager)
sudo darwin-rebuild switch --switch-generation 7     # or to a specific one
```

Or `git revert` the commit and switch. A rollback doesn't undo Homebrew installs or macOS
`defaults`; restore those from `defaults import` or by hand. To remove nix-darwin completely, run
`sudo darwin-uninstaller` (it restores the `*.before-nix-darwin` files), and only then
`/nix/nix-installer uninstall`.

### Bootstrap a fresh Mac

The config expects the macOS account `olivi`, an Apple Silicon Mac, and the checkout at
`~/nixos-config`.

1. Sign in to the Apple ID and the App Store, then run `xcode-select --install` (git, and clang for
   LazyVim's treesitter).
2. Install Homebrew from https://brew.sh. nix-darwin declares its contents but doesn't install it.
3. Install Nix:
   ```sh
   curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
   ```
   Open a new terminal afterwards.
4. Clone the repo:
   ```sh
   git clone https://github.com/itripley/nixos-config.git ~/nixos-config
   ```
5. First switch. `darwin-rebuild` isn't installed yet, so build it from the flake:
   ```sh
   cd ~/nixos-config
   nix build .#darwinConfigurations.macbook-olivia.system
   sudo ./result/sw/bin/darwin-rebuild switch --flake .#macbook-olivia
   ```
   - If it stops with "Unexpected files in /etc", look at the files it lists. Rename each one to
     `<name>.before-nix-darwin` and run the switch again.
   - home-manager moves the dotfiles it replaces to `*.hm-backup`. If a `~/.gitconfig` exists,
     rename it, because it would override the managed `~/.config/git/config`.
   - The switch also installs every cask and App Store app, so the first run takes a while.
6. Restore by hand what isn't in the repo (full list in [MACOS.md](docs/MACOS.md#stays-manual)):
   - SSH keys into `~/.ssh` (`id_ed25519`, `id_unraid`, `id_ed25519_artlivia`), then run
     `gh auth login`.
   - TX-02 and the other personal fonts into `~/Library/Fonts`, and the WezTerm backdrops into
     `home/olivia/dotfiles/wezterm/backdrops/`.
   - App licences, VPN logins and privacy permissions (Accessibility, Screen Recording).
7. From then on, `sudo darwin-rebuild switch --flake ~/nixos-config#macbook-olivia`. Once the
   hostname is set, the `#macbook-olivia` part is optional.

# nixos-config — desktop-olivia

NixOS 26.05 flake for DESKTOP-OLIVIA, dual-booting with the existing Windows 11 install.
Generated from an inventory of the Windows machine (hardware, apps, dotfiles, network setup).

| | |
|---|---|
| CPU / GPU | Ryzen 7 7700X / Radeon RX 7800 XT (amdgpu + ROCm, LACT) |
| Desktop | KDE Plasma 6 (Wayland), Breeze Dark, pt + us layouts |
| NixOS disk | Samsung 850 EVO 500GB — btrfs, own ESP, systemd-boot |
| Windows disk | Fanxiang S770 1TB — untouched, mounted read-only at `/mnt/windows` |
| Unraid | `//192.168.1.65/{appdata,downloads,files}` → `/mnt/unraid/*` (automount) |

```
flake.nix                      inputs + nixosConfigurations.desktop-olivia
hosts/desktop-olivia/          configuration.nix, disko.nix, hardware-configuration.nix (placeholder)
modules/nixos/                 boot, amd, desktop, audio, networking, storage, gaming, services
home/olivia/                   home-manager: apps, dev (git/ssh/nvim/vscode), firefox, plasma, flatpak
home/olivia/dotfiles/          wezterm, nvim (LazyVim), fastfetch, firefox userChrome — copied from Windows
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
| [docs/VERIFICATION.md](docs/VERIFICATION.md) | how it was checked, what was fixed, what's untested |
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | day-to-day use and troubleshooting |

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
5. Flash the **NixOS 26.05 graphical ISO** to a USB stick (Rufus/Etcher). Not the Philips portable SSD.

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

# 3. Real hardware config (replaces the placeholder)
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/desktop-olivia/
git add -A

# 4. SMB credentials for the Unraid shares (not stored in the repo)
sudo install -m 600 /dev/null /mnt/etc/nixos/smb-secrets
printf 'username=YOUR_USER\npassword=YOUR_PASS\n' | sudo tee /mnt/etc/nixos/smb-secrets >/dev/null

# 5. Install
sudo nixos-install --flake .#desktop-olivia
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
- **Services that need a login:** `netbird up`, `warp-cli registration new && warp-cli connect`, Steam, Heroic,
  Bitwarden, Signal (re-link), VS Code Settings Sync (brings back the remaining extensions).
- **PrivadoVPN:** no Linux app — download its WireGuard/OpenVPN configs and import them in
  System Settings → Wi-Fi & Networking.

## Day-to-day

```sh
nh os switch          # rebuild + activate (alias for nixos-rebuild switch --flake ~/nixos-config)
nh os switch --update # update flake inputs, then rebuild
nh clean all          # GC old generations (also runs automatically)
```

Edit `home/olivia/apps.nix` to add/remove apps. Search packages at https://search.nixos.org.
nvim / wezterm / fastfetch configs are live symlinks into this repo — edit them in place, no rebuild needed.

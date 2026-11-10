# nix-config

One Nix flake for all of Olivia's machines: NixOS 26.05 on the desktop, nix-darwin 26.05 on the
MacBook, NixOS-WSL on Windows, and standalone home-manager anywhere else. Every machine shares the
same CLI tools, shell, git/ssh and Neovim setup and live-linked dotfiles. Every Linux machine also
shares the same apps. A new machine of any kind is set up with one command
([Set up a new machine](#set-up-a-new-machine)).

The repo started from an inventory of the Windows PC (hardware, apps, dotfiles, network). The full
reasoning is in [docs/](#documentation).

## Machines

| Machine | What it is | Config |
|---|---|---|
| `desktop-olivia` | The PC: KDE Plasma 6 on Wayland, dual-booting with Windows 11 on its own disk | `nixosConfigurations.desktop-olivia`, `hosts/desktop-olivia/` |
| `macbook-olivia` | MacBook M1, user `olivi`: nix-darwin + home-manager, Homebrew for the GUI apps | `darwinConfigurations.macbook-olivia`, `hosts/macbook-olivia/` |
| `wsl` | NixOS inside WSL, for any Windows PC: CLI tools, dotfiles, the Linux apps through WSLg | `nixosConfigurations.wsl`, `hosts/wsl/` |
| standalone | Any other Linux distro, a WSL distro, or a Mac that can't be taken over: home-manager only | `homeConfigurations."<user>@<system>"` |
| new machines | Another PC or Mac, added by `scripts/bootstrap.sh` | `hosts/<name>/` |

Every folder in `hosts/` is a machine, and `flake.nix` picks it up on its own:
`darwin-configuration.nix` makes it a Mac, `configuration.nix` makes it NixOS. The standalone
outputs exist for the users `olivia` and `olivi` on `x86_64-linux` (with the GUI apps),
`aarch64-linux` and `aarch64-darwin`.

### The desktop's hardware

| | |
|---|---|
| CPU / GPU | Ryzen 7 7700X / Radeon RX 7800 XT (amdgpu + ROCm, LACT) |
| Desktop | KDE Plasma 6 (Wayland), Catppuccin Macchiato + Klassy, Krohnkite tiling, SilentSDDM login, pt + us layouts (Alt+Shift) |
| NixOS disk | Samsung 850 EVO 500GB: btrfs, its own ESP, systemd-boot |
| Windows disk | Fanxiang S770 1TB: never touched, mounted read-only at `/mnt/windows` |
| Unraid | `//192.168.1.65/{appdata,downloads,files}` → `/mnt/unraid/*` (automount) |

## Set up a new machine

Push any local work first, because the script clones the repo from GitHub. Then run this on the new
machine:

```sh
# A PC booted from a NixOS USB installer, a PC already running NixOS, a Mac, or any other Linux
bash <(curl -fsSL https://raw.githubusercontent.com/itripley/nix-config/main/scripts/bootstrap.sh)
```

```powershell
# Windows, in PowerShell: WSL + NixOS-WSL, then the same script inside it
irm https://raw.githubusercontent.com/itripley/nix-config/main/scripts/bootstrap.ps1 | iex
```

| Where it runs | What it does |
|---|---|
| NixOS USB installer (x86_64, UEFI) | Asks for a name. A new one gets `hosts/<name>/`: its hardware config, `amd.nix` or `nvidia.nix` for its GPU, and the disk you pick. You type the disk's name to confirm the wipe, and then it installs the full desktop. A name already in `hosts/` (e.g. `desktop-olivia`) is reinstalled with its own settings. |
| A PC already running NixOS | Switches to its host, or adopts it as a new `hosts/<name>/`, keeping its disks |
| Windows | Installs WSL if needed (admin prompt and a reboot, then run it again), then the NixOS distro and `hosts/wsl` with olivia as the default user |
| Apple Silicon Mac | Switches to its host, or writes a new one (Homebrew, App Store apps, macOS settings), or sets up home-manager only |
| Any other Linux | Installs Nix if needed, then standalone home-manager |

It evaluates the whole configuration before it touches anything, and it never commits. Commit and
push the new `hosts/<name>/` from that machine afterwards, then do the hand steps in
[After setting up](#after-setting-up). Details and limits:
[docs/OPERATIONS.md](docs/OPERATIONS.md#setting-up-a-new-machine). The steps without the script
are in [Manual install](#manual-install).

Not covered: BIOS-only PCs, non-x86_64 NixOS PCs, Intel Macs (nixpkgs 26.05 is their last release),
and native Windows apps (Nix doesn't run on Windows).

## Everyday use

### Switch

| Machine | Command |
|---|---|
| NixOS (the desktop, WSL, a new PC) | `nh os switch`. Use `nh os boot`, then reboot, for kernel, driver or boot changes. |
| Mac | `sudo darwin-rebuild switch --flake ~/nix-config` (activation runs as root) |
| Standalone | `home-manager switch --flake ~/nix-config#<user>@<system>`, e.g. `#olivia@x86_64-linux` |

NixOS and nix-darwin pick the host from the hostname. On a Mac, a switch also installs any declared
cask, brew or App Store app that's missing, but it never upgrades or removes one (`brew upgrade` is
manual). macOS settings declared in `modules/darwin/defaults.nix` and Plasma settings declared in
`home/olivia/plasma.nix` are put back on the next switch if they're changed in the GUI.

The `nvim`, `wezterm` and `fastfetch` configs are live links into `home/olivia/dotfiles/` on every
machine. Edit them in place; no switch is needed. The checkout therefore has to stay at
`~/nix-config`.

### Check a change

```sh
nix fmt                 # nixfmt over every .nix file except the generated hardware configs
nix flake check         # evaluates every machine and home for this system, plus statix, deadnix, nixfmt
                        # (~26 s on the desktop, ~40 s on the Mac; CI runs it on Linux and macOS)
nix develop             # nixfmt-tree, statix, deadnix, nvd, nil

# What a switch would change, without activating anything
nvd diff /run/current-system "$(nix build --no-link --print-out-paths .#nixosConfigurations.desktop-olivia.config.system.build.toplevel)"
nix build .#darwinConfigurations.macbook-olivia.system && nix run nixpkgs#nvd -- diff /run/current-system ./result
```

`git add` new files before any of these: flakes ignore untracked files. `nh os switch` shows the
same diff before it activates. From Windows without Nix, `pwsh -File scripts\verify.ps1` evaluates
the desktop in Docker on the Unraid server.

### Where things go

| Change | File |
|---|---|
| App on every Linux machine (desktop, WSL, other distros) | `home/olivia/apps.nix`; dev tools in `home/olivia/dev.nix` |
| CLI tool on every machine | `home/shared/cli.nix` |
| CLI tool on Macs only | `home/darwin/cli.nix` |
| Mac GUI app / App Store app | a cask / `masApps` in `modules/darwin/homebrew.nix` (`brew search --cask`, `mas search`) |
| macOS setting | `modules/darwin/defaults.nix` |
| Plasma settings, shortcuts, theme | `home/olivia/plasma.nix` |
| Flatpak | `home/olivia/flatpak.nix` (Flathub ID) |
| System service, boot, network, mounts on every PC | the matching `modules/nixos/*.nix` |
| Something only one machine has | its `hosts/<name>/` (the desktop: `machine.nix` for the Windows disk, RTC and RGB) |
| Every NixOS machine (user, Nix settings, nh) / every Mac | `modules/nixos/common.nix` / `modules/darwin/common.nix` |
| A newer version than stable has | `pkgs.unstable.<name>` |
| Package written for this repo | `pkgs/<name>/package.nix`, a line in `overlays/packages.nix`, and `packages` in `flake.nix` |
| Upstream build failure | `overlays/build-fixes.nix`, rather than dropping the app |
| Another username for standalone home-manager | `standaloneUsers` in `flake.nix` |

Find packages at https://search.nixos.org (the 26.05 channel). Keyboard shortcuts, VPN toggles,
theme upkeep and the rest of the how-tos are in [docs/OPERATIONS.md](docs/OPERATIONS.md).

### Update

Update one input at a time, then check and compare before switching:

```sh
nix flake update home-manager     # or nixpkgs, nixpkgs-darwin, serein, vicinae, …
```

Many inputs are shared: `nixpkgs` moves the desktop, WSL and the Linux homes, `nixpkgs-darwin`
moves the Macs, and `home-manager` and `nixpkgs-unstable` move every machine. Switch each machine
that's affected. For third-party flakes (Serein, Claude Desktop, ArtCraft, Vicinae, SilentSDDM,
NixOS-WSL), read their new commits first. `nh os switch --update` updates every input at once.

### Roll back

| Machine | How |
|---|---|
| NixOS | Pick an older generation in the boot menu, or `sudo nixos-rebuild switch --rollback` |
| Mac | `sudo darwin-rebuild --rollback`, or `sudo darwin-rebuild switch --switch-generation <n>` (list them with `sudo darwin-rebuild --list-generations`). Homebrew installs and macOS defaults aren't undone. |
| Standalone | `home-manager generations`, then run the `activate` script in the generation you want |

Or `git revert` the commit and switch. Old generations are cleaned up automatically on NixOS (nh
keeps the last 10 and anything from the last 14 days) and on Macs (every Sunday, older than 14
days). Standalone homes aren't
cleaned automatically: `home-manager expire-generations '-14 days'`, then `nix-collect-garbage`.
To remove nix-darwin from a Mac, run `sudo darwin-uninstaller` (it restores the
`*.before-nix-darwin` files), and only then `/nix/nix-installer uninstall`.

## Layout

```
flake.nix                      inputs; machines and homes built from hosts/; packages, formatter, checks, devShells
hosts/desktop-olivia/          configuration.nix (its modules), machine.nix (Windows disk, RTC, RGB),
                               disko.nix (the Samsung), hardware-configuration.nix (generated)
hosts/macbook-olivia/          darwin-configuration.nix: hostname, user
hosts/wsl/                     NixOS-WSL, for any Windows PC
modules/nixos/                 common (every NixOS machine), boot, desktop, audio, networking, storage, gaming,
                               services; amd / nvidia (GPU), login-art (gitignored art), disk-layout (new PCs)
modules/darwin/                common (every Mac), homebrew (casks, brews, App Store), defaults (Dock, Finder, …)
home/shared/                   every machine: CLI tools, fish, git/ssh, Neovim, the dotfile links
home/linux/                    every x86_64 Linux machine: the apps from home/olivia/ (apps, dev, Firefox,
                               Obsidian, mpv, EasyEffects) and the fonts link
home/olivia/                   the desktop user: home/linux plus Plasma, Flatpak, the WARP tray;
                               dotfiles/ (wezterm, nvim, fastfetch, userChrome; fonts/ gitignored),
                               themes/ (the Fedora theme; art/ gitignored)
home/darwin/                   a Mac user: home/shared plus zsh, Mac CLI tools, git additions
home/standalone.nix            standalone home-manager settings
overlays/                      build-fixes.nix (upstream build workarounds), packages.nix (adds pkgs/)
pkgs/                          packages written for this repo (warp-cloudflare-gui, obsidian-plugins, vscode-marketplace)
scripts/                       bootstrap.sh / bootstrap.ps1 (new machines), verify.ps1 (evaluate from Windows),
                               migrate-firefox-profile.sh (Windows Firefox profile → NixOS)
docs/                          what, how and why
.github/workflows/check.yml    CI: nix flake check on Linux and macOS
```

## Manual install

What `bootstrap.sh` does, step by step, for when the script can't be used.

### Reinstall the desktop from the USB

Before starting, in Windows:

1. **Reinstalling erases the Samsung 850 EVO**, which is the NixOS disk, `/home` included. Back up
   what isn't in the repo or on the Unraid server first.
2. **Fast Startup stays off** (Control Panel → Power Options → "Choose what the power buttons do",
   or `powercfg /h off` in an admin shell). Otherwise Windows leaves C: locked and Linux can't
   mount it.
3. **Push any changes**, since the installer clones from GitHub. `pwsh -File scripts\verify.ps1`
   checks that the config evaluates.
4. **Installer:** the Philips portable SSD has the NixOS graphical ISO on it. Any recent NixOS ISO
   works, because `nixos-install --flake` uses the nixpkgs pinned in `flake.lock`. The SSD can stay
   plugged in: disko only targets the Samsung, by serial.

Boot the USB from the ASUS boot menu (**F8**), connect to the network and open a terminal:

```sh
git clone https://github.com/itripley/nix-config ~/nix-config && cd ~/nix-config
# (if git is missing on the ISO: nix-shell -p git, then run the line above)

# 0. Make sure the config evaluates BEFORE touching any disk (prints a /nix/store/...drv path)
nix --experimental-features "nix-command flakes" eval --raw \
  .#nixosConfigurations.desktop-olivia.config.system.build.toplevel.drvPath

# 1. CHECK the disk id. It must be the 500GB Samsung; if the name differs, fix disko.nix first.
ls -l /dev/disk/by-id/ | grep Samsung

# 2. Partition + format + mount the Samsung disk (destructive, Samsung only)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount hosts/desktop-olivia/disko.nix

# 3. Hardware config for this machine (overwrites the committed one; normally identical)
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/desktop-olivia/
# The stock config isn't used; left there, a plain `nixos-rebuild` without --flake would build it
sudo rm /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/hardware-configuration.nix
git add -A

# 4. SMB credentials for the Unraid shares (not stored in the repo)
sudo install -m 600 /dev/null /mnt/etc/nixos/smb-secrets
printf 'username=YOUR_USER\npassword=YOUR_PASS\n' | sudo tee /mnt/etc/nixos/smb-secrets >/dev/null

# 5. Login-screen art (gitignored; login-art.nix needs it or the build fails). Copy rei2.png and
#    avatar.png into home/olivia/themes/art/sddm/ first (home/olivia/themes/README.md), or comment
#    out login-art.nix in hosts/desktop-olivia/configuration.nix
nix --experimental-features "nix-command flakes" store add-file home/olivia/themes/art/sddm/rei2.png
nix --experimental-features "nix-command flakes" store add-file home/olivia/themes/art/sddm/avatar.png

# 6. Install (--no-channel-copy: the flake pins nixpkgs, so the ISO's channel isn't copied).
#    It asks for a root password at the end; emergency mode uses it.
sudo nixos-install --flake .#desktop-olivia --no-channel-copy
sudo nixos-enter --root /mnt -c 'passwd olivia'

# 7. Keep the repo where the config expects it (dotfile links and nh point here)
sudo cp -r ~/nix-config /mnt/home/olivia/ && sudo nixos-enter --root /mnt -c 'chown -R olivia:users /home/olivia/nix-config'
reboot
```

For a **different PC**, write its `hosts/<name>/` first: copy `hosts/desktop-olivia/configuration.nix`,
swap `./disko.nix` for `../../modules/nixos/disk-layout.nix` plus a
`disko.devices.disk.main.device = "/dev/disk/by-id/…"` line, and drop `amd.nix`, `login-art.nix`
and `./machine.nix` as needed. In step 2, run disko with `--flake .#<name>` instead of the file.
See [docs/OPERATIONS.md](docs/OPERATIONS.md#setting-up-a-new-machine).

### A Mac

This is for the MacBook's own config (account `olivi`, Apple Silicon, the checkout at
`~/nix-config`). Another Mac needs its own `hosts/<name>/darwin-configuration.nix`, which the
script writes.

1. Sign in to the Apple ID and the App Store, then run `xcode-select --install` (git, plus clang for
   LazyVim's treesitter).
2. Install Homebrew from https://brew.sh. nix-darwin declares what's in it but doesn't install it.
3. Install Nix, then open a new terminal:
   ```sh
   curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
   ```
4. Clone the repo:
   ```sh
   git clone https://github.com/itripley/nix-config.git ~/nix-config
   ```
5. First switch. `darwin-rebuild` isn't installed yet, so build it from the flake:
   ```sh
   cd ~/nix-config
   nix build .#darwinConfigurations.macbook-olivia.system
   sudo ./result/sw/bin/darwin-rebuild switch --flake .#macbook-olivia
   ```
   - If it stops with "Unexpected files in /etc", look at the files it lists. Rename each one to
     `<name>.before-nix-darwin` and run the switch again.
   - home-manager moves the dotfiles it replaces to `*.hm-backup`. Rename any `~/.gitconfig`,
     because it would override the managed `~/.config/git/config`.
   - The switch also installs every cask and App Store app, so the first run takes a while.

### Another Linux distro

```sh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes   # then open a new terminal
git clone https://github.com/itripley/nix-config.git ~/nix-config && cd ~/nix-config
nix run --inputs-from . home-manager -- switch --flake .#"$USER@$(nix config show system)" -b hm-backup
sudo "$(command -v non-nixos-gpu-setup)"   # x86_64, once, in a new terminal: GPU drivers for the GUI apps
```

The username has to be in `standaloneUsers` in `flake.nix`. To make fish the login shell, add its
path to `/etc/shells` and run `chsh -s "$(command -v fish)"`.

### Windows (NixOS-WSL)

In PowerShell:

```powershell
wsl --install --no-distribution        # once, as administrator; then reboot
# nixos.wsl from https://github.com/nix-community/NixOS-WSL/releases/latest
wsl --install --from-file nixos.wsl --name NixOS --no-launch
wsl -d NixOS
```

Inside NixOS, still as its default user `nixos`:

```sh
nix --extra-experimental-features "nix-command flakes" run nixpkgs#git -- \
  clone https://github.com/itripley/nix-config ~/nix-config && cd ~/nix-config
sudo nixos-rebuild boot --flake .#wsl   # boot, not switch: the default user changes to olivia
sudo install -d -o "$(id -u)" -g users -m 700 /home/olivia && cp -a ~/nix-config /home/olivia/
exit
```

Then in PowerShell, so that olivia becomes the default user (NixOS-WSL's documented steps):
`wsl -t NixOS; wsl -d NixOS --user root exit; wsl -t NixOS`.

## After setting up

### On any machine

- **Commit and push** the new `hosts/<name>/` from it. Run `gh auth login` once, then `git push`
  works over HTTPS.
- **SSH keys** into `~/.ssh` (`id_ed25519`, `id_unraid`, `id_ed25519_artlivia`). The hosts
  `github-artlivia` and `unraid` are already configured.
- **TX-02 font** (licensed, gitignored): the `.otf` files into `home/olivia/dotfiles/fonts/TX-02/`
  on Linux, or `~/Library/Fonts` on a Mac. WezTerm and Obsidian use it.
- **WezTerm wallpapers** (gitignored) into `home/olivia/dotfiles/wezterm/backdrops/`.

### On a new PC

- **Unraid shares:** `/etc/nixos/smb-secrets` (`username=…`, `password=…`, mode 600), if the
  script's prompt was skipped.
- **Login-screen art:** copy `home/olivia/themes/art/sddm/` in, uncomment `login-art.nix` in its
  `configuration.nix`, `nix store add-file` both files, and switch.
- **Dual boot with Windows:** add `time.hardwareClockInLocalTime = true;` to its host folder.
- The rest of the desktop list below applies too, apart from the Windows-specific steps.

### On the desktop

- **Boot order:** the installer makes NixOS (systemd-boot) the default. Pick Windows from **F8** at
  power-on. A Windows entry in the systemd-boot menu would need `boot.loader.systemd-boot.windows`
  with the EFI shell handle of the Windows ESP.
- **SSH keys** from Windows: `mkdir -m700 ~/.ssh && cp /mnt/windows/Users/olivi/.ssh/id_* ~/.ssh/ && chmod 600 ~/.ssh/id_*`
- **Firefox profile:** close Firefox (on Windows too, before rebooting), then run
  `~/nix-config/scripts/migrate-firefox-profile.sh`. It copies the whole Windows profile from
  `/mnt/windows` into `~/.config/mozilla/firefox/9ylnf32e.default-release`: add-ons with their
  settings and data (Sidebery panels, uBlock filters, ScriptCat scripts…), themes, logins,
  cookies, history and open tabs. It refuses if Windows' Firefox is newer than NixOS'; update
  `nixpkgs` and switch first in that case. See [docs/FIREFOX.md](docs/FIREFOX.md).
- **WezTerm wallpapers** from Windows: `cp /mnt/windows/Users/olivi/.config/wezterm/backdrops/* ~/nix-config/home/olivia/dotfiles/wezterm/backdrops/`
- **Fedora theme artwork** (gitignored): with the Fedora drive plugged in, run the copy commands in
  [home/olivia/themes/README.md](home/olivia/themes/README.md), then log out and back in.
- **Monitor:** System Settings → Display → 2560×1440 @ 165 Hz and Adaptive Sync "Automatic", if
  they weren't picked.
- **NetBird** (self-hosted, `networking.nix`): `netbird up` (add `--setup-key <key>` if SSO isn't
  set up), then **turn off the server's exit node**, or the internet stops working while connected:
  `netbird networks deselect "Exit Node (unraid)" "Exit Node (unraid)-v6"`. Check with
  `netbird status` and `netbird networks list`.
- **WARP:** `warp-cli registration new`, then `warp-cli connect` / `disconnect`, or the *Cloudflare
  Warp* tray icon (`home/olivia/warp-gui.nix`; Cloudflare's own tray app is Zero Trust only). Don't
  run it at the same time as NetBird.
- **Obsidian:** copy the LiveSync and Paperless settings into `~/.config/obsidian-seed/` *before*
  opening Obsidian, then switch: [docs/OPERATIONS.md](docs/OPERATIONS.md#obsidian).
- **plex-mpv-shim:** run it once, then set `"allow_http": true` in
  `~/.config/plex-mpv-shim/conf.json` (Plex desktop casts use plain HTTP).
- **Logins:** Steam, Heroic, Bitwarden, Claude Desktop, VS Code Settings Sync (settings only; the
  extensions are declared in `dev.nix`).
- **PrivadoVPN:** there's no Linux app. Download its WireGuard/OpenVPN configs and import them in
  System Settings → Wi-Fi & Networking.

### On a Mac

- **Fonts:** TX-02 and the other personal fonts into `~/Library/Fonts`.
- **App licences, VPN logins and privacy permissions** (Accessibility, Screen Recording).
- The full list of what stays manual is in [docs/MACOS.md](docs/MACOS.md#stays-manual).

## Documentation

| | |
|---|---|
| [docs/README.md](docs/README.md) | index, current status and history |
| [docs/DESIGN.md](docs/DESIGN.md) | why: dual boot, disk layout, boot, flake inputs, home-manager, the Mac (§11), any machine (§12) |
| [docs/MODULES.md](docs/MODULES.md) | every file and setting, what it does and why |
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | how-tos: new machines, two-machine workflow, shortcuts, VPN toggles, theme, troubleshooting |
| [docs/VERIFICATION.md](docs/VERIFICATION.md) | how each change was checked, what broke and was fixed, what's still to check by hand |
| [docs/MACOS.md](docs/MACOS.md) | the MacBook: inventory, migration log, what was checked, what stays manual |
| [docs/INVENTORY.md](docs/INVENTORY.md) | what was found on the Windows PC: the evidence behind the desktop's choices |
| [docs/MIGRATION.md](docs/MIGRATION.md) | every Windows app and where it went |
| [docs/FEDORA.md](docs/FEDORA.md) | what came over from the old Fedora install, and the conflicts |
| [docs/FIREFOX.md](docs/FIREFOX.md) | the Firefox profile migration |

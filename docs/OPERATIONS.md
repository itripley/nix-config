# Operations: day-to-day use and troubleshooting

## The basic loop

```sh
cd ~/nix-config
$EDITOR home/olivia/apps.nix     # change something
nh os switch                     # build + activate (asks for sudo)
git add -A && git commit -m "…"  # record it
```

- `nh os switch` = `nixos-rebuild switch --flake ~/nix-config#desktop-olivia`, with a readable diff
  of what changed. `nh os boot` applies at next boot instead (safer for kernel/driver changes).
- **New files must be `git add`ed** before rebuilding, or the flake won't see them.
- `nix flake check` (≈26 s) evaluates every Linux machine and home (the desktop, WSL, any added
  PCs, the standalone homes) and lints the repo; `nix fmt` formats it. CI runs the same check on
  every push, and on macOS for the Macs.
- From Windows, check edits before rebooting into NixOS: `pwsh -File scripts\verify.ps1`.
- **The MacBook** has its own loop: `sudo darwin-rebuild switch --flake ~/nix-config#macbook-olivia`.
  Its commands are in the README's [Everyday use](../README.md#everyday-use), and its troubleshooting
  [below](#macbook). A change in `home/shared/` affects both machines, so switch both.

## Working from two machines

The desktop and the Mac share one repo, and `home/shared/` plus the live-linked dotfiles are used by
both, so work done on one has to reach the other through GitHub:

- **Before editing:** `git pull` (or at least `git status`, to spot work left uncommitted there).
- **After a change works:** commit and push, so the other machine's next pull is a fast-forward.
- **Switch both** after a change in `home/shared/`, `flake.nix` or `flake.lock`. The Mac's
  `nix flake check` doesn't cover the desktop, and the desktop's doesn't cover the Mac; CI runs
  both on every push.
- **`lazy-lock.json` is shared.** LazyVim on either machine rewrites
  `home/olivia/dotfiles/nvim/lazy-lock.json` after plugin updates. Commit it like any other change;
  the other machine picks up the same plugin versions on its next start.
- **If a pull refuses** ("Your local changes … would be overwritten by merge"), there's uncommitted
  work on that machine. Don't discard it. Commit it on a branch and push it, then merge it where the
  newer work is, and push `main`. This is what was done on 2026-11-10:
  ```sh
  git add -A && git switch -c desktop-wip && git commit -m "…" && git push -u origin desktop-wip
  git switch main      # the checkout goes back to the old main; the running system is untouched
  # on the other machine: git fetch && git merge origin/desktop-wip, resolve, check, push
  git pull             # now a fast-forward
  ```
  Before pushing a branch to this public repo, grep the staged diff for passwords, tokens and keys.

## Setting up a new machine

One script for every kind of machine (DESIGN §12, MODULES `scripts/bootstrap.sh`). Push any local
work first: the script clones from GitHub.

| The new machine | Run on it | Result |
|---|---|---|
| A PC, booted from a NixOS USB installer (UEFI) | `bash <(curl -fsSL https://raw.githubusercontent.com/itripley/nix-config/main/scripts/bootstrap.sh)` | A new `hosts/<name>/`, the chosen disk wiped and NixOS installed with the full desktop. A known name (`desktop-olivia`) is reinstalled as it is. |
| A PC that already runs NixOS | the same | Its hostname in `hosts/` → switched to it. Otherwise adopted as a new `hosts/<name>/`, keeping its disks. |
| Windows | `irm https://raw.githubusercontent.com/itripley/nix-config/main/scripts/bootstrap.ps1 \| iex` in PowerShell | WSL if missing (admin prompt, reboot, run again), the NixOS-WSL distro, then `hosts/wsl`: user olivia, CLI tools, dotfiles and the Linux apps through WSLg. |
| An Apple Silicon Mac | the `bash <(curl …)` line, in Terminal | Its `LocalHostName` in `hosts/` → switched to it. Otherwise: a new nix-darwin host (`hosts/<name>/`, with Homebrew and the App Store apps) or home-manager only. Sign in to the App Store first. |
| Any other Linux (Fedora, Ubuntu, a WSL distro…), or a Mac that can't be taken over | the `bash <(curl …)` line | Nix if missing, then standalone home-manager: CLI tools, fish, git/ssh, Neovim, the dotfiles, and on x86_64 the GUI apps. |

Afterwards:
- **Commit and push the new `hosts/<name>/`** from the new machine (`gh auth login` first). The
  script stages it but never commits.
- **The hand steps** still apply: SSH keys, the TX-02 font, the gitignored art, logins (the
  README's [After setting up](../README.md#after-setting-up)).
- **Login-screen art on a new PC:** copy `themes/art/sddm/` in, uncomment `login-art.nix` in the
  host's `configuration.nix`, `nix store add-file` both files, then switch.
- **GUI apps on another distro** need one `sudo non-nixos-gpu-setup`, which the script offers.
  NVIDIA's proprietary driver there needs `targets.genericLinux.gpu.nvidia` with the exact driver
  version and hash; not set up.
- **A new username** for standalone home-manager: add it to `standaloneUsers` in `flake.nix`,
  `git add`, run the script again. The outputs are `homeConfigurations."<user>@<system>"`; later
  switches are `home-manager switch --flake ~/nix-config#<user>@<system>`.
- **Later switches** are the usual ones: `nh os switch` on NixOS (WSL included), `sudo
  darwin-rebuild switch --flake ~/nix-config` on a Mac, `home-manager switch …` elsewhere.

Without the script, the manual steps are the README's [Manual install](../README.md#manual-install)
(the desktop from the USB, a Mac, another distro, Windows). For a new PC, also write
`hosts/<name>/configuration.nix` by hand (copy `hosts/desktop-olivia/configuration.nix`, swap
`./disko.nix` for `../../modules/nixos/disk-layout.nix` plus `disko.devices.disk.main.device`,
drop `amd.nix`, `login-art.nix` and `./machine.nix` as needed).

## Common tasks

| Task | How |
|---|---|
| Add/remove an app | Edit `home/olivia/apps.nix` (user apps; through `home/linux` it reaches every Linux machine: the desktop, WSL, other distros) or a `modules/nixos/*.nix` file (system services). A CLI tool for every machine goes in `home/shared/cli.nix`. Find names at https://search.nixos.org. |
| Try an app without installing | `nix shell nixpkgs#<name>` (gone when the shell closes). |
| Add a Flatpak | Add its Flathub ID to `home/olivia/flatpak.nix`. |
| Run an AppImage | `chmod +x Foo.AppImage && ./Foo.AppImage` (binfmt handles it). |
| Update everything | `nh os switch --update` (updates `flake.lock`, then rebuilds). Commit the new lock. |
| Update one input | `nix flake update home-manager`, then `nh os switch`. `home-manager` and `nixpkgs-unstable` are shared with the Mac, so switch it too. |
| Update Claude Desktop / ArtCraft / Serein / Vicinae | `nix flake update claude-desktop` (or `artcraft`, `serein`, `vicinae`), then `nh os switch`. Third-party flakes: glance at the input's commits first (DESIGN §8). |
| Add another ArtCraft app | Add it to `programs.artcraft.apps` in `modules/nixos/desktop.nix`: `vectorcraft`, `designcraft`, `lightcraft`, `effectcraft`, `pdfcraft`. |
| Pin an ArtCraft version | Use `<app>_<x>_<y>_<z>` in that list, e.g. `"photocraft_0_20_1"`; plain `<app>` is the newest in the lock. |
| Roll back | Pick an older generation in the boot menu, or `sudo nixos-rebuild switch --rollback`. |
| Try a risky change in a VM | `nixos-rebuild build-vm --flake .#desktop-olivia`, then `./result/bin/run-desktop-olivia-vm`. Its disk is `./desktop-olivia.qcow2` (gitignored; delete it for a fresh VM). No artwork or secrets inside. With the real btrfs layout: `nix build .#nixosConfigurations.desktop-olivia.config.system.build.vmWithDisko`, then `./result/bin/disko-vm` (disk in a temp dir). |
| See what an update changes | `nix build .#nixosConfigurations.desktop-olivia.config.system.build.toplevel` and `nvd diff /run/current-system result` (`nvd` is in `nix develop`). `nh os switch` shows the same diff before activating. |
| Format / lint | `nix fmt`; `nix flake check`. `nix develop` has nixfmt-tree, statix, deadnix, nvd and nil. |
| Build a repo package alone | `nix build .#warp-cloudflare-gui` (or `obsidian-plugins`, `vscode-marketplace`; the packages in `pkgs/`). |
| Add / update an Obsidian plugin | See [Obsidian](#obsidian). |
| Change the RGB colors | Edit the `openrgb` calls in `openrgb-colors` (`hosts/desktop-olivia/machine.nix`); colors set in the OpenRGB GUI only last until the next boot. |
| Set up a new machine | `scripts/bootstrap.sh` on it (Windows: `bootstrap.ps1`). See [Setting up a new machine](#setting-up-a-new-machine). |
| Add something to one machine only | Its own `hosts/<name>/` (the desktop: `machine.nix`). Something for every Linux machine goes in `home/linux` (or a module it imports); for every NixOS machine in `modules/nixos/common.nix`; for every Mac in `modules/darwin/common.nix`. |
| Change mpv / plex-mpv-shim settings | `programs.mpv` in `mpv.nix` / `home/olivia/plex-mpv-shim/mpv.conf`. |
| Add / update a VS Code extension | Add or change `{publisher, name, version, hash}` in `pkgs/vscode-marketplace/sources.json` (`"arch": "linux-x64"` if the marketplace lists per-platform builds). Get the hash by leaving it as `""`, running `nix build .#vscode-marketplace`, and copying the `got:` value. Extensions installed from inside VS Code still work but aren't kept on a fresh install. |
| Play Minecraft 1.16 or older | Add `jdk17` / `jdk8` to the Prism Launcher `jdks` list in `apps.nix`. |
| Free disk space | Automatic (`programs.nh.clean`: keeps 10 generations / 14 days). Manual: `nh clean all`. On the Mac: automatic every Sunday (`nix.gc`: generations older than 14 days, then `nix-store --optimise`); by hand, `sudo nix-collect-garbage --delete-older-than 14d`. |
| Add a font for yourself | Copy the `.otf`/`.ttf` files into `home/olivia/dotfiles/fonts/<Name>/` (gitignored, linked into `~/.local/share/fonts`). No rebuild; restart the app. After a fresh clone, TX-02 has to be copied back in by hand. Packaged fonts go in `fonts.packages` in `modules/nixos/desktop.nix` instead. |
| Edit nvim / WezTerm / fastfetch config | Edit under `home/olivia/dotfiles/…`; they're live links, so there's no rebuild. |
| Edit Firefox `userChrome.css` | Edit `home/olivia/dotfiles/firefox/userChrome.css`, then `nh os switch`, then restart Firefox. |
| Change time zone | `time.timeZone` in `modules/nixos/desktop.nix` (e.g. `"Europe/London"`). |
| Change SMB password | `sudo $EDITOR /etc/nixos/smb-secrets` (not in the repo). |
| Drop Sublime Text | Remove `sublime4` from `apps.nix`, the `permittedInsecurePackages` line in `flake.nix` (`nixpkgsConfig`) **and** the `openssl_1_1` fix in `overlays/build-fixes.nix`. |
| A package fails to build | Read the log (`nix log /nix/store/…drv`). Fix it in `overlays/build-fixes.nix` rather than commenting the app out; see that file for examples. To unblock a rebuild right away, comment the app out, then put it back once fixed. |
| Upgrade to the next NixOS release | Change `nixos-26.05` / `release-26.05` in `flake.nix`, `nh os switch --update`. **Don't** touch `stateVersion`. |

## Keyboard shortcuts

Set in `home/olivia/plasma.nix` (Krohnkite, launchers, window binds) and `modules/nixos/desktop.nix`
(layout switch). Everything else is KDE's default.

| Keys | Does | From |
|---|---|---|
| **Meta+Space** | Vicinae | Fedora (was Ulauncher) |
| **Meta+V** | Vicinae clipboard history (replaces Klipper's popup) | Vicinae's KDE guide |
| **Alt+Shift** | switch keyboard layout pt ↔ us | moved from Win+Space |
| Alt+Space | KRunner | KDE default |
| Meta+Return | WezTerm | Fedora |
| Meta+H / J / K | Krohnkite: focus left / down / up | Fedora |
| Meta+Shift+H / J / K / L | Krohnkite: move window left / down / up / right | Fedora |
| Meta+Ctrl+H / L | Krohnkite: shrink / grow width | Fedora |
| Meta+Ctrl+K / J | Krohnkite: shrink / grow height | Fedora |
| Meta+M | Krohnkite: monocle layout | Fedora |
| Meta+S / Meta+Shift+F | Krohnkite: float window / float all | Fedora |
| Meta+I | Krohnkite: increase master windows | Fedora |
| Meta+, / Meta+\\ / Meta+\| | Krohnkite: focus previous / next layout / previous layout | Krohnkite defaults |
| Meta+L | lock screen (so Krohnkite "focus right" is unbound) | KDE default |
| Meta+arrows | quick-tile | KDE default (restored) |
| Meta+Alt+arrows | focus window in that direction | KDE default (restored) |
| Alt+Q / Alt+M | close / minimize window | Windows (whkd) |

To change one, edit `plasma.nix` and `nh os switch`. A key changed in System Settings works too, but
the next switch puts the configured value back.

## VPNs: NetBird and WARP

- **Tray toggles:** both tray apps start at login (check under the tray's ^ arrow; right-click the
  tray → *Configure System Tray* → *Always shown*). NetBird: *Connect* / *Disconnect*, and the
  networks menu. WARP: the *Cloudflare Warp* icon (`home/olivia/warp-gui.nix`); right-click →
  *Connect / Disconnect*, or *Hide / Show* for the window with the switch. Cloudflare's own
  `warp-taskbar` is disabled: it's Zero Trust only and has no switch for the free account.
- **Use one at a time.** Both change routing and DNS.
- **NetBird is self-hosted** at `https://netbird.weblivia.dev` (set in `networking.nix`). CLI:
  `netbird up`, `netbird down`, `netbird status`, `netbird networks list`.
- **Exit node:** the server offers *Exit Node (unraid)*. It's deselected on this machine (else all
  traffic goes through the Unraid peer). To use it on purpose: `netbird networks select "Exit Node (unraid)"`;
  undo with `deselect`. On a fresh install, deselect it again (see the README).
- **WARP:** `warp-cli status`, `warp-cli connect` / `disconnect`. Registered with a free account
  (no sign-in exists for it; the sign-in screen in Cloudflare's tray app is for Zero Trust teams).

## Theme (from the Fedora install)

- Files are in `home/olivia/themes/`; see its README. Artwork (`themes/art/`) is **not in git**:
  after a fresh clone, copy it from the Fedora drive with the commands in `themes/README.md`.
  The same goes for the TX-02 font in `home/olivia/dotfiles/fonts/`.
- Changing the wallpaper, colors or cursor in System Settings works until the next `nh os switch`,
  which re-applies `plasma.nix`. Make lasting changes in `plasma.nix`.
- Wallpapers are per screen: the first entry in `workspace.wallpaper` is screen 0 (DP-1).
- The login screen (SilentSDDM) is `programs.silentSDDM` in `desktop.nix`; options are in
  [its wiki](https://github.com/uiriansan/SilentSDDM/wiki/Options). Preview a change without logging
  out: `test-sddm-silent`. SDDM itself only picks up changes after a reboot.

## Obsidian

The vault is `~/Documents/obsidian/weblivia`; `home/olivia/obsidian.nix` installs its plugins, themes
and settings, and LiveSync pulls the notes (MODULES `obsidian.nix`).

**First time (once, before opening Obsidian):** copy the two settings files that hold secrets from
the Windows vault into the private seed folder, then switch:

```sh
w=/mnt/windows/Users/olivi/Desktop/olivia/obsidian/weblivia/.obsidian/plugins
for p in obsidian-livesync paperless; do
  install -D -m600 "$w/$p/data.json" ~/.config/obsidian-seed/plugins/$p/data.json
done
nh os switch
```

Then open Obsidian, pick **weblivia** in the vault list, and choose *Trust author and enable
plugins*. LiveSync connects with the Windows settings and pulls the notes into the empty vault. If
it doesn't start on its own (or asks), use LiveSync's *Fetch from remote* (in its settings,
*Maintenance → Rebuild*): it rebuilds the local database **from** the server. Don't pick anything
that overwrites or rebuilds the remote from this empty vault. Paperless's *Document storage path* is
vault-relative; the Windows value pointed at an old folder, so the seed copy uses `_attachments/paperless`.

If Obsidian was opened before the files were in place, LiveSync wrote its own empty `data.json` and
the seed won't overwrite it: close Obsidian, delete
`~/Documents/obsidian/weblivia/.obsidian/plugins/obsidian-livesync/data.json`, `nh os switch`.

| Task | How |
|---|---|
| Change a setting under *Appearance*, *Core plugins*, *Files and links*, or enable/disable a plugin | Edit `obsidian.nix`; changes made in the GUI don't stick (read-only files). |
| Change a plugin's own settings | In Obsidian, as usual: `data.json` is a normal file. To make it the default for a fresh vault, copy it to `home/olivia/obsidian/seed/plugins/<id>/data.json` (only if it holds no secrets). |
| Add a plugin | Look up its repo in [community-plugins.json](https://github.com/obsidianmd/obsidian-releases/blob/master/community-plugins.json), add an entry to `pkgs/obsidian-plugins/sources.json` with the release files' URLs and hashes (`nix store prefetch-file <url>` prints the hash), then add `plugins.<id>` to `communityPlugins`. |
| Update a plugin | Change its `version`, the tag in its URLs, and the hashes in `sources.json`; the API asset URL has a new id per release (`gh api repos/<repo>/releases/tags/<version>`). `nix build .#obsidian-plugins`. |
| Turn on the git backup here too | Clone the vault's repo into the vault folder, then drop the `disabled` around `obsidian-git`. Two machines committing the same LiveSync'd files will conflict, which is why it's off. |

## Settings copied from Windows by hand

These hold logins or are app state the app rewrites, so they aren't in the config. Found in the
2026-11-09 sweep of the Windows profile ([VERIFICATION.md](VERIFICATION.md#windows-settings-sweep-2026-11-09)).
`w=/mnt/windows/Users/olivi` below.

**plex-mpv-shim** (after the `nh os switch` that brings in its `mpv.conf`). Quit the shim from its
tray icon first so it can't write over the edit, then set the four values that differ from Windows:

```sh
c=~/.config/plex-mpv-shim/conf.json
jq '.fullscreen = false | .subtitle_size = 75 | .transcode_kbps = 20000 | .shader_pack_subtype = "hq"' "$c" > "$c.new" && mv "$c.new" "$c"
```

The switch moves the old (empty) `mpv.conf` aside as `mpv.conf.hm-backup`, which can be deleted.

**Pear Desktop**, before its first start. The config holds the plugin settings (enabled: video-toggle,
do-not-track, downloader, scrobbler, synced-lyrics; five more configured but off) and the Last.fm
session, so keep it private:

```sh
install -D -m600 "$w/AppData/Roaming/YouTube Music/config.json" ~/.config/"YouTube Music"/config.json
```

**Claude Code**: the Cloudflare skills plugin was installed on Windows. In `claude`:
`/plugin marketplace add cloudflare/skills`, then `/plugin install cloudflare@cloudflare`.

**Prism Launcher** (~16 GiB): close Prism, then copy the instances and clear the three that point at
a Windows Java:

```sh
mkdir -p ~/.local/share/PrismLauncher/instances
cp -r "$w/AppData/Roaming/PrismLauncher/instances/." ~/.local/share/PrismLauncher/instances/
sed -i -e '/^JavaPath=/d' -e 's/^OverrideJavaLocation=true/OverrideJavaLocation=false/' \
  ~/.local/share/PrismLauncher/instances/*/instance.cfg
```

Accounts aren't copied; log in again in Prism. `ElyPrismLauncher` (a fork for Ely.by accounts) has
its own `26.3` and `Fabulously Optimized` instances; copy those under different names if they
differ from the Prism ones.

**Blender** (optional): `userpref.blend` is in `$w/scoop/persist/blender/portable/config/`.
Windows runs 5.2 and nixpkgs has 5.1, so copying it to `~/.config/blender/5.1/config/` loads
preferences from a newer version; skip it unless something specific is missing.

## Booting Windows

- **Now:** press **F8** at power-on (ASUS boot menu) and pick Windows Boot Manager.
- **Optional, a Windows entry in the systemd-boot menu.** The pinned NixOS supports it, but the
  device handle can only be found on the real machine:
  1. Add `boot.loader.systemd-boot.edk2-uefi-shell.enable = true;` to `boot.nix`, `nh os switch`, reboot.
  2. Choose the EFI shell entry. Run `map -c`, then `ls <handle>:\EFI` for each handle until one
     contains `Microsoft`. Test with `<handle>:\EFI\Microsoft\Boot\Bootmgfw.efi`.
  3. Add `boot.loader.systemd-boot.windows."11" = { title = "Windows 11"; efiDeviceHandle = "<handle>"; };`
     and rebuild.

## Windows-side upkeep

- Keep **Fast Startup off**, or `/mnt/windows` won't mount (and the clock/disk state gets messy).
- Windows auto-updates Firefox. Before re-running the Firefox migration, make sure NixOS has the
  same or a newer version (the script checks).
- If WSL/Docker Desktop on Windows is still broken, do a full **Restart** (not Shut down). See
  [INVENTORY.md](INVENTORY.md#windows-side-issue-found-along-the-way).

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `git pull`: "Your local changes … would be overwritten" | Uncommitted work on this machine | See [Working from two machines](#working-from-two-machines). Never `git checkout --` or `git reset --hard` it away. |
| No internet while NetBird is connected | NetBird auto-selected the server's **Exit Node (unraid)** (`0.0.0.0/0`); if that peer isn't reachable, everything goes into the tunnel and fails (`write: required key not available` in `journalctl -u netbird`) | `netbird networks deselect "Exit Node (unraid)" "Exit Node (unraid)-v6"` (kept across restarts). Check with `netbird networks list`. To stop new devices auto-selecting it, turn off *auto apply* for that route in the NetBird dashboard. |
| Plex LAN casting / plex-mpv-shim can't connect | Router DNS-rebind protection on `*.plex.direct` | `cat /etc/resolv.conf` should list 1.1.1.1 first (`networking.nix`). WARP or NetBird DNS taking over can also mask or cause it. Long-term: whitelist `plex.direct` in the router. Also set `allow_http: true` in `~/.config/plex-mpv-shim/conf.json`. |
| `netbird up` logs in to app.netbird.io | Daemon still running with old settings | `sudo systemctl restart netbird` (a switch does this automatically when `networking.nix` changes it). One-off: `netbird up --management-url https://netbird.weblivia.dev`. |
| NetBird tray icon missing | Autostart entry not picked up yet, or hidden | Log out/in once after the switch, or run `netbird-ui`; check the tray's ^ arrow. |
| Meta+Space does nothing | Vicinae server not running, or the KDE hotkey not loaded | `systemctl --user status vicinae`; `vicinae ping`; `journalctl --user -u vicinae`; log out/in so KDE loads the `plasma-manager-commands` shortcut. |
| `vicinae.service` restart-loops: *A server is already running (pid …)* | A Vicinae server started outside the unit (e.g. an older one from before a switch) is still running | Log out and back in, or `pkill -f vicinae-server`; the unit then starts the current one. Check the running build with `readlink /proc/<pid>/exe`. |
| Vicinae copies instead of pasting; snippets don't expand | Input server not running (needs its setcap wrapper) | `ls -l /run/wrappers/bin/vicinae-input-server` (from the vicinae NixOS module); `journalctl --user -u vicinae \| grep -i input`. |
| Wallpaper black, cursor default, no splash | `themes/art/` empty (fresh clone) | Copy the artwork back (`home/olivia/themes/README.md`), then log out/in. |
| Build fails: *rei2.png* / *avatar.png* is gitignored art, add it to the store | `themes/art/sddm/` art not in the store: a fresh install, the file changed, or garbage collection (`nh clean`) removed it before any switched-to system used it | Copy it back (`home/olivia/themes/README.md`), then `nix store add-file ~/nix-config/home/olivia/themes/art/sddm/<file>`. If the file itself changed, update its hash in `desktop.nix` (`nix hash file <file>`). |
| Login screen is plain Breeze, or a black screen with a cursor | SilentSDDM theme not loaded | Reboot once after the switch. `journalctl -b -u display-manager \| grep -i -e qml -e silent`; check the theme with `test-sddm-silent`. |
| Lock screen not animated | QtMultimedia / plugin not found | `ls ~/.local/share/plasma/wallpapers/`; `kdePackages.qtmultimedia` must be in `desktop.nix`; check `journalctl --user -b \| grep -i smart.video`. |
| Windows don't tile | Krohnkite disabled | System Settings → Window Management → KWin Scripts → enable Krohnkite (should be set by `kwinrc.Plugins.krohnkiteEnabled`). |
| Keyboard layout won't switch | Using the old key | It's **Alt+Shift** now; Win+Space opens Vicinae. |
| `/mnt/windows` empty or error | Windows Fast Startup / hibernation | Boot Windows, disable Fast Startup (`powercfg /h off`), shut down, retry. `journalctl -b -u mnt-windows.mount`. |
| `/mnt/unraid/*` hangs or errors | Server down, wrong credentials | `journalctl -b -u mnt-unraid-files.mount`; check `/etc/nixos/smb-secrets`; `ping 192.168.1.65`. Times out after 5 s by design. |
| Clock wrong after using Windows | Missing local-time RTC setting | `time.hardwareClockInLocalTime` is in `hosts/desktop-olivia/machine.nix` (desktop only); check `timedatectl`. Another dual-boot PC needs the same line in its own host folder. |
| Obsidian: LiveSync says it can't decrypt, or shows no remote | Its `data.json` is missing or was made by the plugin itself | Redo the first-time steps above (delete its `data.json`, copy it from Windows, switch). |
| Obsidian opens with no plugins | Restricted mode is still on for the vault | *Settings → Community plugins → Turn on community plugins*. |
| Sound only goes to one device / bus silent | Virtual sink routing | `wpctl status`; route apps in the Plasma volume applet or qpwgraph. Game/Music/Chat follow the default output. |
| Mic noisy | EasyEffects not applied | Open EasyEffects → Input → add the *Noise Reduction* (RNNoise) effect on the Seiren Mini. |
| Static / hiss from the speakers after a few seconds of silence | Codec power-down on the onboard analog out | Fixed in `audio.nix` (2026-11-09). Check `cat /sys/module/snd_hda_intel/parameters/power_save` is `0` (needs a reboot after the switch) and `wpctl status` doesn't show the Ryzen output as suspended. If it continues with both in place, it's electrical: ground loop or speaker gain, not software. |
| DAW crackles | Quantum too small | Raise the buffer in the app, or `default.clock.quantum` in `audio.nix`. |
| Resolve can't import a clip | Free Resolve on Linux lacks H.264/H.265/AAC decode | `ffmpeg -i in.mp4 -c:v dnxhd -profile:v dnxhr_hq -c:a pcm_s16le out.mov`. |
| Ollama runs on CPU | ROCm not picked up | `journalctl -u ollama`; `ollama ps` shows the processor. |
| A game won't start | Proton compatibility / anti-cheat | Check protondb.com; try Proton-GE (Steam → Properties → Compatibility). Kernel anti-cheat titles → Windows. |
| Mason LSP binary "not found"/won't run | Unpatched binary | `programs.nix-ld` should cover it; otherwise add the LSP to `programs.neovim.extraPackages` in `home/shared/neovim.nix` (both machines) or `dev.nix` (desktop only). |
| Firefox add-ons missing after migration | Add-on DB not reconciled | See [FIREFOX.md](FIREFOX.md#testing-done-and-not-done). Re-run the script (it backs up first) or reinstall from Firefox Sync's add-on list. |
| Bitwarden extension can't reach the desktop app | Integration off | Desktop app: *Allow browser integration*; extension: enable *Unlock with desktop app*. |
| `home-manager` activation fails: "would be clobbered" | A real file where HM wants a link | HM renames it to `*.hm-backup`; if it still fails, move the file away and rebuild. |
| PhotoCraft / FilmCraft text tool shows no fonts | The `/usr/share/fonts` link is missing | `ls -l /usr/share/fonts`; `sudo systemd-tmpfiles --create` recreates it (from `programs.artcraft`, `linkFonts`). |
| FilmCraft is an old version | artcraft-nix hasn't published newer ones yet | `nix flake update artcraft`; see [VERIFICATION.md](VERIFICATION.md#app-changes-2026-11-09). |
| Claude Desktop won't start or shows a blank window | Wayland flags, or a stale profile after an update | Run `claude-desktop` in a terminal to see the error; `journalctl --user -b \| grep -i claude`. |
| `ldd` says `GLIBC_2.4x not found` for Serein or Claude Desktop | They're linked against unstable's newer glibc; the system `ldd` uses stable's | Not a real problem. Check with the binary's own loader: `$(patchelf --print-interpreter <bin>) --list <bin>`. |
| Rebuild fails after an update | Upstream package change | Roll back (boot menu or `--rollback`), then `git checkout flake.lock` to return to the last good pins. |

## MacBook

| Symptom | Likely cause | Fix |
|---|---|---|
| Switch aborts: "Unexpected files in /etc" | nix-darwin won't overwrite an `/etc` file it doesn't recognise | Look at the file. If nothing in it matters, rename it to `<name>.before-nix-darwin` and switch again. To take it over without the manual step, declare its hash in `environment.etc."<path>".knownSha256Hashes` (done for `sudo_local`). |
| Switch aborts in "Homebrew bundle…" over an untrusted tap | Homebrew 6+ refuses third-party taps that aren't trusted | `trusted = true` on that tap in `modules/darwin/homebrew.nix`. |
| `brew bundle check` says "No Brewfile found" | The shell started before the switch that set `HOMEBREW_BUNDLE_FILE` | Open a new terminal tab. |
| A Dock pin or System Settings change reverts after a switch | It's declared in `modules/darwin/defaults.nix` | Change it there instead. |
| `darwin-rebuild --list-generations`: permission denied | It takes the profile lock | Use `sudo`, or `ls -l /nix/var/nix/profiles/system-*-link`. |
| WezTerm: "… is not a valid Config field" | An older WezTerm (e.g. Homebrew's 20240203) is running the repo's config | Open WezTerm from `~/Applications/Home Manager Apps` (nixpkgs build). |
| docker runs Homebrew's plugins | `cliPluginsExtraDirs` in `~/.docker/config.json` wins over `~/.docker/cli-plugins` | Remove that entry (done on 2026-11-10). |
| `brew uninstall` removed extra formulae | It autoremoves dependency-only formulae by default | Set `HOMEBREW_NO_AUTOREMOVE=1` for the command; reinstall anything needed with `brew install`. |
| A Homebrew service breaks after a cleanup | Its LaunchAgent or LaunchDaemon runs a Homebrew path | `grep -l /opt/homebrew ~/Library/LaunchAgents/*.plist /Library/Launch*/*.plist` before uninstalling; keep that formula declared. |

## Leftover data from removed apps

`nh os switch` removes the programs, not what they stored in your home folder. After the 2026-11-09
cleanup, the leftovers were checked on disk and deleted the same day:

| App | Deleted |
|---|---|
| Zen | `~/.config/zen` (profile, 98 MB), `~/.cache/zen` (100 MB) |
| Krita | `~/.local/share/krita` (91 MB), `~/.config/kritarc`, `~/.config/kritadisplayrc`, `~/.local/share/krita*.log` |
| Vesktop | `~/.config/vesktop` |
| Thunar | `~/.config/Thunar` |
| linuxmeeter (uninstalled 2026-11-09) | `~/.config/linuxmeeter` (profiles, 12 KB), `~/.local/share/com.stacksloth.linuxmeeter` (web view cache, 28 KB) |

Nothing was found for the other removed apps, and `flatpak list --app` was already empty.

`/var/lib/libvirt` (GNOME Boxes, only libvirt's default files) was deleted after the switch too.

The next time an app is removed, look for its data in `~/.config/<app>`, `~/.local/share/<app>`,
`~/.cache/<app>` and `~/.var/app/<id>` (Flatpaks).

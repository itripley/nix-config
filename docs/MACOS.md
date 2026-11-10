# macOS: macbook-olivia (nix-darwin)

The MacBook is the flake's second host: `darwinConfigurations.macbook-olivia`, nix-darwin with
home-manager, sharing the cross-platform home-manager modules with the desktop. This doc is the
Mac's equivalent of INVENTORY + MIGRATION + VERIFICATION: what was on the machine, where each thing
went, what was checked, and what stays manual. Why it's built this way is in
[DESIGN.md §11](DESIGN.md#11-macos-host-nix-darwin-in-the-same-flake).

## Machine (audited 2026-11-10, read-only)

| | |
|---|---|
| Model | MacBook Pro, **Apple M1** (`aarch64-darwin`), FileVault on |
| macOS | 26.6.2 (25G83), Xcode Command Line Tools 26.6 |
| User | `olivi` (uid 501, admin), login shell `/bin/zsh`. The NixOS user is `olivia`. |
| Hostname | was `olivias-MacBook-Pro` / "olivia’s MacBook Pro"; now `macbook-olivia` (all three names) |
| Homebrew | `/opt/homebrew`, 46 leaf formulae (226 total), 36 casks, 5 taps. `brew services` showed nothing running, but two LaunchDaemons run Homebrew binaries: httpd and the Cloudflare tunnel (found during the cleanup). |
| Before Nix | no Nix; Touch ID for sudo already set by hand in `/etc/pam.d/sudo_local` |

Backups taken before any change, outside the repo, in `~/nix-migration-backup-2026-11-10/`:
dotfiles tarball (no SSH keys), `Brewfile.before`, `defaults export` of the Dock, Finder, global,
trackpad, screenshot, clock, WindowManager and loginwindow domains, and copies of
`/etc/{pam.d/sudo_local,zshrc,zprofile,bashrc,shells}`.

## Current state (2026-11-10)

| | |
|---|---|
| System | nix-darwin with the review fixes (`d2fbf68`, switched 2026-11-10; generation 10 was `996c8e0`), `darwin-rebuild` from `nix-darwin-26.05` with `nixpkgs-26.05-darwin`, Nix 2.34.9 |
| Upkeep | Weekly LaunchDaemons: `nix-gc` (generations older than 14 days, Sundays 03:15) and `nix-optimise` (Sundays 04:15) |
| home-manager | 98 commands in `/etc/profiles/per-user/olivi/bin`; zsh, fish, git, ssh and the dotfile links managed |
| Homebrew | 26 leaf formulae (191 total), 29 casks (28 declared, plus plugdata), 5 taps (3 declared). Declared in `modules/darwin/homebrew.nix`. |
| CI | `nix flake check` on `macos-latest` on every push |
| Files | `hosts/macbook-olivia/darwin-configuration.nix` (renamed from `configuration.nix` on 2026-11-10) for this Mac; `modules/darwin/common.nix` for what any Mac gets. Another Mac: `scripts/bootstrap.sh` (DESIGN §12) |

## Where things went

| Before | Now |
|---|---|
| Homebrew CLI tools: git, gh, neovim, fish, btop, fastfetch, croc, docker (+ buildx, compose, credential helper), colima, helm, imagemagick, mc, pipx, pv, rsync, rust, unar, ente-cli | nixpkgs, in `home/shared/cli.nix` or `home/darwin/cli.nix` (some from `pkgs.unstable` to stay as new as Homebrew's). The brew copies were uninstalled. |
| Homebrew build tooling, php/httpd, Python 3.11/3.13, rbenv, mpv, tailscale, chezmoi, projectm, mole, cliclick, opencode | still Homebrew, declared as `brews` ("review later") |
| node, cloudflared | in both: Nix for the shell, Homebrew for the services that run it by path |
| 28 casks with their apps present, 3 taps | declared `casks` and trusted `taps` |
| 8 casks whose apps are gone | 7 uninstalled (records only). plugdata stays: its app is gone but its audio plugins aren't |
| Keynote (App Store) | `masApps` |
| Taphouse (App Store) | manual: no longer in the store |
| Homebrew WezTerm 20240203 | nixpkgs WezTerm in `~/Applications/Home Manager Apps` (old app removed) |
| `.zshrc`, `.zprofile`, `.zshenv`, fish `config.fish` | `home/darwin/shell.nix` + `home/shared/shell.nix` (LM Studio and cargo kept; Rancher, OrbStack and Resolve lines dropped; mise kept at first, dropped 2026-11-10) |
| `.gitconfig`, `~/.config/git/ignore`, `~/.ssh/config` | `home/shared/git.nix` + `home/darwin/git.nix` (the old file is `~/.gitconfig.before-hm`) |
| chezmoi copies of the nvim and wezterm configs | live links into this repo's `home/olivia/dotfiles/`; don't run `chezmoi apply` over them |
| `~/.docker/config.json` `cliPluginsExtraDirs` (Homebrew's plugins) | removed; docker uses the Nix plugins linked into `~/.docker/cli-plugins` |
| Dock, Finder, trackpad, clock, Stage Manager, login and screenshot settings | `modules/darwin/defaults.nix` |
| Hand-written `/etc/pam.d/sudo_local` (Touch ID) | nix-darwin `touchIdAuth` + `reattach` |
| Hand-installed JetBrainsMono Nerd Font (96 files) | `fonts.packages`, in `/Library/Fonts/Nix Fonts` |

## Nix installation

Installed 2026-11-10 with the official NixOS installer
([NixOS/nix-installer](https://github.com/NixOS/nix-installer) 2.35.4):

```sh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

It creates the "Nix Store" APFS volume (encrypted at rest by the M1, not FileVault-keyed: the
store never holds secrets), the `nixbld` group (GID 350) and 32 `_nixbld` users (UID 351+),
launchd daemons, and `/etc/nix/nix.conf`. Uninstall: `/nix/nix-installer uninstall`, but only
**after** `sudo darwin-uninstaller`. Removing Nix while nix-darwin is still installed breaks
networking.

nix-darwin then takes over the Nix install (`nix.enable` is on by default): the daemon now runs
nixpkgs' Nix (2.34.9 at the time, the same source as the desktop), and `/etc/nix/nix.conf` is
generated from `nix.settings`. The installer's files were moved to `*.before-nix-darwin` on the first
switch. nix-darwin 26.05 recognised all of them by hash, so nothing had to be renamed by hand.

## Steps

| # | Step | Status |
|---|---|---|
| 1 | Install Nix (NixOS installer) | done 2026-11-10 |
| 2 | Baseline the desktop's toplevel `drvPath` (cross-evaluated on the Mac) | done: `c577barl…-nixos-system-desktop-olivia-26.05.20261105.c56a87d.drv` |
| 3 | Minimal nix-darwin: hostname, `primaryUser`, `nix.settings`, no channels | done: generation 1, `2256d0e` |
| 4 | home-manager (no file takeover yet) | done: generation 2, `39c8bbd`; rollback rehearsed (2 → 1 → 2) |
| 5 | Shared home modules + CLI packages | done: generation 3, `13f0528` |
| 6 | Shell, git, ssh, editor config taken over | done: generations 4–5, `fa820cb` |
| 7 | Homebrew casks, brews, App Store apps (declared) | done: generations 6–7, `286d6f5` |
| 8 | macOS defaults | done: generation 8, `a252741` |
| 9 | Touch ID for sudo (nix-darwin managed) | done: generation 9, `9607781` |
| 10 | Fonts | done: generation 10, `996c8e0` |
| 11 | README, docs, CI | done: README macOS section, CLAUDE.md, CI matrix with `macos-latest` (`fff9b9e`) |
| 12 | Homebrew cleanup (Olivia's OK) | done: 21 formulae now from Nix uninstalled; node and cloudflared kept (`657592e`) |
| 13 | Review fixes: weekly GC + store optimise, mise dropped, git name shared with the desktop | done: `d2fbf68`, switched 2026-11-10; hand checks passed |

## Checked

- **Step 3** (generation 1): `scutil` reports `macbook-olivia` for ComputerName, LocalHostName and
  HostName; `nix store info` shows the daemon at 2.34.9 from the system profile; `nix config show`
  has `trusted-users = root`; `nix run nixpkgs#hello` works; `/etc/pam.d/sudo_local` is untouched.
  The desktop's toplevel `drvPath` is unchanged from the baseline.
- **Step 4** (generation 2): home-manager activated for `olivi`. It added only its three marker
  files (`~/.cache/.keep`, `~/.local/state/.keep`, `~/Library/Fonts/.home-manager-fonts-version`) and
  `/etc/profiles/per-user/olivi`. Rollback rehearsed: `sudo darwin-rebuild --rollback` to 1, then
  `sudo darwin-rebuild switch --switch-generation 2`. `darwin-rebuild --list-generations` needs
  `sudo` (it takes the profile lock); `ls -l /nix/var/nix/profiles/system-*-link` works without it.
- **Installer boot hook** (`/Library/LaunchDaemons/systems.determinate.nix-installer.nix-hook.plist`,
  runs `/nix/nix-installer repair` at boot): kept. Its shell-profile repair skips symlinked files
  (checked in the 2.35.4 source), so it leaves nix-darwin's `/etc/zshrc` and others alone. It only
  re-adds the Nix lines if a macOS update puts a stock file back, which keeps Nix usable until the
  next switch.
- **Step 5** (generation 3): 73 binaries in `/etc/profiles/per-user/olivi/bin`, all from the binary
  cache (911 MiB download). Versions checked: colima 0.10.3, docker 29.9.2, node 26.13.0, croc
  11.5.5, uv 0.11.21. Homebrew's copies still come first on PATH (`~/.zprofile` runs `brew
  shellenv`) until step 6. **Desktop:** same 68 packages. Its toplevel `drvPath` changed only because
  the package order in `home-manager-path`, `man-paths` and `olivia-fish-completions` moved
  (nix-diff). Its next `nh os switch` rebuilds those few derivations with identical contents.
- **Step 6** (generations 4 and 5): home-manager took over `~/.zshrc`, `~/.zprofile`, `~/.zshenv`,
  fish's `config.fish` and `~/.ssh/config`. The old files are next to them as `*.hm-backup` (and in
  the step 0 tarball). `~/.gitconfig` was renamed by hand to `~/.gitconfig.before-hm`, since git
  config now lives in `~/.config/git/config`. In a new login shell, `which -a` finds git, nvim, gh,
  node and fish in `/etc/profiles/per-user/olivi/bin` first, with Homebrew's copies after them.
  `git config --list --show-origin` shows the name, email and the `gh auth git-credential` helpers.
  `ssh -G unraid` resolves to root@192.168.1.65 with `id_unraid`, and `ssh -G colima` resolves
  through the colima include. The 14 backdrops were copied into the gitignored
  `dotfiles/wezterm/backdrops/`.
  - **WezTerm:** Homebrew's 20240203 release rejected the repo's config
    (`show_close_tab_button_in_tabs` is not a valid Config field). Generation 5 adds nixpkgs WezTerm
    (`0-unstable-2026-03-31`, the desktop's build) in `~/Applications/Home Manager Apps`. It opens
    fish with TX-02 and the backdrops. The old `/Applications/WezTerm.app` is still installed.
  - **Docker plugins:** `~/.docker/config.json` (not managed: docker writes the current context
    there) has `cliPluginsExtraDirs` pointing at `/opt/homebrew/lib/docker/cli-plugins`. That
    directory wins over `~/.docker/cli-plugins`, so docker still runs Homebrew's buildx 0.37.1, not
    Nix's 0.38.1. Compose is 5.5.1 either way. Removing that entry hands the plugins to Nix.
- **Step 7** (generations 6 and 7): before the switch, `brew bundle check --no-upgrade` against the
  generated Brewfile reported nothing to install. Without `--no-upgrade`, it lists the 30 declared
  items that are outdated; activation passes `--no-upgrade` (`upgrade = false`), so they stay as
  they are. After the switch:
  - No new kegs or casks (nothing in `Cellar`/`Caskroom` newer than the switch). There are still 36
    casks and 47 leaves.
  - serein and anomalyco are now trusted taps (`brew tap-info`). pear was already trusted.
  - `mas list` shows Keynote 409183694.
  - In a fresh login shell, `HOMEBREW_BUNDLE_FILE` points at the store Brewfile and `brew bundle
    check --no-upgrade` is satisfied. A shell that already ran nix-darwin's environment script
    keeps the old values until it's restarted.
  - **Taphouse is not declared.** It has an App Store receipt, but `mas list` doesn't show it and
    Apple's lookup API returns nothing for `com.multimodalsolutions.taphouse` in the us, pt, br or
    gb storefronts. It looks withdrawn from the store, so it stays a manual install.
  - Brew prints a warning about a libtiff ↔ webp circular dependency. It comes from stale keg
    records and doesn't block anything; it was left alone.
- **Docker plugins** (after step 7, with Olivia's OK): `cliPluginsExtraDirs` was removed from
  `~/.docker/config.json`, and nothing else in the file changed. The original is
  `docker-config.json.before` in the backup folder. `docker info` now lists buildx 0.38.1 and
  compose 5.6.1 from `~/.docker/cli-plugins` (Nix).
- **Step 8** (generation 8): before the switch, all 34 `defaults write` calls in the built
  activation script were compared with the live values, and every one matched. The only visible
  change was the Dock app list, rewritten with the same 19 apps (Seanime, uninstalled, dropped) and
  one Dock restart. The Dock as it was before is saved as
  `defaults/com.apple.dock.before-step8.plist`.
  - Left unmanaged: the `-currentHost` global trackpad keys (`com.apple.mouse.tapBehavior` = 1,
    `trackpadCornerClickBehavior` = 1, `enableSecondaryClick` = 0). nix-darwin only writes the
    user domain. The trackpad domains it does write give the same behaviour.
  - Key repeat is at the macOS default, so it isn't set.
- **Step 9** (generation 9): the hand-written `sudo_local` (`pam_tid.so` only, sha256
  `5bef9b2a…`) was declared as a known hash. The switch renamed it to
  `/etc/pam.d/sudo_local.before-nix-darwin` (identical to the backup copy) and linked
  `/etc/static/pam.d/sudo_local`, which has `pam_reattach` (optional) and `pam_tid.so`
  (sufficient). `/etc/pam.d/sudo` is unchanged. Olivia checked `sudo -k; sudo true` both in a
  plain shell and inside tmux: Touch ID was offered in both.
- **Step 10** (generation 10): `nerd-fonts.jetbrains-mono` 3.4.0 (JetBrains Mono 2.304) is in
  `/Library/Fonts/Nix Fonts`. Its 96 files have the same names as the hand-installed ones, and the
  Regular files are byte-identical. With Olivia's OK, the 96 hand-installed
  `~/Library/Fonts/JetBrainsMono*NerdFont*.ttf` were moved (not deleted) to
  `~/nix-migration-backup-2026-11-10/fonts/`, and the user font cache was cleared
  (`atsutil databases -removeUser`). `system_profiler SPFontsDataType` then lists the Nix copy as
  valid. The other fonts in `~/Library/Fonts` were not touched.
- **Review (2026-11-10, from the desktop):** both hosts evaluate with no warnings or failed
  assertions, `nix flake check --all-systems` passes, and CI is green on both runners. A dry-run
  build of the Mac system against cache.nixos.org fetches every real package, the `pkgs.unstable`
  ones included. The only local builds are the usual config files, wrappers and fish completions.
  Since generation 10, the only effective change for the Mac had been the Brewfile (node and
  cloudflared, `657592e`). The desktop merge left its home-manager generation identical.
- **Step 13** (`d2fbf68`, switched 2026-11-10): before the switch, `nix-diff` of the Mac system against the previous config showed
  only two changes. `.zshrc` lost the `mise activate` line, and two LaunchDaemons were added
  (`org.nixos.nix-gc`: `nix-collect-garbage --delete-older-than 14d`, Sundays 03:15;
  `org.nixos.nix-optimise`: `nix-store --optimise`, Sundays 04:15). The Mac's git config is
  byte-identical: `user.name` only moved to `home/shared/git.nix`. After the switch, Olivia checked
  all three, and all passed:
  - `sudo launchctl print system/org.nixos.nix-gc` and `system/org.nixos.nix-optimise` show both
    jobs loaded.
  - A new zsh starts without errors, and `which mise` finds nothing on PATH.
  - `git config user.name` prints `olivia`.

## Stays manual

Not declared, on purpose or because it can't be:

- **Secrets:** SSH keys (`id_ed25519`, `id_unraid`, `id_ed25519_artlivia`), copied by hand as on
  the desktop. The gh token (`gh auth login`, kept in the keychain), VPN logins (Tailscale, NetBird,
  WARP, PrivadoVPN). If a secret ever needs to be declarative, use sops-nix (one tool for NixOS,
  nix-darwin and home-manager).
- **Accounts and permissions:** Apple ID, iCloud, the App Store sign-in (needed for `masApps`), app
  licences (CrossOver, Scrivener, ForkLift, BetterDisplay). Also the privacy grants: Accessibility
  and Screen Recording for Raycast, BetterDisplay, Mac Mouse Fix and OBS.
- **Other macOS state:** login items, wallpaper, Focus, notifications, the `-currentHost` trackpad
  keys, key repeat.
- **App settings:** VS Code (`settings.json` holds an API key), Raycast, Sublime, `~/.config/mpv`.
- **Apps without a cask or store listing:** PhotoCraft, Plex MPV Shim (local build), TrackWeight,
  Authenticator, Logi Options, TeraCopy, Taphouse, and the hand-installed apps with casks that
  weren't adopted (Firefox, CrossOver, Eagle, ForkLift, Godot Mono, qBittorrent, Scrivener,
  NetBird UI). The old Homebrew `/Applications/WezTerm.app` is unused now and can be removed.
- **Personal or licensed fonts:** TX-02 (licensed), bianzhidai, Poppins, SF Movie Poster,
  Sixtyfour, Golos, Bitsumishi, deception scanline, all in `~/Library/Fonts`. The WezTerm backdrops
  go into the gitignored `home/olivia/dotfiles/wezterm/backdrops/`.
- **mise** (dropped from the config 2026-11-10): the binary in `~/.local/bin/mise` and whatever it
  installed are still on disk. Nothing runs it any more. Removing it is a manual step.
- **Homebrew leftovers:** the `plugdata` cask. Its app is gone, but its AU, VST3, CLAP and LV2
  plugins are still in `/Library/Audio/Plug-Ins` and are tracked by the cask's pkg receipts.
  Uninstalling the cask would delete them. It isn't declared, and nothing removes it
  (`cleanup = "none"`).

## Homebrew cleanup (2026-11-10)

With Olivia's OK, after step 11:

- **Kept in Homebrew, now declared:** `node` and `cloudflared`, because services use Homebrew's
  paths. The openclaw gateway LaunchAgent runs `/opt/homebrew/opt/node/bin/node` with the npm
  globals in `/opt/homebrew/lib/node_modules`. The Cloudflare tunnel LaunchDaemon runs
  `/opt/homebrew/bin/cloudflared`, with its token in the plist (not in the repo).
- **Uninstalled** with plain `brew uninstall`, after `brew uses --installed` showed no dependents:
  btop, colima, croc, docker, docker-buildx, docker-compose, docker-credential-helper, ente-cli,
  fastfetch, fish, gh, git, helm, imagemagick, midnight-commander, neovim, pipx, pv, rsync, rust,
  unar. Their config files stay (`/opt/homebrew/etc/fish`, `/opt/homebrew/etc/gitconfig`).
- **Removed automatically by brew afterwards** (unintended: `HOMEBREW_NO_AUTOREMOVE` wasn't set):
  14 dependency-only formulae, which nothing installed on request still needed. They were
  diffutils, libde265, libgit2, libheif, lima, llvm@22 (1.6 GB, from `rust`), lpeg, luv, popt,
  s-lang, tree-sitter, unibilium, utf8proc and yyjson. Nix's colima brings its own `lima-full`
  2.2.0. Anything else that turns out to need one of them can get it back with `brew install`.
- **Checked afterwards:** every tool resolves to `/etc/profiles/per-user/olivi/bin`, and the
  rustup toolchain stays the default. `brew bundle check --no-upgrade` is satisfied, and httpd and
  the cloudflared tunnel are still running.
  - The openclaw gateway was already failing before the cleanup: exit 78 (`EX_CONFIG`) from its
    `~/.openclaw` wrapper script, 39,580 launchd runs in 39 days of uptime. It was left alone.
- The old `/Applications/WezTerm.app` was already gone; only the Home Manager copy is left.
- **Stale casks** (later the same day, with Olivia's OK): `brew uninstall --cask` with
  `HOMEBREW_NO_AUTOREMOVE=1` for audacity, ente-auth, keka, quitty, renpy, shutter-encoder and
  tailscale-app. Their apps were already gone. Before running it, each cask's uninstall steps were
  read (`brew info --cask --json=v2`) and its pkg receipts checked at their install locations:
  - shutter-encoder and tailscale-app had receipts with no files left; brew forgot them with `sudo
    pkgutil`. tailscale-app also deleted `/usr/local/bin/tailscale` (a shim that ran the missing
    `Tailscale.app`) and one man page. Homebrew's `tailscale` formula (1.102.4) is unaffected.
  - The rest only dropped brew's record (keka also its `/opt/homebrew/bin/keka` wrapper).
  - **plugdata was skipped:** its 82 plugin files are still installed, and its uninstall step would
    delete them.

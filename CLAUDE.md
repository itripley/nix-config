# CLAUDE.md

NixOS 26.05 flake for one machine, `desktop-olivia` (x86_64, Ryzen 7700X + RX 7800 XT, KDE Plasma 6
on Wayland). It's **installed and in daily use**, dual-booting with Windows 11 on a separate disk.
home-manager runs as a NixOS module (user `olivia`), with plasma-manager, nix-flatpak and a few
third-party flakes. One `nh os switch` applies both system and user config.

The second host is the MacBook, `darwinConfigurations.macbook-olivia`: an M1 running nix-darwin
26.05, with home-manager as a nix-darwin module for user `olivi`. Homebrew handles the GUI apps.
`home/shared/` is imported by every machine. Mac details and its migration log are in
`docs/MACOS.md`.

Any new machine is set up with `scripts/bootstrap.sh` (Windows: `bootstrap.ps1`), DESIGN §12. Every
folder in `hosts/` is a machine, picked up by `flake.nix`: `darwin-configuration.nix` makes it a
Mac, `configuration.nix` NixOS. `hosts/wsl` is NixOS-WSL for any Windows PC. Other distros and
locked Macs get standalone `homeConfigurations."<user>@<system>"`. `home/linux/` (the apps) is
shared by the desktop, WSL and other x86_64 distros.

The full reasoning is in `docs/`. Read the relevant doc before changing an area:
`docs/MODULES.md` (every file and setting), `docs/DESIGN.md` (why), `docs/OPERATIONS.md`
(how-tos, troubleshooting), `docs/VERIFICATION.md` (what broke and how it was checked).
`docs/README.md` has the current status.

## Where things go

| Change | File |
|---|---|
| User app | `home/olivia/apps.nix` (dev tools: `home/olivia/dev.nix`). Through `home/linux` it also reaches WSL and other distros; Plasma/Flatpak/WARP-only things go in `home/olivia/default.nix` |
| CLI tool for both machines | `home/shared/cli.nix` (changes the desktop too: compare its toplevel `drvPath`) |
| Mac-only CLI tool | `home/darwin/cli.nix` |
| Mac GUI app (Homebrew cask), Homebrew-only formula, App Store app | `modules/darwin/homebrew.nix` |
| macOS setting (Dock, Finder, trackpad, …) | `modules/darwin/defaults.nix` (System Settings changes are reverted on switch) |
| Shell, git/ssh, Neovim settings for both machines | `home/shared/shell.nix`, `git.nix`, `neovim.nix` (Mac-only additions: `home/darwin/shell.nix`, `git.nix`) |
| System service, hardware, boot, network, mounts | the matching `modules/nixos/*.nix` (every PC); only this PC's hardware (Windows disk, RTC, RGB): `hosts/desktop-olivia/machine.nix`; GPU: `amd.nix` / `nvidia.nix` |
| Every NixOS machine (user, Nix settings, nh) / every Mac | `modules/nixos/common.nix` / `modules/darwin/common.nix` |
| New module | new file, then add it to `imports` in `hosts/desktop-olivia/configuration.nix` or `home/olivia/default.nix` (Mac: `hosts/macbook-olivia/darwin-configuration.nix` or `home/darwin/default.nix`; every Linux machine: `home/linux/default.nix`) |
| New machine | `scripts/bootstrap.sh` writes `hosts/<name>/` on it; no `flake.nix` edit. Standalone home-manager usernames: `standaloneUsers` in `flake.nix` |
| Plasma settings, shortcuts, theme | `home/olivia/plasma.nix` |
| Flatpak | `home/olivia/flatpak.nix` (Flathub ID) |
| Package written for this repo | `pkgs/<name>/package.nix` + a line in `overlays/packages.nix` + `packages` in `flake.nix` |
| Upstream build failure | `overlays/build-fixes.nix`, never comment the app out for good |
| Unfree / insecure allowances | `nixpkgsConfig` in `flake.nix` (shared by stable and unstable) |

## Commands

Safe to run any time:

```sh
nix flake check   # ~26 s: evaluates every Linux host and home (every .drv) + statix, deadnix, nixfmt. CI runs the same (and the Macs on macOS).
nix fmt           # nixfmt over every .nix except hardware-configuration.nix
nix develop       # nixfmt-tree, statix, deadnix, nvd, nil
nix eval .#nixosConfigurations.desktop-olivia.options.<option.path>.description   # look up an option in the pinned nixpkgs
nix eval .#nixosConfigurations.desktop-olivia.config.<option.path>                # see a value as evaluated
nix build --no-link .#warp-cloudflare-gui                                          # build a repo package alone
```

Builds. These are fine for checking a change, but they're heavy: the system is 40+ GiB, mostly from cache, and some unfree apps build locally:

```sh
nh os build                                   # build the system without activating it
nvd diff /run/current-system "$(nix build --no-link --print-out-paths .#nixosConfigurations.desktop-olivia.config.system.build.toplevel)"
nixos-rebuild build-vm --flake .#desktop-olivia   # VM for risky changes (no btrfs; see boot.nix)
```

On the Mac, `nix flake check` covers the aarch64-darwin config and also cross-evaluates the desktop:

```sh
nix build --no-link .#darwinConfigurations.macbook-olivia.system   # build the Mac system without activating
nix eval .#darwinConfigurations.macbook-olivia.options.<option.path>.description
nix eval .#nixosConfigurations.desktop-olivia.config.system.build.toplevel.drvPath   # desktop unchanged? compare before/after
```

On Windows (no Nix installed), `pwsh -File scripts\verify.ps1` evaluates the flake in Docker on the Unraid server. It runs `git add -A` first.

## Workflow for every change

1. Read the file and its section in `docs/MODULES.md`.
2. Make the change. Keep comments in the `.nix` files to a short *what*; the *why* goes in the docs.
3. `git add` any new file. Flakes ignore untracked files.
4. Run `nix fmt`, then `nix flake check`. It must pass.
5. If packages or services changed, build and show the `nvd diff` of what changes.
6. Update the docs: the file's section in `docs/MODULES.md`, a row in the History table in
   `docs/README.md` (plus Status if it changed), `docs/DESIGN.md` for design decisions,
   `docs/MIGRATION.md` for app additions and removals, `docs/VERIFICATION.md` for anything checked
   or still to check by hand.
7. Stop there and tell Olivia what to run: `nh os switch`, or `nh os boot` + reboot for kernel,
   driver, boot or kernel-parameter changes. On the Mac, run `sudo darwin-rebuild switch --flake
   ~/nix-config#macbook-olivia`. Also list any hand checks.

Commit only when asked. Commit messages are a short imperative sentence, optionally with an area
prefix (`NetBird: restart on config change`, `Add Serein from its flake`). Doc-only changes get
their own `Docs: …` commit. Never push.

## Hard rules

- Never activate anything: no `nh os switch` / `boot` / `test`, no `nixos-rebuild switch` / `boot` /
  `test` / `--rollback`, no `darwin-rebuild switch` / `activate` / `--rollback`. Olivia does that.
- Mac: never uninstall Homebrew packages, and never set `homebrew.onActivation.cleanup` to
  `"uninstall"` or `"zap"` without asking. Never delete files there without asking either.
- Never change the running system or network by hand: no `sudo`, no `systemctl start` / `stop` /
  `restart`, no `netbird up` / `networks select`, no `warp-cli connect`. Read-only status commands
  are fine.
- Never run `scripts/bootstrap.sh` or `bootstrap.ps1`: they install, wipe disks and switch. Test
  them only with `BOOTSTRAP_SOURCED=1 source scripts/bootstrap.sh` in a scratch copy of the repo
  (docs/VERIFICATION.md, "Any-machine deploy").
- Never run the disko CLI. Don't change the disk id in `hosts/desktop-olivia/disko.nix`: the
  Samsung serial is what keeps disko off the Windows NVMe. That file also defines the live
  `fileSystems`, so editing it changes real mounts.
- Never edit or reformat `hosts/desktop-olivia/hardware-configuration.nix`; it's generated.
- Never change `system.stateVersion` or `home.stateVersion`, even when upgrading NixOS.
- Never write to `/mnt/windows` (Windows C:, read-only) or the `/mnt/unraid/*` shares.
- Secrets never enter the repo or a Nix expression, because the store is world-readable. Never
  read or print `/etc/nixos/smb-secrets`, `~/.ssh`, or the Firefox profile.
- Keep `nix.settings.trusted-users` root-only. Adding `@wheel` is a passwordless path to root.
- No `nix flake update` of everything. Update one named input only when asked. For third-party
  flakes (serein, claude-desktop, artcraft, vicinae), show their new commits first.
- Never `git add -f` the gitignored art (`home/olivia/themes/art/`,
  `home/olivia/dotfiles/wezterm/backdrops/`). It's third-party and is not republished.
- No `--impure`, `nix-env`, `nix profile install`, `nix-channel`, or garbage collection.

## Gotchas

- **Several machines, one repo:** the desktop and the Mac (and any machine added since) each have a
  checkout. Before editing, run `git fetch` and `git status`; another machine may have pushed, or may
  hold uncommitted work. Never discard someone's uncommitted changes. Commit them on a branch and
  merge (docs/OPERATIONS.md, "Working from two machines").
- **Comparing before/after:** the desktop's toplevel `drvPath` is stable, but moving a module that
  adds packages reorders lists. Use `nix-diff` and check it's order only. The Mac's `drvPath` also
  changes with the git revision (`configurationRevision`), so compare it with `nix-diff` too.
- **Live dotfiles:** `home/olivia/dotfiles/{nvim,wezterm,fastfetch}` are out-of-store symlinks
  into this checkout. Edits there change the running apps immediately, with no rebuild. The
  checkout must stay at `~/nix-config`.
- **Options change between releases.** Check names with the `nix eval … .options` lookup above. For
  home-manager options use `man home-configuration.nix`. For plasma-manager, vicinae and the other
  flakes, read the module source at the locked revision. If the `nixos` docs skill is installed,
  use it for general Nix and NixOS questions, but it tracks nixpkgs **master**, not 26.05.
- **Unstable is opt-in:** use `pkgs.unstable.<name>`, and only when the stable version is too old
  (currently `claude-code` on the desktop; croc, colima, docker-buildx, kubernetes-helm and ente-cli on the Mac). Serein and Claude Desktop follow `nixpkgs-unstable`, so they link a
  newer glibc. A `GLIBC_2.4x not found` from the system `ldd` is expected.
- **Inputs follow our nixpkgs** (or our unstable, if the flake targets unstable). `vicinae` has no
  `follows` on purpose, so its builds match vicinae.cachix.org. Don't "fix" that.
- **Build fixes are temporary.** Each one in `overlays/build-fixes.nix` says what upstream bug it
  works around, and the vscode fix asserts so it fails loudly if upstream changes. After an
  update, try removing each fix. Dropping Sublime means removing three things together: `sublime4`,
  `openssl-1.1.1w` in `permittedInsecurePackages`, and the `openssl_1_1` fix.
- **Deliberate choices; don't "fix" them:** blanket `allowUnfree` and the `docker` group (DESIGN
  §4, §9), statix `repeated_keys` off so each setting sits next to its comment (`statix.toml`), no
  `system.autoUpgrade` (DESIGN §10). The audit's "left on purpose" list is in `docs/VERIFICATION.md`.
- **Settings changed in the KDE GUI are reverted** on the next switch. Lasting changes go in `plasma.nix`.
- **Users:** the Windows user is `olivi`, the NixOS user is `olivia`, and the macOS user is `olivi`.
  Usernames and home paths go only in per-host files, never in `home/shared/`. Windows paths are written
  as they appear on Windows. Line endings are LF (`.gitattributes`), since the repo is also edited
  on Windows.
- **Debugging:** `nix flake check --show-trace` for evaluation errors, `nix log <drv>` for build
  failures. Troubleshooting tables are in `docs/OPERATIONS.md`.

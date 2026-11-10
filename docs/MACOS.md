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
| Homebrew | `/opt/homebrew`, 46 leaf formulae (226 total), 36 casks, 5 taps, no running services |
| Before Nix | no Nix; Touch ID for sudo already set by hand in `/etc/pam.d/sudo_local` |

Backups taken before any change, outside the repo, in `~/nix-migration-backup-2026-11-10/`:
dotfiles tarball (no SSH keys), `Brewfile.before`, `defaults export` of the Dock, Finder, global,
trackpad, screenshot, clock, WindowManager and loginwindow domains, and copies of
`/etc/{pam.d/sudo_local,zshrc,zprofile,bashrc,shells}`.

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
| 5 | Shared home modules + CLI packages | |
| 6 | Shell, git, ssh, editor config taken over | |
| 7 | Homebrew casks, brews, App Store apps (declared) | |
| 8 | macOS defaults | |
| 9 | Touch ID for sudo (nix-darwin managed) | |
| 10 | Fonts | |
| 11 | README, docs, CI | |

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

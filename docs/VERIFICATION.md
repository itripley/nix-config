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

## Not verified (can only be checked on the real install)

| Area | Risk | How you'd notice / fix |
|---|---|---|
| **Building** the system | A package could fail to build or download. Evaluation doesn't build anything. | `nixos-install` stops with a build error before anything is activated. |
| Disk id | The by-id name is inferred from the Windows model and serial. | README step 1 checks `ls -l /dev/disk/by-id/` before disko runs. |
| Hardware | 165 Hz/VRR mode selection, LACT, OpenRGB device detection, ROCm in Resolve/Ollama, the Seiren Mini | Plasma display settings, `lact`, OpenRGB GUI, `ollama ps`. |
| Plasma shortcuts | KWin action names could differ in this Plasma version. | System Settings → Shortcuts; adjust `plasma.nix`. |
| PipeWire virtual sinks | Config is valid but routing behaviour is untested. | `wpctl status` should list Game/Music/Chat. |
| SMB mounts | Credentials and share names. | `ls /mnt/unraid/files`, `journalctl -u mnt-unraid-files.mount`. |
| `/mnt/windows` | Needs Fast Startup off. | `ls /mnt/windows`. |
| Firefox migration | Real Firefox opening the migrated profile. | See [FIREFOX.md](FIREFOX.md). |
| Flatpaks | Installed on first activation, so they need network. | `flatpak list`. |

Run `pwsh -File scripts\verify.ps1` after **any** edit before installing or rebuilding.

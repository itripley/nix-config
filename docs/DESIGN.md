# Design decisions

Each section gives the decision, then **why**, with the alternatives that were rejected.
Facts referenced here are in [INVENTORY.md](INVENTORY.md).

## 1. Dual-boot on the Samsung 850 EVO

**Decision:** install NixOS on the whole Samsung 850 EVO 500GB and leave the Windows NVMe untouched.

**Why:**
- Several daily apps have no Linux version (Adobe CC, FL Studio, Avid, Clip Studio, Voicemeeter,
  some anti-cheat games). Keeping Windows means nothing is lost; see [MIGRATION.md](MIGRATION.md).
- A separate physical disk means no shrinking of the Windows partition and no shared ESP. Windows
  updates can't overwrite the Linux boot loader, and a mistake on one OS can't break the other.
- The Samsung disk had no drive letter, so it wasn't in active use by Windows.

**Rejected:** replacing Windows (loses the Windows-only apps); NixOS-WSL (no desktop, GPU or apps,
just a CLI environment).

**Risk:** the disk is not empty (two old partitions, probably Linux). The install erases it.

## 2. Disk layout (`hosts/desktop-olivia/disko.nix`)

| Choice | Why |
|---|---|
| **disko** (declarative partitioning) | The layout is code: reviewable before it runs, and reproducible if the disk is ever replaced. |
| Disk addressed **by-id with the serial** (`ata-Samsung_SSD_850_EVO_500GB_S3R3NF0J901761H`) | `/dev/sdX` / `/dev/nvmeXnY` names can change between boots. The serial can only ever match the Samsung, so disko cannot hit the Windows NVMe by mistake. |
| **GPT** (replacing the old MBR) | UEFI boot needs an EFI partition; GPT is the norm for it. |
| **Own 1 GB ESP** | Windows' ESP is 100 MB, too small for several NixOS kernels + initrds (each generation can need tens of MB). A separate ESP also keeps the two OSes independent. |
| **btrfs** with `@`, `@home`, `@nix`, `@swap` subvolumes | zstd compression (noticeable on `/nix`), cheap snapshots later if wanted, and `/home` kept separate from the root. |
| `compress=zstd,noatime` | Compression saves space and writes; `noatime` avoids a write on every read. |
| 16 GB swapfile on its own subvolume + **zram** | btrfs swapfiles must not be copy-on-write or snapshotted; a dedicated subvolume (which disko sets up) satisfies that. zram absorbs most swapping in compressed RAM first. |

## 3. Boot

| Choice | Why |
|---|---|
| **systemd-boot** | Simple and well supported by NixOS; Secure Boot is off, so no signing tools (lanzaboote) are needed. |
| Windows via the **ASUS F8 boot menu** | systemd-boot only auto-detects Windows on its *own* ESP. Adding an entry for the other disk's ESP requires the EFI shell device handle, which can only be read on the real hardware. The option (`boot.loader.systemd-boot.windows`) is documented in the README for later. |
| `time.hardwareClockInLocalTime = true` | Windows keeps the hardware clock in local time; Linux defaults to UTC. Without this the clock is an hour off after every switch (in summer). |
| `linuxPackages_latest` | Newest fixes for RDNA3 graphics and Zen 4. |

## 4. Flake inputs and pinning (`flake.nix`, `flake.lock`)

| Input | Why |
|---|---|
| `nixpkgs` → **nixos-26.05** (stable) | Fewer surprises for a first NixOS system. Stable still gets Firefox and security updates. |
| `nixpkgs-unstable`, exposed as `pkgs.unstable.*` | Only for fast-moving tools where a release-branch version is too old: `claude-code`. |
| `home-manager` (release-26.05) | User-level config (apps, dotfiles, Firefox, Plasma) in the same repo, applied in the same rebuild. |
| `plasma-manager` | Declares KDE settings (theme, keyboard, shortcuts) that would otherwise live in hand-edited `~/.config` files. |
| `disko` | See §2. |
| `nix-flatpak` | Declarative Flatpaks for apps that aren't in nixpkgs. The list is empty since 2026-11-09 (JDownloader and Stremio removed); kept so new ones are one line. |
| `serein` flake ([ViceVerse-cz/Serein](https://github.com/ViceVerse-cz/Serein)) | Native Rust Discord client, not in nixpkgs. Its own flake targets nixos-unstable, so its `nixpkgs` follows our `nixpkgs-unstable` (same channel, no extra copy). Built from source: not in any binary cache. No release tags, so `flake.lock` pins a commit; `nix flake update serein` moves it. Needs a `dontCargoUseSystemLibs` override (VERIFICATION #15, the same failure codex had). |
| `claude-desktop` flake ([tomsch/claude-desktop-nix](https://github.com/tomsch/claude-desktop-nix)) | Anthropic's official Claude Desktop Linux beta isn't in nixpkgs. The flake repackages the `.deb` from Anthropic's apt repo (`downloads.claude.ai`), pinned by hash; its CI bumps it every 6 hours after checking the repo's GPG signature. Its `nixpkgs` follows our `nixpkgs-unstable`. The wrapper runs Electron with `--no-sandbox` (Chromium's setuid sandbox can't work from the store) and Wayland flags. `nix flake update claude-desktop` picks up new versions. |
| `artcraft` flake ([ipeglin/artcraft-nix](https://github.com/ipeglin/artcraft-nix)) | Unofficial packaging of the ArtCraft apps (storytold), not in nixpkgs. Repackages the upstream release AppImages (autoPatchelf, no FHS sandbox), pinned by upstream's sha256, with GitHub/GitLab mirrors as fallback. Its NixOS module builds against our `pkgs`; `nixpkgs` follows ours only so the lock has no extra copy. Only PhotoCraft and FilmCraft are enabled (`desktop.nix`). New releases arrive with `nix flake update artcraft`. |
| `vicinae` flake ([vicinaehq/vicinae](https://github.com/vicinaehq/vicinae)) | The launcher's own flake, set up per [its NixOS guide](https://docs.vicinae.com/nixos). nixpkgs has the package but no NixOS module: without upstream's module the input server lacks `cap_dac_override` (a `security.wrappers` entry), so paste-to-window and snippet expansion fall back to copying. Its Home Manager module replaces home-manager's `programs.vicinae`. Its `nixpkgs` deliberately does **not** follow ours, so builds match `vicinae.cachix.org` (added to `nix.settings`); the cost is its own nixpkgs and Qt in the closure. `nix flake update vicinae` picks up new releases. |

Every input except nix-flatpak and Vicinae follows our `nixpkgs` (Serein and Claude Desktop follow
`nixpkgs-unstable`; Vicinae keeps its own for the binary cache, see above), so there's one package set
per channel instead of several copies. `flake.lock` pins exact revisions, so evaluation is reproducible until you choose to update.

**Unfree / insecure:** `allowUnfree = true` (Steam, Resolve, VS Code, Plex, …). One insecure package
is permitted, `openssl-1.1.1w`, because **Sublime Text 4 still links the end-of-life OpenSSL 1.1**.
It's scoped by exact name; remove it together with `sublime4` if you stop using Sublime. Both
settings live in one `nixpkgsConfig` in `flake.nix`, used for stable and `pkgs.unstable` alike. A
blanket `allowUnfree` rather than an `allowUnfreePredicate` list is deliberate: about 20 apps are
unfree, and on a single-user desktop the list would just be upkeep.

## 5. home-manager as a NixOS module

**Decision:** home-manager runs inside the NixOS config (`home-manager.nixosModules.home-manager`)
with `useGlobalPkgs` and `useUserPackages`.

**Why:** one command (`nh os switch`) updates system and user config together. They always share
one nixpkgs and its settings (unfree, overlays). `backupFileExtension = "hm-backup"` means a file
already in the way gets renamed instead of failing the activation.

## 6. Dotfiles: live links, not store copies

**Decision:** WezTerm, Neovim and fastfetch configs are linked with `mkOutOfStoreSymlink` into the
checkout at `~/nixos-config`, instead of being copied into the read-only Nix store.

**Why:**
- LazyVim writes `lazy-lock.json` into its config directory; a read-only store copy breaks plugin updates.
- Edits apply immediately, with no rebuild for a colour or keybind tweak.
- The files stay version-controlled in this repo.

**Trade-off:** the repo must live at `~/nixos-config` (the README's install step 6 puts it there).
`userChrome.css` is the exception: it's a normal Nix-managed file because it's tiny and changes rarely.

## 7. Desktop: KDE Plasma 6 on Wayland

**Why Plasma:** the closest to the Windows workflow (taskbar, start menu, system tray). It has
built-in replacements for many Windows utilities: KWin tiling (AquaSnap/PowerToys), KRunner
(Raycast), per-app volume (EarTrumpet), Spectacle (ShareX), DDC brightness (Twinkle Tray). KDE
Connect was already in use, and Plasma handles 165 Hz + VRR well on AMD.

Carried over: pt+us layouts from Windows. The look and keys come from the old Fedora install
([FEDORA.md](FEDORA.md)): Catppuccin Macchiato + Klassy, Krohnkite tiling on Meta+H/J/K/L, and
a launcher on Meta+Space (Ulauncher there, Vicinae here), so layouts switch with Alt+Shift. (The first version used Breeze Dark and
the Windows komorebi Alt+H/J/K/L binds; Fedora's setup replaced both.)

## 8. Apps: same app first, then native replacement, then escape hatches

Order of preference for every Windows app:
1. **The same app from nixpkgs** (most of them).
2. **A native Linux replacement** when the app is Windows-only (e.g. Voicemeeter → PipeWire sinks).
3. **A third-party flake** when the app has a maintained Nix packaging outside nixpkgs (Serein,
   Claude Desktop, ArtCraft, Vicinae; §4). Each one is pinned in `flake.lock`, and its nixpkgs follows ours
   (or our unstable), except Vicinae's, which keeps its own to hit its binary cache. These flakes are outside code that runs at build time, so `nix flake update
   <name>` only after a look at what changed. Prefer flakes that repackage the vendor's own
   release files pinned by hash (Claude Desktop, ArtCraft) or build from source (Serein).
4. **Flatpak** when it exists for Linux but isn't packaged in nixpkgs or a flake. (None at the moment.)
5. **AppImage** (binfmt enabled, so they run directly) for one-off downloads like Helium or chaiNNer.
6. **Stays on Windows**, since it's a dual-boot.

**2026-11-09 cleanup:** 44 apps from the original Windows and Fedora lists were removed at Olivia's
request (Zen, the Flatpaks, most chat clients, the image/audio tools, Wine and the Windows-plugin
tooling, LM Studio, codex, opencode, Warehouse, …; the full list is in MODULES `apps.nix`). Config that
only existed for them went too (the zen-browser input, Meta+F Thunar, Vesktop autostart, libvirtd,
the codex build fix). MIGRATION.md marks each one "removed 2026-11-09", so the Windows → Linux
mapping still shows what used to cover each app.

## 9. Secrets stay out of the repo

The Nix store is **world-readable**, and this repo may be pushed somewhere. So:
- SMB credentials live in `/etc/nixos/smb-secrets` (root, mode 600), created by hand during install.
- SSH private keys are copied from the Windows drive after install, never committed.
- The Firefox profile (logins, cookies) is copied by a script, never committed.
- Obsidian's LiveSync and Paperless settings (`data.json`: CouchDB login, E2EE passphrase, API token)
  are copied by hand into `~/.config/obsidian-seed/` and only from there into the vault. LiveSync's
  own encryption of that file uses a fixed default passphrase, so it counts as plain text. Plugin
  code and the other settings are in the repo, pinned by hash.
- WezTerm wallpapers, the Plasma theme artwork (`themes/art/`) and the TX-02 font (`dotfiles/fonts/`)
  are gitignored. They're third-party art and a licensed font, not secrets, but shouldn't be republished.

**Root-equivalent access** (checked in the 2026-11-09 audit):
- `nix.settings.trusted-users` is left at `root` only. Trusting `@wheel` would let anything running
  as olivia become root without sudo's password (by setting a substituter or build hook).
- The `docker` group is root-equivalent too (it can mount `/` into a container). It's **kept on
  purpose**, so Docker works without sudo. Rootless Docker (`virtualisation.docker.rootless`) is the
  alternative if that trade-off ever stops being worth it.
- The root password set by `nixos-install` is kept: `systemd-boot.editor = false` blocks
  `init=/bin/sh`, so root's password is the way into emergency mode short of the USB installer.

## 10. Repo hygiene

- `.gitattributes` forces **LF line endings**. The repo is edited on Windows but run on Linux,
  where CRLF breaks shell scripts.
- Flakes only see **git-tracked files**, so the verify script runs `git add -A` first.
- `hardware-configuration.nix` started as a placeholder that evaluated, so the config could be
  checked before the real hardware scan existed. The install replaced it with the generated one.
- Upstream build failures are fixed in `overlays/build-fixes.nix`, not by commenting packages out,
  so the app list in `apps.nix` stays the source of truth.
- Packages written for this repo live in `pkgs/<name>/package.nix` and reach the package set through
  `overlays/packages.nix`. That way they build on their own (`nix build .#<name>`) and can be
  overridden like any nixpkgs package.
- **Checks instead of full CI builds.** `nix flake check` evaluates the whole system and lints the
  repo (statix, deadnix, nixfmt) in about 15 s. GitHub Actions runs the same on every push. CI
  doesn't build the system: it's 40+ GiB, and unfree apps like Resolve aren't in the binary cache.
  `nix fmt` formats everything except the generated `hardware-configuration.nix`. statix's
  "repeated keys" warning is off (`statix.toml`), so each setting stays next to its own comment.
- **No `system.autoUpgrade`.** Updates are manual (`nh os switch --update`, then commit
  `flake.lock`), so a broken upstream change never lands unattended on a desktop that's also used
  for work.

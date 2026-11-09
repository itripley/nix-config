# Inventory of the Windows machine

Everything in the config traces back to something observed here. The data was collected on
2026-11-08 with **read-only** PowerShell queries (CIM/WMI, the registry, `scoop list`, file reads);
nothing on Windows was changed to gather it.

## Hardware

| Component | Found | Used for |
|---|---|---|
| Machine | ASUS motherboard, hostname `DESKTOP-OLIVIA` | hostname `desktop-olivia` |
| CPU | AMD Ryzen 7 7700X (Zen 4, 8 cores) | `kvm-amd`, AMD microcode, `linuxPackages_latest` |
| GPU | AMD Radeon RX 7800 XT (RDNA3, `gfx1101`) | amdgpu, ROCm (Resolve, Blender HIP, Ollama), LACT |
| RAM | 32 GB | 16 GB swapfile + zram |
| Display | DELL S2721DGF, 2560×1440 @ 165 Hz (DP-1), plus a 1600×1200 @ 75 Hz second monitor (DP-2, found on NixOS) | 165 Hz picked automatically; Adaptive Sync set to Automatic after install |
| Network | Realtek Gaming 2.5GbE (wired) | NetworkManager defaults |
| Audio | Realtek HDA, AMD HDMI audio, **Razer Seiren Mini** USB mic, Voicemeeter virtual devices | PipeWire, virtual sinks, EasyEffects |
| Firmware | UEFI, **Secure Boot off**, SVM (virtualization) on | plain systemd-boot, no Secure Boot tooling needed |

## Disks

| Disk | Bus | Layout found | Role in this config |
|---|---|---|---|
| Fanxiang S770 1TB | NVMe | GPT: `C:` NTFS 931 GB (partition GUID `62cd18cb-2a2f-4de3-9849-fc529fea7536`) + 100 MB EFI system partition | **Windows; never touched.** Mounted read-only at `/mnt/windows` |
| Samsung SSD 850 EVO 500GB, serial `S3R3NF0J901761H` | SATA | **MBR, two partitions Windows can't read** (457 GB + 8.8 GB), likely an old Linux install + swap | **NixOS target; fully erased by disko** |
| PHILIPS Portable SSD 233 GB | USB | shows as "RAW" in Windows, because it holds a flashed NixOS ISO (Windows can't read the ISO's hybrid layout) | **the NixOS installer**; not part of the installed system |
| SanDisk 119 GB (`sdc`, seen on NixOS) | USB | GPT: 600 MB EFI + 2 GB ext4 `/boot` + 117 GB btrfs `fedora` (subvolumes `root`, `home`) | **the old Fedora 43 KDE install**; auto-mounted at `/run/media/olivia/fedora`. Source of the theme, tiling and apps in [FEDORA.md](FEDORA.md). Not part of the config. |

Other findings that matter for dual-boot:
- **Windows Fast Startup is on** (`HiberbootEnabled = 1`). That leaves `C:` in a hibernated state
  that Linux won't mount, so the README says to turn it off.
- The Windows EFI partition is only 100 MB, too small to hold NixOS kernels for several generations.

## Locale & input

- Time zone **GMT Standard Time** (Dublin/Edinburgh/Lisbon/London), UI language en-US, Windows
  components shown in Portuguese.
- Keyboard layouts: **pt-PT first, en-US second**.
- Apps in **dark mode** (`AppsUseLightTheme = 0`).

## Network

| Found | Detail |
|---|---|
| Unraid server | `UNRAID-OLIVIA` = **192.168.1.65**; SSH with `~/.ssh/id_unraid` (root) |
| Mapped drives | `X:` → `\\UNRAID-OLIVIA\appdata`, `Y:` → `\downloads`, `Z:` → `\files` |
| DNS | Static **1.1.1.1 / 1.0.0.1**. The router (192.168.1.1) has DNS-rebind protection that blanks `*.plex.direct` answers for private IPs, which breaks LAN Plex over TLS (plex-mpv-shim casting). |
| VPN / overlay | NetBird (`wt0` WireGuard interface, self-hosted management at `netbird.weblivia.dev`), Cloudflare One / WARP, PrivadoVPN |
| LAN services used | Plex + plex-mpv-shim (HTTP on 3000, GDM discovery), LocalSend, KDE Connect |

## Software

- **Package managers:** scoop (~70 apps), Chocolatey and winget via UniGetUI.
- **Installed programs:** ~110 entries from the Uninstall registry keys, plus Store apps.
- **Startup items / services** that hint at what must keep running: Ollama, OpenRGB, KDE Connect,
  LocalSend, Signal (tray), Steam, NetBird, WARP, Docker Desktop, Voicemeeter, NVIDIA Broadcast /
  AMD Noise Suppression, Everything, ShareX, AquaSnap, Twinkle Tray, and others.
- The full app list and where each one went is in [MIGRATION.md](MIGRATION.md).

## Dotfiles & personal config

| Found | Detail | Carried over as |
|---|---|---|
| `~/.config/wezterm/` | modular Lua config, already cross-platform; its Linux branch launches **`fish -l`**. Contains a `backdrops/` folder of third-party wallpapers. | `home/olivia/dotfiles/wezterm` (wallpapers excluded from git) |
| `~/.config/nvim/` | LazyVim starter config (with `lazy-lock.json`) | `home/olivia/dotfiles/nvim` |
| `~/.config/fastfetch/config.jsonc` | fastfetch config | `home/olivia/dotfiles/fastfetch` |
| `~/.config/whkdrc` | komorebi/whkd tiling keybinds: Alt+H/J/K/L focus, Alt+Shift+H/J/K/L move, Alt+Q close, Alt+M minimize | first as KWin shortcuts; now replaced by Krohnkite on Meta (Fedora setup, see FEDORA.md). Alt+Q/Alt+M kept. |
| `~/.gitconfig` | only `user.email`; no `user.name`; credential helper wincred | `dev.nix` (email only) |
| `~/.ssh/config` | host `github-artlivia` (deploy key `id_ed25519_artlivia`); keys `id_unraid`, `id_ed25519_unraid` | `dev.nix` SSH hosts; **keys are copied by hand, never committed** |
| VS Code | 43 extensions | 8 declared in `dev.nix`, rest via Settings Sync |
| Fonts | JetBrainsMono Nerd Font (used by WezTerm) | `fonts.packages` |
| Firefox | profile `9ylnf32e.default-release`, Firefox 159.0.1, 110 extensions (20 on), 15 themes, Sidebery, `userChrome.css` | see [FIREFOX.md](FIREFOX.md) |
| Bitwarden | Firefox native-messaging host `com.8bit.bitwarden` registered (desktop app ↔ browser) | declared in `firefox.nix` |

## Windows-side issue found along the way

WSL2 and Docker Desktop don't work on this boot (`HCS_E_HYPERV_NOT_INSTALLED`, Docker API returns
500), even though virtualization is fully enabled (SVM in firmware, VirtualMachinePlatform +
Hyper-V on, `hypervisorlaunchtype Auto`). The Hyper-V event log shows the hypervisor last started
on 2026-10-29 and not at all on the 2026-11-04 boot. The suspected cause is Fast Startup resuming a
hibernated kernel, and the likely fix is a full **Restart**. It's unconfirmed and doesn't affect
NixOS, but it is why verification runs on the Unraid server instead (see [VERIFICATION.md](VERIFICATION.md)).

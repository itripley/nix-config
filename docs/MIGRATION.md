# Windows → NixOS app migration

Inventory taken 2026-11-08 from DESKTOP-OLIVIA (scoop, installed programs, Store apps, startup items).
Because this is a dual-boot, nothing listed under "Stays on Windows" is lost — reboot into Windows for it.

Legend: **same** = the same app runs natively · **alt** = Linux replacement · **flatpak** / **AppImage** = installed outside nixpkgs

## Browsers, chat, productivity

| Windows | NixOS | |
|---|---|---|
| Firefox | same | whole profile migrated, see [FIREFOX.md](FIREFOX.md) |
| Chromium | same | Bitwarden + Claude extensions declared (Helium had them). Zen was installed from its flake until 2026-11-09 |
| Helium | AppImage | not packaged; download the AppImage and run it directly |
| Helium PWAs (Immich, Kavita, Open WebUI, Paper, TweetDeck, FileBrowser Quantum) | reinstall | open each site and "Install app" from Chromium |
| Legcord | same | Signal, Vesktop, Element, Cinny and Dissent removed 2026-11-09 |
| (new) Serein | native Discord client | from its own flake (`serein` input); see DESIGN §4 |
| Bitwarden, Sublime Text, Termius | same | |
| Obsidian (weblivia vault) | same | plugins, themes and settings declared; notes via LiveSync (MODULES `obsidian.nix`) |
| VS Code (+42 extensions) | same | FHS build; all extensions declared at the Windows versions (`pkgs/vscode-marketplace`), settings via Settings Sync |
| Claude desktop | same | official Linux beta, from the `claude-desktop` flake (DESIGN §4) |
| Notion, ChatGPT | web | no official Linux apps |
| Figma / Figma Agent | web | figma-linux removed 2026-11-09 |
| Scrivener | alt: Obsidian | or keep writing in Windows |

## Firefox

The whole profile (110 extensions with their settings, Sidebery, 15 themes, userChrome.css, logins,
history, open tabs) moves over. See [FIREFOX.md](FIREFOX.md) for what, how and why.

## Creative

| Windows | NixOS | |
|---|---|---|
| Blender, OBS | same | Blender is the HIP build for the 7800 XT. OBS has Background Removal + Scale to Sound (Image Reaction isn't packaged); scenes need rebuilding with Linux sources. GIMP, Kdenlive, Audacity removed 2026-11-09 |
| DaVinci Resolve | same | ⚠ free Resolve on Linux can't decode H.264/H.265/AAC — transcode with ffmpeg (DNxHR/ProRes + PCM) |
| Photoshop, Clip Studio Paint | alt: PhotoCraft | from the `artcraft` flake (DESIGN §4), early alpha. Krita and GIMP removed 2026-11-09 |
| Premiere Pro, Media Encoder, Avid Media Composer | alt: Resolve / ffmpeg, FilmCraft | FilmCraft from the `artcraft` flake (DESIGN §4), early alpha |
| paint.net | none | Pinta removed 2026-11-09 |
| XnView MP, LosslessCut, MediaInfo, MakeMKV | none | removed 2026-11-09 |
| Cavalry, Eagle, chaiNNer, Booru Tagger | Windows / AppImage | chaiNNer ships an AppImage |

## Music & audio

| Windows | NixOS | |
|---|---|---|
| Renoise, VCV Rack, Cardinal, plugdata | none | removed 2026-11-09. PipeWire still has JACK and a 256-sample quantum (min 64) |
| FL Studio | Windows | Renoise removed 2026-11-09 |
| Windows VST plugins | none | yabridge and Wine removed 2026-11-09 |
| Voicemeeter | alt: PipeWire virtual sinks **Game / Music / Chat** + qpwgraph | route apps per sink in the Plasma volume applet. linuxmeeter (a Voicemeeter-style mixer) was tried and uninstalled on 2026-11-09 |
| NVIDIA Broadcast, AMD Noise Suppression | alt: EasyEffects (RNNoise) | for the Razer Seiren Mini |
| EarTrumpet, Volume2 | alt: Plasma volume applet | per-app volume is built in |
| iZotope Trash, FakinTheFunk | Windows | |

## Media & streaming

| Windows | NixOS | |
|---|---|---|
| mpv, MPC-QT | same | mpv's Windows `mpv.conf` and `input.conf` declared (MODULES `mpv.nix`) |
| MPC-BE, madVR, LAV Filters | alt: mpv | |
| Plex, Plexamp, plex-mpv-shim | same | firewall opened for shim (3000/tcp, GDM 32410–32414/udp); set `allow_http`. Shim's `mpv.conf` declared; 4 `conf.json` values by hand (OPERATIONS) |
| TIDAL | alt: tidal-hifi | |
| Pear Desktop | same | copy its `config.json` (plugins, Last.fm) by hand (OPERATIONS). Feishin removed 2026-11-09 |
| Stremio, JDownloader 2 | none | were Flatpaks in `home/olivia/flatpak.nix`; removed 2026-11-09 |
| qBittorrent, ffmpeg | same | get_iplayer removed 2026-11-09 |
| Seanime | AppImage | |
| CDisplayEx | none | YACReader removed 2026-11-09 |

## Gaming

| Windows | NixOS | |
|---|---|---|
| Steam | same | Proton + Proton-GE, gamescope session, gamemode (MangoHud removed 2026-11-09) |
| Epic, GOG Galaxy, Amazon Games | alt: Heroic | |
| Ubisoft Connect, EA app | alt: Lutris | |
| Prism Launcher, Tabletop Simulator | same | Prism instances (~16 GiB) copied by hand (OPERATIONS). TTS has a native Steam build |
| Games | Proton | check each on protondb.com. Games with kernel-level anti-cheat (e.g. some EA/Ubisoft multiplayer titles) may need Windows. |
| DS2 Lighting Engine mod | Proton (untested) | DLL-injection mods often work under Proton with a `WINEDLLOVERRIDES` launch option; untested for this one |

## System utilities

| Windows | NixOS | |
|---|---|---|
| scoop, Chocolatey, winget, UniGetUI | nix | `home/olivia/apps.nix` + `nh os switch` |
| PowerToys, AquaSnap, TranslucentTB | Plasma / KWin built-ins | KWin tiling, window rules, KRunner |
| komorebi + whkd | Krohnkite (from the Fedora setup) | Meta+H/J/K/L focus, Meta+Shift move, Meta+Ctrl resize; Alt+Q close and Alt+M minimize kept. See [FEDORA.md](FEDORA.md). |
| Raycast | alt: Vicinae (Meta+Space; Raycast-like, runs Raycast extensions) and KRunner (Alt+Space) | Built-in file search, clipboard history, calculator, emoji; more from its extension store |
| Everything | alt: FSearch | |
| QuickLook | alt: Dolphin preview panel | |
| ShareX | alt: Spectacle (built in) + Flameshot | |
| TeraCopy, File Pilot, Files (UWP) | alt: Dolphin | |
| WinDirStat | none | Filelight removed 2026-11-09 |
| Rufus, balenaEtcher | none | Impression removed 2026-11-09 |
| 7-Zip, NanaZip | alt: 7zz + Ark | |
| Twinkle Tray | alt: Plasma brightness via DDC/CI | `hardware.i2c` enabled |
| AMD Software | alt: LACT | |
| OpenRGB | same | system service; the lowpink colors applied at boot by `openrgb-colors` |
| KDE Connect, LocalSend, croc | same | |
| ActivityWatch | none | removed 2026-11-09 |
| gsudo | sudo | |
| Bonjour | alt: Avahi | |
| Docker Desktop | alt: Docker engine | `docker` group |
| Ollama | same | with ROCm. LM Studio removed 2026-11-09 |
| claude-code | same | from nixos-unstable. codex, opencode removed 2026-11-09 |
| Godot 4 / Godot Mono, Node, Python, Git, ripgrep, tmux, mc | same | |
| Visual Studio Build Tools, Java 8 | alt: gcc/clang via nix shells | Prism Launcher brings its own JDKs |
| WezTerm | same | `wezterm` in `dev.nix` (plain package; the config is live-linked) |
| WezTerm, LazyVim, fastfetch configs | same | copied into `home/olivia/dotfiles`, live-linked |

## Networking

| Windows | NixOS | |
|---|---|---|
| NetBird | same | `services.netbird` (self-hosted server, tray app autostarts) |
| Cloudflare One / WARP | same | `services.cloudflare-warp` |
| PrivadoVPN | NetworkManager | import its WireGuard/OpenVPN configs |
| Static DNS 1.1.1.1 | same | router DNS-rebind protection breaks `*.plex.direct` |
| Mapped drives X:, Y:, Z: | `/mnt/unraid/{appdata,downloads,files}` | CIFS automount, creds in `/etc/nixos/smb-secrets` |

## Stays on Windows (no native Linux version)

Adobe Creative Cloud (Photoshop, Premiere, Media Encoder), FL Studio, Avid Media Composer,
Clip Studio Paint, Cavalry, Scrivener, Eagle, Voicemeeter, iZotope Trash, FakinTheFunk,
Blackmagic RAW/Control Panels, PACE/Sentinel license services, 8th Wall, DCP-o-matic,
File Juggler, Ev Paneli, OpenClaw Companion, Tern, BlockSlot, Wintoys, Dolby Atmos/DTS:X/Realtek
audio consoles, NVIDIA tools (no NVIDIA GPU in this machine), Raycast, Apple Software Update.

## Found later, not decided (2026-11-09)

Still installed on Windows but missing from the original inventory: Moosync, Houdoku, ImageGlass,
Wabbajack. There's also a `Calibre Library` folder (174 authors) in `C:\Users\olivi`, with no
Calibre install found.

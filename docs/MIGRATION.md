# Windows → NixOS app migration

Inventory taken 2026-11-08 from DESKTOP-OLIVIA (scoop, installed programs, Store apps, startup items).
Because this is a dual-boot, nothing listed under "Stays on Windows" is lost — reboot into Windows for it.

Legend: **same** = the same app runs natively · **alt** = Linux replacement · **flatpak** / **AppImage** = installed outside nixpkgs

## Browsers, chat, productivity

| Windows | NixOS | |
|---|---|---|
| Firefox | same | whole profile migrated, see [FIREFOX.md](FIREFOX.md) |
| Zen, Chromium | same | Zen from the zen-browser flake |
| Helium | AppImage | not packaged; download the AppImage and run it directly |
| Helium PWAs (Immich, Kavita, Open WebUI, Paper, TweetDeck, FileBrowser Quantum) | reinstall | open each site and "Install app" from Chromium/Zen |
| Signal, Vesktop, Legcord, Element, Cinny, Dissent | same | |
| Bitwarden, Obsidian, Sublime Text, Termius | same | |
| VS Code (+43 extensions) | same | FHS build; 8 extensions declared, the rest via Settings Sync |
| Notion, ChatGPT, Claude desktop | web | no official Linux apps |
| Figma / Figma Agent | alt: figma-linux | |
| Scrivener | alt: Obsidian | or keep writing in Windows |

## Firefox

The whole profile (110 extensions with their settings, Sidebery, 15 themes, userChrome.css, logins,
history, open tabs) moves over. See [FIREFOX.md](FIREFOX.md) for what, how and why.

## Creative

| Windows | NixOS | |
|---|---|---|
| Blender, GIMP, Kdenlive, OBS, Audacity | same | Blender is the HIP build for the 7800 XT |
| DaVinci Resolve | same | ⚠ free Resolve on Linux can't decode H.264/H.265/AAC — transcode with ffmpeg (DNxHR/ProRes + PCM) or cut in Kdenlive |
| Photoshop, Clip Studio Paint | alt: Krita (+ GIMP) | |
| Premiere Pro, Media Encoder, Avid Media Composer | alt: Resolve / Kdenlive / ffmpeg | |
| paint.net | alt: Pinta | |
| XnView MP, LosslessCut, MediaInfo, MakeMKV | same | |
| Cavalry, Eagle, chaiNNer, Booru Tagger | Windows / AppImage | chaiNNer ships an AppImage |

## Music & audio

| Windows | NixOS | |
|---|---|---|
| Renoise, VCV Rack, Cardinal, plugdata | same | JACK through PipeWire, 256-sample quantum (min 64) |
| FL Studio | alt: Renoise | FL itself stays on Windows |
| Windows VST plugins | yabridge | `yabridgectl add ~/.wine/drive_c/Program\ Files/Common\ Files/VST3 && yabridgectl sync` |
| Voicemeeter | alt: PipeWire virtual sinks **Game / Music / Chat** + qpwgraph | route apps per sink in the Plasma volume applet |
| NVIDIA Broadcast, AMD Noise Suppression | alt: EasyEffects (RNNoise) | for the Razer Seiren Mini |
| EarTrumpet, Volume2 | alt: Plasma volume applet | per-app volume is built in |
| iZotope Trash, FakinTheFunk | Windows | |

## Media & streaming

| Windows | NixOS | |
|---|---|---|
| mpv, MPC-QT | same | |
| MPC-BE, madVR, LAV Filters | alt: mpv | |
| Plex, Plexamp, plex-mpv-shim | same | firewall opened for shim (3000/tcp, GDM 32410–32414/udp); set `allow_http` |
| TIDAL | alt: tidal-hifi | |
| Feishin, Pear Desktop | same | |
| Stremio, JDownloader 2 | flatpak | declared in `home/olivia/flatpak.nix` |
| qBittorrent, get_iplayer, ffmpeg | same | |
| Seanime | AppImage | |
| CDisplayEx | alt: YACReader | |

## Gaming

| Windows | NixOS | |
|---|---|---|
| Steam | same | Proton + Proton-GE, gamescope session, gamemode, MangoHud |
| Epic, GOG Galaxy, Amazon Games | alt: Heroic | |
| Ubisoft Connect, EA app | alt: Lutris | |
| Prism Launcher, Tabletop Simulator | same | TTS has a native Steam build |
| Games | Proton | check each on protondb.com. Games with kernel-level anti-cheat (e.g. some EA/Ubisoft multiplayer titles) may need Windows. |
| DS2 Lighting Engine mod | Proton (untested) | DLL-injection mods often work under Proton with a `WINEDLLOVERRIDES` launch option; untested for this one |

## System utilities

| Windows | NixOS | |
|---|---|---|
| scoop, Chocolatey, winget, UniGetUI | nix | `home/olivia/apps.nix` + `nh os switch` |
| PowerToys, AquaSnap, TranslucentTB | Plasma / KWin built-ins | KWin tiling, window rules, KRunner |
| komorebi + whkd | KWin shortcuts | Alt+H/J/K/L focus, Alt+Shift+H/J/K/L tile, Alt+Q close, Alt+M minimize |
| Raycast | alt: KRunner | Alt+Space / Meta |
| Everything | alt: FSearch | |
| QuickLook | alt: Dolphin preview panel | |
| ShareX | alt: Spectacle (built in) + Flameshot | |
| TeraCopy, File Pilot, Files (UWP) | alt: Dolphin | |
| WinDirStat | alt: Filelight | |
| Rufus, balenaEtcher | alt: Impression | |
| 7-Zip, NanaZip | alt: 7zz + Ark | |
| Twinkle Tray | alt: Plasma brightness via DDC/CI | `hardware.i2c` enabled |
| AMD Software | alt: LACT | |
| OpenRGB | same | system service |
| KDE Connect, LocalSend, croc | same | |
| ActivityWatch | same | window tracking on Wayland is limited |
| gsudo | sudo | |
| Bonjour | alt: Avahi | |
| Docker Desktop | alt: Docker engine | `docker` group |
| Ollama, LM Studio | same | Ollama with ROCm |
| claude-code, codex, opencode | same | from nixos-unstable |
| Godot 4 / Godot Mono, Node, Python, Git, ripgrep, tmux, mc | same | |
| Visual Studio Build Tools, Java 8 | alt: gcc/clang via nix shells | Prism Launcher brings its own JDKs |
| WezTerm, LazyVim, fastfetch configs | same | copied into `home/olivia/dotfiles`, live-linked |

## Networking

| Windows | NixOS | |
|---|---|---|
| NetBird | same | `services.netbird` + netbird-ui |
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

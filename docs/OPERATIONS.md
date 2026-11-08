# Operations: day-to-day use and troubleshooting

## The basic loop

```sh
cd ~/nixos-config
$EDITOR home/olivia/apps.nix     # change something
nh os switch                     # build + activate (asks for sudo)
git add -A && git commit -m "…"  # record it
```

- `nh os switch` = `nixos-rebuild switch --flake ~/nixos-config#desktop-olivia`, with a readable diff
  of what changed. `nh os boot` applies at next boot instead (safer for kernel/driver changes).
- **New files must be `git add`ed** before rebuilding, or the flake won't see them.
- From Windows, check edits before rebooting into NixOS: `pwsh -File scripts\verify.ps1`.

## Common tasks

| Task | How |
|---|---|
| Add/remove an app | Edit `home/olivia/apps.nix` (user apps) or a `modules/nixos/*.nix` file (system services). Find names at https://search.nixos.org. |
| Try an app without installing | `nix shell nixpkgs#<name>` (gone when the shell closes). |
| Add a Flatpak | Add its Flathub ID to `home/olivia/flatpak.nix`. |
| Run an AppImage | `chmod +x Foo.AppImage && ./Foo.AppImage` (binfmt handles it). |
| Update everything | `nh os switch --update` (updates `flake.lock`, then rebuilds). Commit the new lock. |
| Update one input | `nix flake update home-manager`, then `nh os switch`. |
| Roll back | Pick an older generation in the boot menu, or `sudo nixos-rebuild switch --rollback`. |
| Free disk space | Automatic (`programs.nh.clean`: keeps 10 generations / 14 days). Manual: `nh clean all`. |
| Edit nvim / WezTerm / fastfetch config | Edit under `home/olivia/dotfiles/…`; they're live links, so there's no rebuild. |
| Edit Firefox `userChrome.css` | Edit `home/olivia/dotfiles/firefox/userChrome.css`, then `nh os switch`, then restart Firefox. |
| Change time zone | `time.timeZone` in `modules/nixos/desktop.nix` (e.g. `"Europe/London"`). |
| Change SMB password | `sudo $EDITOR /etc/nixos/smb-secrets` (not in the repo). |
| Drop Sublime Text | Remove `sublime4` from `apps.nix` **and** the `permittedInsecurePackages` line in `flake.nix`. |
| Upgrade to the next NixOS release | Change `nixos-26.05` / `release-26.05` in `flake.nix`, `nh os switch --update`. **Don't** touch `stateVersion`. |

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
| Plex LAN casting / plex-mpv-shim can't connect | Router DNS-rebind protection on `*.plex.direct` | `cat /etc/resolv.conf` should list 1.1.1.1 first (`networking.nix`). WARP or NetBird DNS taking over can also mask or cause it. Long-term: whitelist `plex.direct` in the router. Also set `allow_http: true` in `~/.config/plex-mpv-shim/conf.json`. |
| `/mnt/windows` empty or error | Windows Fast Startup / hibernation | Boot Windows, disable Fast Startup (`powercfg /h off`), shut down, retry. `journalctl -b -u mnt-windows.mount`. |
| `/mnt/unraid/*` hangs or errors | Server down, wrong credentials | `journalctl -b -u mnt-unraid-files.mount`; check `/etc/nixos/smb-secrets`; `ping 192.168.1.65`. Times out after 5 s by design. |
| Clock wrong after using Windows | Missing local-time RTC setting | `time.hardwareClockInLocalTime` is in `boot.nix`; check `timedatectl`. |
| Sound only goes to one device / bus silent | Virtual sink routing | `wpctl status`; route apps in the Plasma volume applet or qpwgraph. Game/Music/Chat follow the default output. |
| Mic noisy | EasyEffects not applied | Open EasyEffects → Input → add the *Noise Reduction* (RNNoise) effect on the Seiren Mini. |
| DAW crackles | Quantum too small | Raise the buffer in the app, or `default.clock.quantum` in `audio.nix`. |
| Resolve can't import a clip | Free Resolve on Linux lacks H.264/H.265/AAC decode | `ffmpeg -i in.mp4 -c:v dnxhd -profile:v dnxhr_hq -c:a pcm_s16le out.mov`, or edit in Kdenlive. |
| Ollama runs on CPU | ROCm not picked up | `journalctl -u ollama`; `ollama ps` shows the processor. |
| A game won't start | Proton compatibility / anti-cheat | Check protondb.com; try Proton-GE (Steam → Properties → Compatibility). Kernel anti-cheat titles → Windows. |
| Windows VST plugin missing in DAW | yabridge not synced | `yabridgectl add "<plugin dir in wine prefix>" && yabridgectl sync`. |
| Mason LSP binary "not found"/won't run | Unpatched binary | `programs.nix-ld` should cover it; otherwise add the LSP to `programs.neovim.extraPackages` in `dev.nix`. |
| Firefox add-ons missing after migration | Add-on DB not reconciled | See [FIREFOX.md](FIREFOX.md#testing-done-and-not-done). Re-run the script (it backs up first) or reinstall from Firefox Sync's add-on list. |
| Bitwarden extension can't reach the desktop app | Integration off | Desktop app: *Allow browser integration*; extension: enable *Unlock with desktop app*. |
| `home-manager` activation fails: "would be clobbered" | A real file where HM wants a link | HM renames it to `*.hm-backup`; if it still fails, move the file away and rebuild. |
| Rebuild fails after an update | Upstream package change | Roll back (boot menu or `--rollback`), then `git checkout flake.lock` to return to the last good pins. |

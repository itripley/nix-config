<!--
The manual in niri: Settings > Information > Manual, or "Manual" in the launcher.
Edit it here; it's read again each time it opens, with no rebuild. What it understands:
  # Title (two words)     ## Section     ### Part     paragraphs (the first in a section is the intro)
  - `command` what it does          - [Alt+B] what it does
  {keys}      every key in niri's config, read live     {tutorial}  the moving-around animation
-->

# User Manual

## Moving around
Windows sit side by side on a strip, and each workspace is another strip below. Super (spr) is the Windows key.

{tutorial}

## Keys
These come straight from niri's config, so they're always the ones in use.

{keys}

## This desktop
niri is the second desktop on this account, with the same apps, logins and files as Plasma.

- `~/.config/niri/cfg` Keys, mouse, screens, rules

niri reloads those files when they're saved. Settings writes the mouse and display ones itself. There's no log out in the power menu: Ctrl+Alt+Delete quits niri.

To use Plasma, log out here first, then pick it on the login screen. Only one desktop runs at a time.

## Terminal
kitty, with the same backgrounds as WezTerm. Each tab has its own; the keys change the current tab's.

- [Alt+/] Random background
- [Alt+,] Previous background
- [Alt+.] Next background
- [Alt+B] No background

## NixOS
Everything here is declared in ~/nix-config. Change a file, then switch.

### Every day

- `nh os switch` Build and use the change
- `nh os boot` Use it from the next start (kernel, drivers)
- `nh os build` Only build it
- `git add` New files, before building

When the kernel has changed, Settings says "Restart recommended".

### Apps

- `nix shell nixpkgs#name` Try an app without installing
- `home/olivia/apps.nix` Add or remove one

### Updates

- `nh os switch --update` Everything
- `nix flake update name` One input, then switch

### If something breaks

- `sudo nixos-rebuild switch --rollback` Go back one

Older generations are also in the boot menu. Old ones are cleaned up by themselves (10 generations, 14 days).

- `nh clean all` Free space now

## Where things are
Inside ~/nix-config.

- `home/pond` This desktop
- `home/olivia/plasma.nix` Plasma
- `modules/nixos` The system
- `home/olivia/dotfiles` kitty, WezTerm, Neovim, this manual
- `docs/OPERATIONS.md` How to do everything else

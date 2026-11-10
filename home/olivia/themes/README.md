# Plasma theme (from the old Fedora install)

Linked into `~/.local/share` by `home/olivia/plasma.nix`.

| Folder | What | In git? |
|---|---|---|
| `color-schemes/CatppuccinMacchiato.colors` | Catppuccin Macchiato color scheme (MIT) | yes |
| `kwin-effects/kinetic_maximize` | "Kinetic" maximize animation, KWin JS effect (GPL) | yes |
| `plasma-wallpapers/luisbocanegra.smart.video.wallpaper.reborn` | Smart Video Wallpaper Reborn 2.5.1 (GPLv2+), used for the animated lock screen | yes |
| `art/Lain` | "Lain" splash screen (look-and-feel package) | no |
| `art/Bocchi-The-Cursor-Alt-Cross` | cursor theme | no |
| `art/wallpapers/` | desktop wallpapers (`GpIWw6Ma4AAXh2A.png` main screen, `D2uFrIz.png` second) and the cube skybox (`GVLweQ9bgAEn4ct.png`) | no |
| `art/lockscreen.gif` | lock-screen animation | no |
| `art/sddm/` | login screen (SilentSDDM, `modules/nixos/desktop.nix`): background `rei2.png` and avatar `avatar.png` | no |

`art/` is gitignored: it's third-party artwork, like the WezTerm backdrops. On a fresh
checkout, copy it back from the Fedora drive (`/run/media/olivia/fedora/home/olivi`):

```sh
F=/run/media/olivia/fedora/home/olivi; A=~/nixos-config/home/olivia/themes/art
cp -r $F/.local/share/plasma/look-and-feel/Lain $F/.icons/Bocchi-The-Cursor-Alt-Cross $A/
mkdir -p $A/wallpapers && cp $F/Pictures/{GpIWw6Ma4AAXh2A,D2uFrIz,GVLweQ9bgAEn4ct}.png $A/wallpapers/
cp $F/Videos/lockscreen.gif $A/
R=/run/media/olivia/fedora/root; mkdir -p $A/sddm
cp $R/usr/share/sddm/themes/silent/backgrounds/rei2.png $A/sddm/
cp $R/var/lib/AccountsService/icons/olivi $A/sddm/avatar.png
# The login screen needs these in the store (the greeter can't read /home); desktop.nix has their hashes
nix store add-file $A/sddm/rei2.png; nix store add-file $A/sddm/avatar.png
```

Without `art/`, everything else still builds; the links just point at nothing and Plasma falls back
to its defaults for those pieces. The exception is `art/sddm/`: until both files are added to the
store, the system build stops with a message saying which one is missing. Added files are only kept
until a switched-to system uses them; before that, garbage collection (`nh clean`) can remove them, and
they have to be added again.

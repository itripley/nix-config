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

`art/` is gitignored: it's third-party artwork, like the WezTerm backdrops. On a fresh
checkout, copy it back from the Fedora drive (`/run/media/olivia/fedora/home/olivi`):

```sh
F=/run/media/olivia/fedora/home/olivi; A=~/nixos-config/home/olivia/themes/art
cp -r $F/.local/share/plasma/look-and-feel/Lain $F/.icons/Bocchi-The-Cursor-Alt-Cross $A/
mkdir -p $A/wallpapers && cp $F/Pictures/{GpIWw6Ma4AAXh2A,D2uFrIz,GVLweQ9bgAEn4ct}.png $A/wallpapers/
cp $F/Videos/lockscreen.gif $A/
```

Without `art/`, everything still builds; the links just point at nothing and Plasma falls back
to its defaults for those pieces.

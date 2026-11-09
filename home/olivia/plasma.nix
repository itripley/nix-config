# KDE Plasma look and behaviour, carried over from the old Fedora 43 install.
# Theme files live in ./themes (see themes/README.md).
{ config, pkgs, ... }:
let
  # Live links into the checkout for the gitignored artwork (same idea as default.nix)
  themes = "${config.home.homeDirectory}/nixos-config/home/olivia/themes";
  art = path: config.lib.file.mkOutOfStoreSymlink "${themes}/art/${path}";
  artPath = path: "${themes}/art/${path}";
in
{
  xdg.dataFile = {
    "color-schemes/CatppuccinMacchiato.colors".source = ./themes/color-schemes/CatppuccinMacchiato.colors;
    "kwin/effects/kinetic_maximize".source = ./themes/kwin-effects/kinetic_maximize;
    "plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn".source =
      ./themes/plasma-wallpapers/luisbocanegra.smart.video.wallpaper.reborn;
    "plasma/look-and-feel/Lain".source = art "Lain"; # splash screen only
    "icons/Bocchi-The-Cursor-Alt-Cross".source = art "Bocchi-The-Cursor-Alt-Cross";
  };

  programs.plasma = {
    enable = true;

    # No global theme on Fedora either: each piece is set on its own
    workspace = {
      theme = "default"; # Breeze Plasma style, follows the color scheme
      colorScheme = "CatppuccinMacchiato";
      iconTheme = "breeze-dark";
      cursor = {
        theme = "Bocchi-The-Cursor-Alt-Cross";
        size = 24;
      };
      splashScreen.theme = "Lain";
      windowDecorations = {
        library = "org.kde.klassy"; # klassy is installed system-wide (desktop.nix)
        theme = "Klassy";
      };
      # One per screen, in screen order (0 = DP-1 main, 1 = DP-2)
      wallpaper = [
        (artPath "wallpapers/GpIWw6Ma4AAXh2A.png")
        (artPath "wallpapers/D2uFrIz.png")
      ];
    };

    kwin.virtualDesktops = {
      number = 3;
      rows = 1;
    };

    # Layout switching moved off Win+Space (Ulauncher has it now, as on Fedora)
    input.keyboard = {
      layouts = [
        { layout = "pt"; }
        { layout = "us"; }
      ];
      options = [ "grp:alt_shift_toggle" ];
    };

    shortcuts = {
      kwin = {
        # Krohnkite tiling (Fedora binds). Focus Right stays unbound: Meta+L locks the screen.
        "KrohnkiteFocusLeft" = "Meta+H";
        "KrohnkiteFocusDown" = "Meta+J";
        "KrohnkiteFocusUp" = "Meta+K";
        "KrohnkiteShiftLeft" = "Meta+Shift+H";
        "KrohnkiteShiftDown" = "Meta+Shift+J";
        "KrohnkiteShiftUp" = "Meta+Shift+K";
        "KrohnkiteShiftRight" = "Meta+Shift+L";
        "KrohnkiteShrinkWidth" = "Meta+Ctrl+H";
        "KrohnkiteGrowHeight" = "Meta+Ctrl+J";
        "KrohnkiteShrinkHeight" = "Meta+Ctrl+K";
        "KrohnkitegrowWidth" = "Meta+Ctrl+L";
        "KrohnkiteIncrease" = "Meta+I";
        "KrohnkiteMonocleLayout" = "Meta+M";
        "KrohnkiteToggleFloat" = "Meta+S";
        "KrohnkiteFloatAll" = "Meta+Shift+F";
        # Focus Previous (Meta+,), Next Layout (Meta+\) and Previous Layout (Meta+|) were
        # Krohnkite's own defaults on Fedora too; Krohnkite registers them itself.

        # The Windows komorebi Alt+H/J/K/L binds are replaced by Krohnkite. Set back to
        # KDE's defaults explicitly, since plasma-manager doesn't reset removed keys.
        "Switch Window Left" = "Meta+Alt+Left";
        "Switch Window Down" = "Meta+Alt+Down";
        "Switch Window Up" = "Meta+Alt+Up";
        "Switch Window Right" = "Meta+Alt+Right";
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Bottom" = "Meta+Down";
        "Window Quick Tile Top" = "Meta+Up";
        "Window Quick Tile Right" = "Meta+Right";

        # Kept from Windows
        "Window Close" = "Alt+Q";
        "Window Minimize" = "Alt+M";
      };
      # App launchers from Fedora
      "services/org.wezfurlong.wezterm.desktop"."_launch" = "Meta+Return";
    };

    # Wayland apps can't grab global keys themselves; KDE calls ulauncher-toggle instead
    hotkeys.commands."ulauncher-toggle" = {
      name = "Ulauncher";
      key = "Meta+Space";
      command = "ulauncher-toggle";
    };

    configFile = {
      kwinrc = {
        Plugins = {
          krohnkiteEnabled = true;
          cubeEnabled = true;
          translucencyEnabled = true;
          # kinetic_maximize is enabled by default once installed
        };
        "Script-krohnkite" = {
          limitTileWidthRatio = 2.2;
          screenGapBetween = 10;
          screenGapBottom = 17;
          screenGapLeft = 9;
          screenGapRight = 9;
          screenGapTop = 10;
        };
        Tiling.padding = 4;
        "Effect-cube" = {
          Background = "SkyBox";
          DistanceFactor = 1.73;
          SkyBox = artPath "wallpapers/GVLweQ9bgAEn4ct.png";
        };
        "Effect-translucency" = {
          ComboboxPopups = 99;
          Dialogs = 99;
          MoveResize = 93;
        };
      };

      # Klassy window decoration settings
      klassyrc = {
        ButtonColors = {
          ButtonBackgroundColorsActive = "Accent";
          ButtonIconColorsActive = "Accent";
          CloseButtonIconColorActive = "AsSelected";
        };
        ShadowStyle.ShadowSize = "ShadowNone";
        Windeco = {
          ButtonIconStyle = "StyleOxygen";
          ButtonShape = "ShapeFullHeightRoundedRectangle";
          WindowCornerRadius = 7;
        };
        WindowOutlineStyle = {
          ThinWindowOutlineThickness = 1.25;
          WindowOutlineAccentColorOpacityActive = 39;
          WindowOutlineContrastOpacityInactive = 7;
        };
      };
      breezerc.Common.ShadowSize = "ShadowNone";

      # Animated lock screen (Smart Video Wallpaper Reborn playing lockscreen.gif)
      kscreenlockerrc = {
        Greeter.WallpaperPlugin = "luisbocanegra.smart.video.wallpaper.reborn";
        "Greeter/Wallpaper/luisbocanegra.smart.video.wallpaper.reborn/General" = {
          VideoUrls = builtins.toJSON [
            {
              filename = "file://${artPath "lockscreen.gif"}";
              enabled = true;
              duration = 0;
              customDuration = 0;
              playbackRate = 0;
              loop = false;
            }
          ];
        };
      };

      # WezTerm as the default terminal (Dolphin "Open Terminal", etc.)
      kdeglobals.General = {
        TerminalApplication = "wezterm start --cwd .";
        TerminalService = "org.wezfurlong.wezterm.desktop";
      };
    };
  };

  # Ulauncher (Fedora's launcher), started hidden at login. GDK_BACKEND=x11 as on Fedora:
  # under Wayland it can't position its window otherwise.
  systemd.user.services.ulauncher = {
    Unit = {
      Description = "Ulauncher application launcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [ "GDK_BACKEND=x11" ];
      ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

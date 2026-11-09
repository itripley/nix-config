# KDE Plasma look and behaviour, carried over from the old Fedora 43 install.
# Theme files live in ./themes (see themes/README.md).
{
  config,
  osConfig,
  ...
}:
let
  # Live links into the checkout for the gitignored artwork (same idea as default.nix)
  themes = "${osConfig.programs.nh.flake}/home/olivia/themes";
  art = path: config.lib.file.mkOutOfStoreSymlink "${themes}/art/${path}";
  artPath = path: "${themes}/art/${path}";
in
{
  xdg.dataFile = {
    "color-schemes/CatppuccinMacchiato.colors".source =
      ./themes/color-schemes/CatppuccinMacchiato.colors;
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

    # Layout switching moved off Win+Space (the launcher has it now, as on Fedora)
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
      # Meta+V goes to Vicinae's clipboard history (below); Klipper's popup gives it up
      plasmashell."show-on-mouse-pos" = [ ];
    };

    # Wayland apps can't grab global keys themselves, so KDE runs the Vicinae commands
    # (docs.vicinae.com/quickstart/kde). Both need the server (programs.vicinae below).
    hotkeys.commands = {
      "vicinae-toggle" = {
        name = "Vicinae";
        key = "Meta+Space";
        command = "vicinae toggle";
      };
      "vicinae-clipboard" = {
        name = "Vicinae clipboard history";
        key = "Meta+V";
        command = "vicinae vicinae://launch/clipboard/history";
      };
    };

    configFile = {
      kwinrc = {
        Plugins = {
          krohnkiteEnabled = true;
          cubeEnabled = true;
          translucencyEnabled = true;
          # kinetic_maximize is enabled by default once installed
        };
        # Focus stealing prevention "Low" (KDE's default, pinned): any higher and the Vicinae
        # window can fail to take focus when toggled (docs.vicinae.com/quickstart/kde)
        Windows.FocusStealingPreventionLevel = 1;
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

  # Vicinae launcher (replaces Fedora's Ulauncher). The server runs from login as a user
  # service; Meta+Space toggles its window (hotkeys above). Uses KWin's layer-shell support.
  # Module and package come from the vicinae flake input (docs.vicinae.com/nixos), not
  # home-manager/nixpkgs. `settings` goes to a store file (VICINAE_OVERRIDES) applied on top
  # of the GUI's settings.json, so Vicinae's own settings screen still saves; Nix values win.
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme.dark.name = "catppuccin-macchiato"; # bundled; matches the Plasma colors
      # Vicinae asks KWin for blur itself; KDE's blur is strong, so let more of it show
      launcher_window.opacity = 0.85;
    };
  };
}

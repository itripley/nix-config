{ ... }:
{
  programs.plasma = {
    enable = true;

    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop"; # Windows was in dark mode
    };

    input.keyboard = {
      layouts = [
        { layout = "pt"; }
        { layout = "us"; }
      ];
      options = [ "grp:win_space_toggle" ];
    };

    # Mirrors the whkd/komorebi binds from ~/.config/whkdrc on Windows
    shortcuts.kwin = {
      "Switch Window Left" = "Alt+H";
      "Switch Window Down" = "Alt+J";
      "Switch Window Up" = "Alt+K";
      "Switch Window Right" = "Alt+L";
      "Window Quick Tile Left" = "Alt+Shift+H";
      "Window Quick Tile Bottom" = "Alt+Shift+J";
      "Window Quick Tile Top" = "Alt+Shift+K";
      "Window Quick Tile Right" = "Alt+Shift+L";
      "Window Close" = "Alt+Q";
      "Window Minimize" = "Alt+M";
    };
  };
}

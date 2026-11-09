{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
  };

  # Windows had "GMT Standard Time" with a pt-PT keyboard. Europe/London has the same rules if preferred.
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "en_US.UTF-8";

  # pt-PT first, en-US second (matches Windows). Alt+Shift switches layouts: Win+Space
  # opens Ulauncher, as on the old Fedora install (see home/olivia/plasma.nix).
  services.xserver.xkb = {
    layout = "pt,us";
    options = "grp:alt_shift_toggle";
  };

  # KWin/Plasma add-ons from the Fedora setup, system-wide so KWin and plasmashell find them
  environment.systemPackages = with pkgs; [
    klassy # window decoration
    kdePackages.krohnkite # tiling script
    kdePackages.qtmultimedia # QML module for the Smart Video Wallpaper (animated lock screen)
  ];
  console.useXkbConfig = true;

  programs.kdeconnect.enable = true; # opens its firewall ports
  programs.partition-manager.enable = true;
  services.printing.enable = true;

  # Escape hatches for apps not in nixpkgs
  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true; # run ./Something.AppImage directly
  };

  # ArtCraft apps (artcraft flake input). The module also links /usr/share/fonts to the
  # system fonts: their text tools only look there, not through fontconfig.
  programs.artcraft = {
    enable = true;
    apps = [
      "photocraft" # Photoshop
      "filmcraft" # Premiere Pro
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    corefonts
  ];
}

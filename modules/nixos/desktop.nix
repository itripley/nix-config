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

  # pt-PT first, en-US second (matches Windows); Win+Space switches layouts like on Windows
  services.xserver.xkb = {
    layout = "pt,us";
    options = "grp:win_space_toggle";
  };
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

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    corefonts
  ];
}

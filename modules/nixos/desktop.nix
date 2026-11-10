{ lib, pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
  };

  # olivia's desktop home-manager config: Plasma, apps, dotfiles (home/olivia)
  home-manager.users.olivia = import ../../home/olivia;

  # SilentSDDM login screen (silent-sddm flake input): Fedora's "rei" preset with its edits.
  # The module sets SDDM's theme, Qt modules and virtual keyboard. Fedora's own background and
  # avatar are in login-art.nix; without it the preset's video background shows.
  programs.silentSDDM =
    let
      fonts =
        lib.genAttrs
          [
            "LockScreen.Clock"
            "LockScreen.Date"
            "LockScreen.Message"
            "LoginScreen.LoginArea.Username"
            "LoginScreen.LoginArea.PasswordInput"
            "LoginScreen.LoginArea.LoginButton"
            "LoginScreen.LoginArea.Spinner"
            "LoginScreen.LoginArea.WarningMessage"
            "LoginScreen.MenuArea.Buttons"
            "LoginScreen.MenuArea.Popups"
            "Tooltips"
          ]
          (_: {
            font-family = "JetBrainsMonoNerdFont";
          });
    in
    {
      enable = true;
      theme = "rei";
      settings = fonts // {
        "LoginScreen.LoginArea.Avatar".shape = "circle";
      };
    };

  # Windows had "GMT Standard Time" with a pt-PT keyboard. Europe/London has the same rules if preferred.
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "en_US.UTF-8";

  # pt-PT first, en-US second (matches Windows). Alt+Shift switches layouts: Win+Space
  # opens the launcher (Vicinae), as on the old Fedora install (see home/olivia/plasma.nix).
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

  # Plasma 6 turns these on by default (mkDefault); neither is used here.
  # Orca screen reader, and speech-dispatcher with its voices (~1.2 GiB closure, ran at every
  # login; also enabled by NixOS' graphical-desktop defaults). No text-to-speech without it.
  services.orca.enable = false;
  services.speechd.enable = false;
  # KDE PIM (Akonadi + a MariaDB server) for KMail/KOrganizer/Kontact:
  programs.kde-pim.enable = false;

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

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

  # SilentSDDM login screen (silent-sddm flake input): Fedora's "rei" preset with its edits.
  # The module sets SDDM's theme, Qt modules and virtual keyboard, and links the avatar.
  programs.silentSDDM =
    let
      # Third-party art, gitignored: added to the store by hand (home/olivia/themes/README.md)
      art =
        name: hash:
        pkgs.requireFile {
          inherit name hash;
          message = ''
            ${name} is gitignored art. Add it to the store, then build again:
              nix store add-file ~/nixos-config/home/olivia/themes/art/sddm/${name}
          '';
        };
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
      backgrounds.rei2 = art "rei2.png" "sha256-Hu/hnIvhM8ClDcNUQFmJCR/hT495eRu3gZlYta0+bXc=";
      profileIcons.olivia = art "avatar.png" "sha256-3pdAQJ1e5xCpqMcPWMglKm0TxKa7eyDLy2/+KG5qWM8=";
      settings = fonts // {
        General.animated-background-placeholder = "rei2.png";
        LockScreen.background = "rei2.png";
        LoginScreen.background = "rei2.png";
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

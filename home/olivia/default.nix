{ config, osConfig, ... }:
{
  imports = [
    ../shared
    ./apps.nix
    ./dev.nix
    ./firefox.nix
    ./plasma.nix
    ./flatpak.nix
    ./warp-gui.nix
    ./obsidian.nix
    ./mpv.nix
    ./easyeffects.nix
  ];

  home.username = "olivia";
  home.homeDirectory = "/home/olivia";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  # fish, PATH, and the wezterm/nvim/fastfetch links: home/shared/ (also used by the Mac)

  # Licensed fonts (TX-02 for WezTerm and Obsidian), kept out of git: dotfiles/fonts is gitignored.
  # A live link into the checkout, like the shared dotfiles.
  xdg.dataFile."fonts/nixos-config".source =
    config.lib.file.mkOutOfStoreSymlink "${osConfig.programs.nh.flake}/home/olivia/dotfiles/fonts";

  # EasyEffects (mic noise suppression, EQ presets): easyeffects.nix
}

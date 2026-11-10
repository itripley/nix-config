{ config, osConfig, ... }:
let
  # Live symlinks into the checkout (not the read-only store), so LazyVim can
  # write lazy-lock.json and edits apply without a rebuild.
  # The checkout is programs.nh.flake (configuration.nix): ~/nixos-config.
  dotfiles = "${osConfig.programs.nh.flake}/home/olivia/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
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
  ];

  home.username = "olivia";
  home.homeDirectory = "/home/olivia";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  programs.fish = {
    enable = true; # WezTerm's Linux launch config starts `fish -l`
    functions.fish_greeting = "pokemon-colorscripts -r"; # Fedora's greeting
  };

  # Fedora had these on PATH (cargo installs, go installs)
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
  ];

  xdg.configFile = {
    "wezterm".source = link "wezterm"; # wallpapers go in wezterm/backdrops (gitignored)
    "nvim".source = link "nvim";
    "fastfetch".source = link "fastfetch";
  };

  # Licensed fonts (TX-02 for WezTerm and Obsidian), kept out of git: dotfiles/fonts is gitignored
  xdg.dataFile."fonts/nixos-config".source = link "fonts";

  # Mic noise suppression (RNNoise) and EQ: replaces NVIDIA Broadcast / AMD Noise Suppression
  services.easyeffects.enable = true;
}

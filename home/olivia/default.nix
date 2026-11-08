{ config, ... }:
let
  # Live symlinks into the checkout (not the read-only store), so LazyVim can
  # write lazy-lock.json and edits apply without a rebuild.
  # Requires the repo to be cloned at ~/nixos-config.
  dotfiles = "${config.home.homeDirectory}/nixos-config/home/olivia/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  imports = [
    ./apps.nix
    ./dev.nix
    ./firefox.nix
    ./plasma.nix
    ./flatpak.nix
  ];

  home.username = "olivia";
  home.homeDirectory = "/home/olivia";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  programs.fish.enable = true; # WezTerm's Linux launch config starts `fish -l`

  xdg.configFile = {
    "wezterm".source = link "wezterm"; # wallpapers go in wezterm/backdrops (gitignored)
    "nvim".source = link "nvim";
    "fastfetch".source = link "fastfetch";
  };

  # Mic noise suppression (RNNoise) and EQ: replaces NVIDIA Broadcast / AMD Noise Suppression
  services.easyeffects.enable = true;
}

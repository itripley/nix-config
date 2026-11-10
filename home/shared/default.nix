# home-manager modules shared by both hosts. Platform-specific config stays in
# home/olivia (NixOS) and home/darwin (macOS).
{ config, ... }:
let
  # Live symlinks into the checkout (not the read-only store), so LazyVim can
  # write lazy-lock.json and edits apply without a rebuild.
  # The checkout is ~/nixos-config on both machines (programs.nh.flake on the desktop).
  dotfiles = "${config.home.homeDirectory}/nixos-config/home/olivia/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  imports = [
    ./cli.nix
    ./shell.nix
    ./git.nix
    ./neovim.nix
  ];

  xdg.configFile = {
    "wezterm".source = link "wezterm"; # wallpapers go in wezterm/backdrops (gitignored)
    "nvim".source = link "nvim";
    "fastfetch".source = link "fastfetch";
  };
}

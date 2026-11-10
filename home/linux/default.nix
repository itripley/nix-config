# olivia's apps on any x86_64 Linux: the NixOS desktop (home/olivia), NixOS-WSL (hosts/wsl) and
# other distros (standalone home-manager, flake.nix). Plasma, Flatpak and the WARP tray need
# NixOS and stay in home/olivia.
{ config, ... }:
{
  imports = [
    ../shared
    ../olivia/apps.nix
    ../olivia/dev.nix
    ../olivia/firefox.nix
    ../olivia/obsidian.nix
    ../olivia/mpv.nix
    ../olivia/easyeffects.nix
  ];

  # Licensed fonts (TX-02 for WezTerm and Obsidian), kept out of git: dotfiles/fonts is gitignored.
  # A live link into the checkout (~/nixos-config), like the shared dotfiles.
  xdg.dataFile."fonts/nixos-config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/home/olivia/dotfiles/fonts";
}

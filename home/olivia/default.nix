# olivia on a NixOS PC (desktop.nix): the Linux apps plus what needs NixOS underneath
{
  imports = [
    ../linux # shared CLI/dotfiles + apps, dev, Firefox, Obsidian, mpv, EasyEffects, fonts
    ./plasma.nix
    ./flatpak.nix
    ./warp-gui.nix
  ];

  home.username = "olivia";
  home.homeDirectory = "/home/olivia";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}

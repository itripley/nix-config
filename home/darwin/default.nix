# home-manager for olivi on macbook-olivia (the Mac's username; the NixOS user is olivia)
{
  imports = [
    ../shared
    ./cli.nix
  ];

  home.username = "olivi";
  home.homeDirectory = "/Users/olivi";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}

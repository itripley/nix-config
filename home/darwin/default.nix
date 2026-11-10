# home-manager for the Mac user (olivi on macbook-olivia). The username and home come from the
# host's users.users (nix-darwin), or from flake.nix for standalone home-manager.
{
  imports = [
    ../shared
    ./cli.nix
    ./shell.nix
    ./git.nix
  ];

  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}

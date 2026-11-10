{ pkgs, ... }:
{
  programs.fish = {
    enable = true; # WezTerm's launch config starts `fish -l`
    functions.fish_greeting = "pokemon-colorscripts -r"; # Fedora's greeting
  };
  home.packages = [ pkgs.pokemon-colorscripts ];

  # Fedora had these on PATH (cargo installs, go installs)
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
  ];
}

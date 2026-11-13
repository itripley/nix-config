{ pkgs, ... }:
{
  programs.fish = {
    enable = true; # WezTerm's launch config starts `fish -l`
    functions.fish_greeting = "krabby random 1-4 --no-mega --no-gmax --no-regional"; # gens 1-4, base forms; 1/128 shiny
  };
  home.packages = [ pkgs.krabby ];

  # Fedora had these on PATH (cargo installs, go installs)
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
  ];
}

# Standalone home-manager on a machine whose OS this repo doesn't manage (flake.nix
# homeConfigurations): `home-manager switch --flake ~/nixos-config#<user>@<system>`.
# The user, home directory and the Linux target settings come from flake.nix.
{ lib, ... }:
{
  home.stateVersion = lib.mkDefault "26.05";
  programs.home-manager.enable = true; # the home-manager command, for later switches
}

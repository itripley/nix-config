# Packages defined in this repo (pkgs/), added to the stable package set as pkgs.<name>.
# Also exposed as flake outputs: `nix build .#<name>`.
final: _prev: {
  warp-cloudflare-gui = final.callPackage ../pkgs/warp-cloudflare-gui/package.nix { };
}

# Packages defined in this repo (pkgs/), added to the stable package set as pkgs.<name>.
# Also exposed as flake outputs: `nix build .#<name>`.
final: _prev: {
  warp-cloudflare-gui = final.callPackage ../pkgs/warp-cloudflare-gui/package.nix { };
  obsidian-plugins = final.callPackage ../pkgs/obsidian-plugins/package.nix { };
  vscode-marketplace = final.callPackage ../pkgs/vscode-marketplace/package.nix { };
  # Built from unstable: needs Qt 6.12 (stable has 6.11), and Quickshell must match that Qt
  pond-interface = final.unstable.callPackage ../pkgs/pond-interface/package.nix { };
}

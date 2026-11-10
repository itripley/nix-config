# What every Mac gets (nix-darwin): Homebrew apps, macOS defaults, Touch ID sudo, Nix settings
{ inputs, pkgs, ... }:
{
  imports = [
    ./homebrew.nix
    ./defaults.nix
  ];

  # Touch ID for sudo, also inside tmux (pam_reattach)
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Into /Library/Fonts/Nix Fonts. WezTerm's icon fallback, as on the desktop (desktop.nix)
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # fish for WezTerm at a stable path (/run/current-system/sw/bin/fish), with the Nix environment
  programs.fish.enable = true;
  # macOS's own zsh prompt, instead of nix-darwin's default
  programs.zsh.promptInit = ''PS1="%n@%m %1~ %# "'';

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # trusted-users stays at the default (root only), as on the desktop
  };
  # No legacy channels: <nixpkgs> and `nix shell nixpkgs#…` resolve to this flake's nixpkgs
  nix.channel.enable = false;

  # Weekly (Sunday 03:15): drop generations older than 14 days and collect garbage
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  # Weekly (Sunday 04:15) store dedup, instead of auto-optimise-store (DESIGN §11)
  nix.optimise.automatic = true;

  # `darwin-version` shows which commit a generation was built from
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
}

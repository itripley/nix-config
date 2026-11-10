{ inputs, pkgs, ... }:
{
  imports = [
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/defaults.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin"; # Apple M1

  networking.hostName = "macbook-olivia";
  networking.computerName = "macbook-olivia";

  # nix-darwin applies user-level settings (homebrew, system.defaults) to this user
  system.primaryUser = "olivi";
  # The existing macOS account; home-manager reads its home from here
  users.users.olivi.home = "/Users/olivi";

  # Touch ID for sudo, also inside tmux (pam_reattach)
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
  # The hand-written file it replaces (just pam_tid.so); renamed to .before-nix-darwin on switch
  environment.etc."pam.d/sudo_local".knownSha256Hashes = [
    "5bef9b2acbc58dfbb2ae23eca69788ab2c75b8368a33810625a0ba7fe46dc433"
  ];

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

  # `darwin-version` shows which commit a generation was built from
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  system.stateVersion = 7;
}

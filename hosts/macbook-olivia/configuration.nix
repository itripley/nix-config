{ inputs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin"; # Apple M1

  networking.hostName = "macbook-olivia";
  networking.computerName = "macbook-olivia";

  # nix-darwin applies user-level settings (homebrew, system.defaults) to this user
  system.primaryUser = "olivi";

  # Leave the hand-written /etc/pam.d/sudo_local (Touch ID) alone for now
  security.pam.services.sudo_local.enable = false;

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

{
  imports = [ ../../modules/darwin/common.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin"; # Apple M1

  networking.hostName = "macbook-olivia";
  networking.computerName = "macbook-olivia";

  # nix-darwin applies user-level settings (homebrew, system.defaults) to this user
  system.primaryUser = "olivi";
  # The existing macOS account; home-manager reads its home from here
  users.users.olivi.home = "/Users/olivi";
  home-manager.users.olivi = import ../../home/darwin;

  # The hand-written file the Touch ID setting (common.nix) replaced (just pam_tid.so);
  # renamed to .before-nix-darwin on switch
  environment.etc."pam.d/sudo_local".knownSha256Hashes = [
    "5bef9b2acbc58dfbb2ae23eca69788ab2c75b8368a33810625a0ba7fe46dc433"
  ];

  system.stateVersion = 7;
}

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/amd.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/login-art.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/storage.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/services.nix
    ./machine.nix
  ];

  networking.hostName = "desktop-olivia";

  system.stateVersion = "26.05";
}

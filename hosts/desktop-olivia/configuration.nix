{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/amd.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/storage.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/services.nix
  ];

  networking.hostName = "desktop-olivia";

  users.users.olivia = {
    isNormalUser = true;
    uid = 1000; # storage.nix mounts SMB/NTFS as uid 1000
    description = "Olivia";
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "docker"
      "libvirtd"
      "gamemode"
      "i2c"
    ];
  };
  programs.fish.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # `nh os switch` / `nh os boot` — nicer nixos-rebuild, plus automatic GC
  programs.nh = {
    enable = true;
    flake = "/home/olivia/nixos-config";
    clean = {
      enable = true;
      extraArgs = "--keep 10 --keep-since 14d";
    };
  };

  # Lets unpatched binaries run (Mason LSPs in LazyVim, VS Code server, downloaded tools)
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    pciutils
    usbutils
  ];

  system.stateVersion = "26.05";
}

{ config, pkgs, ... }:
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
    uid = 1000; # fixed, so files on the SMB/NTFS mounts (storage.nix) keep their owner
    description = "Olivia";
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "docker"
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
    # trusted-users stays at the default (root only). Don't add @wheel: a trusted user can set
    # substituters/build hooks, i.e. become root without sudo's password. nh goes through sudo.
  };
  # No legacy channels: <nixpkgs> and `nix shell nixpkgs#…` resolve to this flake's nixpkgs
  # (nix.registry / nix.nixPath are pinned by nixosSystem).
  nix.channel.enable = false;

  # `nh os switch` / `nh os boot` — nicer nixos-rebuild, plus automatic GC
  programs.nh = {
    enable = true;
    # The checkout. Also where home-manager's live dotfile links point (osConfig.programs.nh.flake)
    flake = "${config.users.users.olivia.home}/nixos-config";
    clean = {
      enable = true;
      extraArgs = "--keep 10 --keep-since 14d";
    };
  };

  # Lets unpatched binaries run (Mason LSPs in LazyVim, VS Code server, downloaded tools)
  programs.nix-ld.enable = true;

  # git and an editor come from home-manager for olivia (gitFull, neovim with vim/vi aliases);
  # root has nano. Nix fetches flakes without a git binary.
  environment.systemPackages = with pkgs; [
    wget
    curl
    pciutils
    usbutils
  ];

  system.stateVersion = "26.05";
}

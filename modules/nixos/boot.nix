{ lib, pkgs, ... }:
{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 15;
    consoleMode = "max";
    editor = false;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # Newest kernel for RDNA3 / Zen 4
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [
    "btrfs"
    "ntfs"
  ];

  # Windows keeps the RTC in local time; without this the clock jumps on every OS switch
  time.hardwareClockInLocalTime = true;

  hardware.enableRedistributableFirmware = true;
  zramSwap.enable = true;
  services.fstrim.enable = true;
  services.btrfs.autoScrub.enable = true;
  # `nixos-rebuild build-vm` swaps fileSystems for a non-btrfs disk, which trips autoScrub's
  # assertion. (`system.build.vmWithDisko` keeps the real btrfs layout and doesn't need this.)
  virtualisation.vmVariant.services.btrfs.autoScrub.enable = lib.mkForce false;
}

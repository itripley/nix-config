{ pkgs, ... }:
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
}

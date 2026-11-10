{
  config,
  lib,
  pkgs,
  ...
}:
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

  hardware.enableRedistributableFirmware = true;
  zramSwap.enable = true;
  services.fstrim.enable = true;
  # Only where there is btrfs (autoScrub asserts otherwise): not on an adopted ext4 install, nor
  # in `nixos-rebuild build-vm`, which swaps fileSystems for a plain disk
  services.btrfs.autoScrub.enable = lib.any (fs: fs.fsType == "btrfs") (
    lib.attrValues config.fileSystems
  );
}

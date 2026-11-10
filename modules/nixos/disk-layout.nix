# The desktop's disk layout (hosts/desktop-olivia/disko.nix) for new PCs: 1 GiB ESP, btrfs
# subvolumes for / /home /nix, a swapfile. The host sets only the disk, by id:
#   disko.devices.disk.main.device = "/dev/disk/by-id/…";
# The installed system mounts by partition label (disk-main-ESP, disk-main-root), not by device.
{ lib, ... }:
let
  btrfsMount = mountpoint: {
    inherit mountpoint;
    mountOptions = [
      "compress=zstd"
      "noatime"
    ];
  };
in
{
  disko.devices.disk.main = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "nixos"
            ];
            subvolumes = {
              "@" = btrfsMount "/";
              "@home" = btrfsMount "/home";
              "@nix" = btrfsMount "/nix";
              "@swap" = {
                mountpoint = "/.swapvol";
                swap.swapfile.size = lib.mkDefault "16G";
              };
            };
          };
        };
      };
    };
  };
}

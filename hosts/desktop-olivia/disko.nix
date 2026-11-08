# Partitions the Samsung 850 EVO ONLY. The Windows NVMe (Fanxiang S770) is never touched.
# Before running disko, confirm this path exists and is the 500GB Samsung:
#   ls -l /dev/disk/by-id/ | grep Samsung
{
  disko.devices.disk.nixos = {
    type = "disk";
    device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S3R3NF0J901761H";
    content = {
      type = "gpt";
      partitions = {
        # NixOS gets its own ESP; the Windows one is only 100MB, too small for kernels
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
              "@" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@swap" = {
                mountpoint = "/.swapvol";
                swap.swapfile.size = "16G";
              };
            };
          };
        };
      };
    };
  };
}

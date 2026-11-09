{ config, pkgs, ... }:
let
  # Files on SMB/NTFS mounts show up as owned by olivia (configuration.nix) and group users
  owner = [
    "uid=${toString config.users.users.olivia.uid}"
    "gid=${toString config.users.groups.users.gid}"
  ];

  # Same shares Windows maps as X:, Y:, Z:. Credentials live outside the repo:
  #   /etc/nixos/smb-secrets  (chmod 600)
  #     username=...
  #     password=...
  unraidShare = share: {
    device = "//192.168.1.65/${share}";
    fsType = "cifs";
    options = owner ++ [
      "credentials=/etc/nixos/smb-secrets"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };
in
{
  environment.systemPackages = [ pkgs.cifs-utils ];

  fileSystems."/mnt/unraid/appdata" = unraidShare "appdata";
  fileSystems."/mnt/unraid/downloads" = unraidShare "downloads";
  fileSystems."/mnt/unraid/files" = unraidShare "files";

  # Windows C: (Fanxiang NVMe), read-only. Needs Fast Startup disabled in Windows,
  # otherwise the volume is left "dirty" and ntfs3 refuses to mount it.
  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-partuuid/62cd18cb-2a2f-4de3-9849-fc529fea7536";
    fsType = "ntfs3";
    options = owner ++ [
      "ro"
      "noauto"
      "nofail"
      "x-systemd.automount"
    ];
  };
}

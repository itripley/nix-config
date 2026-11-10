{ config, pkgs, ... }:
let
  # Files on the SMB mounts show up as owned by olivia (common.nix) and group users
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

  # The desktop's Windows disk is mounted in hosts/desktop-olivia/machine.nix
}

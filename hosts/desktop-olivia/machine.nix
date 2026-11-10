# What only this PC has: the Windows NVMe next to it, and its RGB devices
{ config, ... }:
{
  # Windows keeps the RTC in local time; without this the clock jumps on every OS switch
  time.hardwareClockInLocalTime = true;

  # Windows C: (Fanxiang NVMe), read-only. Needs Fast Startup disabled in Windows,
  # otherwise the volume is left "dirty" and ntfs3 refuses to mount it.
  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-partuuid/62cd18cb-2a2f-4de3-9849-fc529fea7536";
    fsType = "ntfs3";
    options = [
      "uid=${toString config.users.users.olivia.uid}"
      "gid=${toString config.users.groups.users.gid}"
      "ro"
      "noauto"
      "nofail"
      "x-systemd.automount"
    ];
  };

  # RGB (Windows used OpenRGB + PawnIO for SMBus; here it's i2c-piix4)
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  # The Windows "lowpink" profile as CLI calls: RAM and board off, mouse pink.
  # The profile file itself matches devices by their Windows paths (MODULES `machine.nix`).
  systemd.services.openrgb-colors = {
    description = "Apply the lowpink RGB colors";
    after = [ "openrgb.service" ];
    requires = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.hardware.openrgb.package ];
    serviceConfig.Type = "oneshot";
    # --nodetect: talk to the running server only, never probe the hardware from here
    script = ''
      for _ in $(seq 30); do
        openrgb --nodetect --list-devices | grep -q Basilisk && break
        sleep 1
      done
      openrgb --nodetect --mode direct --color 000000
      openrgb --nodetect --device Basilisk --mode direct --color B29393
    '';
  };
}

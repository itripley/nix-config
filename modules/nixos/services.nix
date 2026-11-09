{ config, pkgs, ... }:
{
  virtualisation.docker.enable = true;

  # Local LLMs on the 7800 XT (gfx1101 is a supported ROCm target)
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
  };

  # RGB (Windows used OpenRGB + PawnIO for SMBus; here it's i2c-piix4)
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  # The Windows "lowpink" profile as CLI calls: RAM and board off, mouse pink.
  # The profile file itself matches devices by their Windows paths (MODULES `services.nix`).
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

  # mDNS / .local discovery (replaces Apple Bonjour)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}

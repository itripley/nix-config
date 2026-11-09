{ pkgs, ... }:
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

  # mDNS / .local discovery (replaces Apple Bonjour)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}

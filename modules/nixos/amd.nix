# Ryzen 7 7700X + Radeon RX 7800 XT (gfx1101)
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / Proton / Wine
  };

  hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true; # ROCm OpenCL for DaVinci Resolve
  };

  # LACT: fan curves, power limits, clocks (replaces AMD Software / Adrenalin)
  services.lact.enable = true;

  # DDC/CI so Plasma can control monitor brightness (replaces Twinkle Tray)
  hardware.i2c.enable = true;

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
    clinfo
    ddcutil
  ];
}

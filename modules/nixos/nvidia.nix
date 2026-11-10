# NVIDIA GPUs, proprietary driver. bootstrap.sh adds it when it finds one.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Selects the driver; also on Wayland, where X itself isn't running
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / Proton / Wine
  };

  hardware.nvidia = {
    # Open kernel modules: Turing (GTX 16xx / RTX 20xx) and newer. Older cards need false.
    open = true;
    modesetting.enable = true; # Plasma on Wayland needs it
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # The driver often trails linuxPackages_latest (boot.nix); the default kernel is what it supports
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
}

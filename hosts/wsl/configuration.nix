# NixOS inside WSL, on any Windows machine (NixOS-WSL). No hardware config: WSL provides the
# kernel, disk and boot. Installed by scripts/bootstrap.ps1; GUI apps run through WSLg.
{ inputs, lib, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../../modules/nixos/common.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "olivia";
    useWindowsDriver = true; # GPU acceleration through the Windows driver (d3d12)
    startMenuLaunchers = true; # Linux GUI apps show up in the Windows Start menu
  };
  hardware.graphics.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "wsl";

  home-manager.users.olivia = {
    imports = [ ../../home/linux ];
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
    # No PipeWire inside WSL (WSLg's audio is a PulseAudio socket)
    services.easyeffects.enable = lib.mkForce false;
  };

  system.stateVersion = "26.05";
}

# home-manager modules shared by both hosts. Platform-specific config stays in
# home/olivia (NixOS) and home/darwin (macOS).
{
  imports = [
    ./cli.nix
  ];
}

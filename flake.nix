{
  description = "NixOS config for desktop-olivia (dual-boot with Windows 11)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      plasma-manager,
      disko,
      nix-flatpak,
      ...
    }@inputs:
    let
      # Workarounds for packages that don't build in the pinned nixpkgs
      buildFixes = import ./overlays/build-fixes.nix;

      # Fast-moving tools (AI CLIs etc.) come from unstable as pkgs.unstable.<name>
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
          overlays = [ buildFixes ];
        };
      };
    in
    {
      nixosConfigurations.desktop-olivia = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.overlays = [
              buildFixes
              unstableOverlay
            ];
            nixpkgs.config.allowUnfree = true;
            # Only needed by Sublime Text 4 (still links the EOL OpenSSL 1.1).
            # Remove together with sublime4 in home/olivia/apps.nix.
            nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
          }
          disko.nixosModules.disko
          ./hosts/desktop-olivia/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { inherit inputs; };
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
              users.olivia = import ./home/olivia;
            };
          }
        ];
      };
    };
}

# Apps with no usable nixpkgs package, installed declaratively from Flathub.
# Empty for now: nix-flatpak still uninstalls what it installed before (JDownloader, Stremio).
{ ... }:
{
  services.flatpak = {
    packages = [ ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}

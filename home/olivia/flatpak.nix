# Apps with no usable nixpkgs package, installed declaratively from Flathub
{ ... }:
{
  services.flatpak = {
    packages = [
      "org.jdownloader.JDownloader"
      "com.stremio.Stremio"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}

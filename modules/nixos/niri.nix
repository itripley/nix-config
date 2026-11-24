# Second desktop: niri with Pond's interface (pkgs/pond-interface), next to Plasma. Pick "Niri" in
# SDDM's session menu when logging in; log out of Plasma first (one desktop at a time per account).
{ lib, pkgs, ... }:
{
  programs.niri.enable = true;

  # olivia: same apps, logins and files as in Plasma. home/pond only runs under niri.
  home-manager.users.olivia.imports = [ ../../home/pond ];

  # GVfs for Nautilus: drives, trash, network. Only its services, started on request; the GIO module
  # that makes apps ask for them is set for Nautilus alone (home/pond), so Plasma doesn't load it.
  services.dbus.packages = [ pkgs.gnome.gvfs ];
  systemd.packages = [ pkgs.gnome.gvfs ];

  # The niri module turns GNOME Keyring on; its PAM hook would also start it in olivia's Plasma
  # logins, next to KWallet. KWallet serves both desktops instead.
  services.gnome.gnome-keyring.enable = false;
  xdg.portal.config.niri."org.freedesktop.impl.portal.Secret" = lib.mkForce "kwallet";
}

# Consumer WARP on/off toggle in the tray. WARP's own tray app (warp-taskbar) only supports Zero
# Trust teams: with a free registration it opens a team-name sign-in screen and has no switch.
# The app itself is packaged in pkgs/warp-cloudflare-gui (github.com/mrmoein/warp-cloudflare-gui).
{ pkgs, osConfig, ... }:
let
  # Same warp-cli as the system daemon (services.cloudflare-warp in networking.nix)
  warp-cloudflare-gui = pkgs.warp-cloudflare-gui.override {
    cloudflare-warp = osConfig.services.cloudflare-warp.package;
  };
in
{
  home.packages = [ warp-cloudflare-gui ];

  xdg.configFile = {
    # Start at login as a tray icon only (--hide); right-click → Hide / Show opens the window.
    "autostart/warp-cloudflare-gui.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Cloudflare WARP (tray)
      Exec=${warp-cloudflare-gui}/bin/warp-cloudflare-gui --hide
      Icon=warp-cloudflare-gui
      Terminal=false
    '';
    # Stop warp-taskbar autostarting (its entry is in /etc/xdg/autostart). A user file with the
    # same name overrides it; Hidden=true means "don't run". Otherwise there are two WARP icons.
    "autostart/com.cloudflare.WarpTaskbar.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Cloudflare Zero Trust
      Hidden=true
    '';
  };
}

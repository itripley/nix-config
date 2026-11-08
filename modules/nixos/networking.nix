{ pkgs, ... }:
{
  networking.networkmanager = {
    enable = true;
    # The router's DNS rebind protection breaks *.plex.direct (LAN Plex over TLS).
    # Windows works around it with static 1.1.1.1; do the same here.
    insertNameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    plugins = [ pkgs.networkmanager-openvpn ]; # PrivadoVPN: import its OpenVPN/WireGuard configs
  };

  # Public DNS doesn't know the Unraid box's NetBIOS name
  networking.hosts."192.168.1.65" = [
    "unraid-olivia"
    "UNRAID-OLIVIA"
  ];

  services.netbird.enable = true;
  # Self-hosted management server (same as the Windows client). Merged into
  # /var/lib/netbird/config.json on every start, so `netbird up` logs in there
  # instead of NetBird's cloud. NetBird stores the URL as Go's url.URL object.
  services.netbird.clients.default.config.ManagementURL = {
    Scheme = "https";
    Host = "netbird.weblivia.dev:443";
  };
  services.cloudflare-warp.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53317 # LocalSend
      3000 # plex-mpv-shim HTTP
    ];
    allowedUDPPorts = [
      53317 # LocalSend
      32410 # Plex GDM discovery
      32412
      32413
      32414
    ];
  };
}

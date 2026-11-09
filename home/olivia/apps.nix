# Windows → Linux app mapping. See docs/MIGRATION.md for the full table.
{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Browsers (Firefox is configured in firefox.nix)
    chromium

    # From the old Fedora install
    ulauncher # launcher on Meta+Space (started by plasma.nix)
    btop
    high-tide # TIDAL client (was a Flatpak)
    pokemon-colorscripts # fish greeting (default.nix)

    # Chat & social
    # Serein, native Discord client (flake input). nixpkgs-unstable's cargoUseSystemLibs hook
    # forces a system AWS-LC that isn't there; opt out so it builds the vendored one.
    (inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
      dontCargoUseSystemLibs = true;
    })
    legcord

    # Productivity
    bitwarden-desktop
    obsidian
    sublime4
    termius

    # Creative: image / video / 3D
    pkgsRocm.blender # HIP render on the 7800 XT
    davinci-resolve # Premiere / Avid
    obs-studio

    # Audio / music production
    qpwgraph # PipeWire patchbay (Voicemeeter routing)

    # Playback & media
    mpv # MPC-BE + madVR + LAV
    mpc-qt
    plex-desktop
    plexamp
    plex-mpv-shim
    tidal-hifi
    pear-desktop
    ffmpeg-full
    yt-dlp
    qbittorrent

    # Games
    prismlauncher
    heroic # Epic / GOG / Amazon
    lutris # Ubisoft / EA
    protonplus

    # Windows-utility replacements
    fsearch # Everything
    flameshot # ShareX (Spectacle is built in too)
    localsend
    croc
    _7zz
    # NetBird tray app comes from services.netbird (networking.nix), wrapped for its socket

    # AI
    unstable.claude-code
  ];
}

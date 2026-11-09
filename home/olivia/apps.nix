# Windows → Linux app mapping. See docs/MIGRATION.md for the full table.
{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Browsers (Firefox is configured in firefox.nix)
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    chromium

    # From the old Fedora install
    ulauncher # launcher on Meta+Space (started by plasma.nix)
    thunar # file manager on Meta+F
    btop
    w3m # terminal browser (with images in WezTerm)
    unstable.ente-desktop # Ente Photos (stable 1.7.22 needs EOL Electron 41)
    high-tide # TIDAL client (was a Flatpak)
    gnome-boxes # VMs (libvirtd in services.nix)
    distrobox # containers via Docker
    distroshelf # distrobox GUI (was a Flatpak)
    warehouse # Flatpak manager GUI (was a Flatpak)
    pokemon-colorscripts # fish greeting (default.nix)

    # Chat & social
    # Serein, native Discord client (flake input). Same fix as codex in overlays/build-fixes.nix:
    # nixpkgs' cargoUseSystemLibs hook forces a system AWS-LC that isn't there.
    (inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
      dontCargoUseSystemLibs = true;
    })
    signal-desktop
    vesktop
    legcord
    element-desktop
    cinny-desktop
    dissent

    # Productivity
    bitwarden-desktop
    obsidian
    sublime4
    termius
    figma-linux

    # Creative: image / video / 3D
    krita # Clip Studio / Photoshop
    gimp
    pinta # paint.net
    pkgsRocm.blender # HIP render on the 7800 XT
    davinci-resolve # Premiere / Avid
    kdePackages.kdenlive
    obs-studio
    losslesscut-bin
    xnviewmp

    # Audio / music production
    audacity
    renoise # FL Studio replacement (already licensed)
    vcv-rack
    cardinal
    plugdata
    yabridge # Windows VST2/VST3 plugins through Wine
    yabridgectl
    qpwgraph # PipeWire patchbay (Voicemeeter routing)

    # Playback & media
    mpv # MPC-BE + madVR + LAV
    mpc-qt
    plex-desktop
    plexamp
    plex-mpv-shim
    feishin
    tidal-hifi
    pear-desktop
    makemkv
    mediainfo-gui
    ffmpeg-full
    yt-dlp
    get_iplayer
    qbittorrent

    # Games
    prismlauncher
    heroic # Epic / GOG / Amazon
    lutris # Ubisoft / EA
    protonplus
    mangohud
    bottles
    wineWow64Packages.stable # plain Wine + winetricks, as on Fedora
    winetricks

    # Windows-utility replacements
    fsearch # Everything
    flameshot # ShareX (Spectacle is built in too)
    kdePackages.filelight # WinDirStat
    impression # Rufus / balenaEtcher
    yacreader # CDisplayEx
    activitywatch
    localsend
    croc
    _7zz
    unrar
    innoextract # innounp
    # NetBird tray app comes from services.netbird (networking.nix), wrapped for its socket

    # AI
    lmstudio
    unstable.claude-code
    unstable.codex
    unstable.opencode
  ];
}

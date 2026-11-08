# Windows → Linux app mapping. See docs/MIGRATION.md for the full table.
{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Browsers (Firefox is configured in firefox.nix)
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    chromium

    # Chat & social
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

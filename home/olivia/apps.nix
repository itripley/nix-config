# Windows → Linux app mapping. See docs/MIGRATION.md for the full table.
{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Browsers: Firefox in firefox.nix, Chromium below (programs.chromium)

    # From the old Fedora install (btop, pokemon-colorscripts: home/shared/)
    high-tide # TIDAL client (was a Flatpak)

    # Chat & social
    # Serein, native Discord client (flake input). nixpkgs-unstable's cargoUseSystemLibs hook
    # forces a system AWS-LC that isn't there; opt out so it builds the vendored one.
    # postPatch lowers the hard-coded 760x520 minimum window size.
    (inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      dontCargoUseSystemLibs = true;
      postPatch = (old.postPatch or "") + ''
        substituteInPlace apps/desktop/src/app_settings.rs \
          --replace-fail 'MIN_WINDOW_SIZE: [u32; 2] = [760, 520];' \
                         'MIN_WINDOW_SIZE: [u32; 2] = [400, 300];'
      '';
    }))
    legcord

    # Productivity
    bitwarden-desktop
    # Obsidian: obsidian.nix (programs.obsidian, with the vault's plugins)
    sublime4
    termius

    # Creative: image / video / 3D
    pkgsRocm.blender # HIP render on the 7800 XT
    davinci-resolve # Premiere / Avid
    # OBS: programs.obs-studio below

    # Audio / music production
    qpwgraph # PipeWire patchbay (Voicemeeter routing)

    # Playback & media
    # mpv (MPC-BE + madVR + LAV): mpv.nix
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
    # Java 21 (Minecraft 1.20.5+) and 25 only; the default also bundles 8 and 17 (~0.7 GiB) for
    # 1.16 and older. Add jdk17 / jdk8 back here for those versions.
    (prismlauncher.override {
      jdks = [
        jdk25
        jdk21
      ];
    })
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
    # Claude Desktop (flake input): Anthropic's .deb, run with --no-sandbox (no setuid in the store)
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Extensions Helium had on Windows; Chromium fetches them from the Web Store
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; } # Claude
    ];
  };

  # Image Reaction, the third Windows plugin, isn't in nixpkgs
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-scale-to-sound
    ];
  };
}

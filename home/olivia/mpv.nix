# mpv and plex-mpv-shim settings, from the Windows configs (MODULES `mpv.nix`)
_: {
  programs.mpv = {
    enable = true;
    defaultProfiles = [ "high-quality" ]; # written first, so the options below override it
    config = {
      # Video output & decoding
      vo = "gpu-next";
      hwdec = "auto";

      # General
      save-position-on-quit = "no";
      fullscreen = "no";
      keep-open = "always";
      reset-on-next-file = "pause";
      force-seekable = "yes";

      # Language priority
      alang = "ja,en";
      slang = "en";

      # Screenshots
      screenshot-directory = "~/Pictures/mpv-screenshots";
      screenshot-template = "%f-%wH.%wM.%wS.%wT";
      screenshot-format = "webp";
      screenshot-high-bit-depth = "yes";
      screenshot-tag-colorspace = "yes";
      screenshot-png-compression = 7;
      screenshot-jpeg-quality = 90;
      screenshot-webp-lossless = "yes";
      screenshot-webp-quality = 75;
      screenshot-avif-encoder = "libaom-av1";
      screenshot-avif-pixfmt = "yuv420p";
      screenshot-avif-opts = "usage=allintra";
      screenshot-jxl-distance = 1.0;

      # OSD and OSC
      osd-bar = "yes";
      osc = "yes";
      border = "yes";
      cursor-autohide-fs-only = "yes";
      cursor-autohide = 300;
      osd-level = 1;
      osd-duration = 1000;
      hr-seek = "yes";
      osd-font = "Verdana"; # corefonts
      osd-font-size = 20;
      osd-color = "#FFFFFF";
      osd-border-color = "#000000";
      osd-border-size = 0.6;
      osd-blur = 0.2;
      osd-status-msg = "\${playback-time/full} / \${duration} (\${percent-pos}%)\\nframe: \${estimated-frame-number} / \${estimated-frame-count}";

      # Audio
      volume = 100;
      volume-max = 200;
      audio-file-auto = "fuzzy";
      audio-pitch-correction = "yes";

      # Scalers
      scale = "ewa_lanczossharp";
      dscale = "mitchell";
      cscale = "ewa_lanczossoft";

      # Debanding (off by default, `b` toggles it)
      deband = "no";
      deband-iterations = 2;
      deband-threshold = 64;
      deband-range = 17;
      deband-grain = 12;

      # Subtitles
      demuxer-mkv-subtitle-preroll = "yes";
      sub-ass-use-video-data = "all";
      sub-fix-timing = "no";
      sub-auto = "fuzzy";
      sub-font-size = 40;
      sub-color = "#FFFFFFFF";
      sub-border-color = "#FF000000";
      sub-border-size = 2.0;
      sub-shadow-offset = 0;
      sub-spacing = 0.0;
    };
    profiles.WEB-DL = {
      profile-desc = "WEB-DL Anime (HatSubs, SubsPlease, HorribleSubs, Erai-raws)";
      profile-cond = ''string.match(p.filename, "HatSubs")~=nil or string.match(p.filename, "SubsPlease")~=nil or string.match(p.filename, "HorribleSubs")~=nil or string.match(p.filename, "Erai%-raws")~=nil'';
      profile-restore = "copy-equal";
      deband = "yes";
    };
    bindings = {
      WHEEL_UP = "add volume 2";
      WHEEL_DOWN = "add volume -2";
    };
  };

  # plex-mpv-shim reads mpv.conf from its own folder. conf.json holds the Plex login and is
  # rewritten by the shim, so it stays unmanaged (OPERATIONS "plex-mpv-shim").
  xdg.configFile."plex-mpv-shim/mpv.conf".source = ./plex-mpv-shim/mpv.conf;
}

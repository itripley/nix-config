{ lib, ... }:
let
  # Voicemeeter replacement: each virtual device is a sink that forwards to the
  # default output, so apps can be routed (and volume-controlled) per bus from
  # the Plasma volume applet. Use qpwgraph for anything fancier.
  virtualSink = name: {
    name = "libpipewire-module-loopback";
    args = {
      "node.description" = name;
      "capture.props" = {
        "node.name" = "virtual_${lib.toLower name}";
        "media.class" = "Audio/Sink";
        "audio.position" = [
          "FL"
          "FR"
        ];
      };
      "playback.props" = {
        "node.name" = "virtual_${lib.toLower name}_out";
        "node.passive" = true;
        "audio.position" = [
          "FL"
          "FR"
        ];
      };
    };
  };
in
{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Idle hiss/static on the onboard analog out: keep the codec powered (applies after a reboot)
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
  '';

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # for JACK apps (DAWs, synths)

    # Same static: never suspend the onboard analog out when it goes quiet
    wireplumber.extraConfig."51-analog-no-suspend"."monitor.alsa.rules" = [
      {
        matches = [ { "node.name" = "~alsa_output.pci-0000_0e_00.6.*"; } ];
        actions.update-props."session.suspend-timeout-seconds" = 0;
      }
    ];

    extraConfig.pipewire = {
      # Low enough for music production, can go to 64 when an app asks for it
      "10-low-latency"."context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [
          44100
          48000
          96000
        ];
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 2048;
      };
      "20-virtual-sinks"."context.modules" = map virtualSink [
        "Game"
        "Music"
        "Chat"
      ];
    };
  };
}

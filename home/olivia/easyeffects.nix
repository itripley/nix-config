# EasyEffects and its presets
{ lib, ... }:
let
  # oratory1990's AirPods Max EQ (ANC on or Transparency, v2.9, 09.02.22): type, Hz, dB, Q
  airpodsMaxBands = [
    [
      "Bell"
      17
      (-2.8)
      0.8
    ]
    [
      "Lo-shelf"
      105
      0.0
      0.71
    ]
    [
      "Bell"
      210
      (-1.5)
      1.5
    ]
    [
      "Bell"
      1200
      (-2.4)
      1.4
    ]
    [
      "Hi-shelf"
      1300
      4.5
      0.71
    ]
    [
      "Bell"
      2900
      (-0.8)
      5.0
    ]
    [
      "Bell"
      4920
      (-2.5)
      6.0
    ]
    [
      "Bell"
      6300
      (-1.0)
      6.0
    ]
    [
      "Bell"
      8450
      (-2.0)
      7.0
    ]
    [
      "Hi-shelf"
      11000
      (-9.0)
      0.71
    ]
  ];

  band = b: {
    type = builtins.elemAt b 0;
    frequency = builtins.elemAt b 1 * 1.0;
    gain = builtins.elemAt b 2;
    q = builtins.elemAt b 3;
    mode = "APO (DR)"; # same filter maths as Equalizer APO, which these values are written for
    slope = "x1";
    width = 4.0;
    mute = false;
    solo = false;
  };

  channel = lib.listToAttrs (
    lib.imap0 (i: b: lib.nameValuePair "band${toString i}" (band b)) airpodsMaxBands
  );
in
{
  # Mic noise suppression (RNNoise) and EQ: replaces NVIDIA Broadcast / AMD Noise Suppression
  services.easyeffects = {
    enable = true;

    # ~/.local/share/easyeffects/output/<name>.json (read-only store links)
    extraPresets."Apple AirPods Max (oratory1990)".output = {
      blocklist = [ ];
      plugins_order = [ "equalizer#0" ];
      "equalizer#0" = {
        bypass = false;
        input-gain = -4.0; # the PDF's preamp
        output-gain = 0.0;
        mode = "IIR";
        num-bands = builtins.length airpodsMaxBands;
        split-channels = false;
        balance = 0.0;
        pitch-left = 0.0;
        pitch-right = 0.0;
        left = channel;
        right = channel;
      };
    };
  };
}

# Pond's desktop layer (bflycomputer/pond-interface, BSD-3-Clause, Butterfly Interaction Inc.):
# the Quickshell shell, lock screen, wallpaper and niri config, with /usr paths moved to the
# store. Built from pkgs.unstable (overlays/packages.nix): its native QML module needs Qt 6.12.
# `qs` here is Quickshell wrapped with what the shell runs (python helpers, nmcli, pactl, ...).
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
  pkg-config,
  makeWrapper,
  qt6,
  kdePackages,
  wayland,
  quickshell,
  python3,
  glib,
  networkmanager,
  iw,
  pulseaudio,
  brightnessctl,
  ddcutil,
  zenity,
  wl-clipboard,
  fastfetch,
  getent,
  coreutils,
  gnugrep,
  bash,
  xkeyboard_config,
  tzdata,
  launcher ? null, # Pond's Vicinae fork (home/pond); without it, `vicinae` from PATH
}:
let
  # Fonts the shell asks for by name, from google/fonts (the commit Pond's Arch port pins)
  fontsCommit = "4c1db3aec83c67dd223dd82a68c039cab30917a9";
  googleFont =
    name: path: hash:
    fetchurl {
      inherit name hash;
      url = "https://raw.githubusercontent.com/google/fonts/${fontsCommit}/ofl/${path}";
    };
  onest =
    googleFont "Onest.ttf" "onest/Onest%5Bwght%5D.ttf"
      "sha256-lmxcKbR1XahLaFTVwh3U6qJCAiXQ6YdN5gLeF21KnzE=";
  adventPro =
    googleFont "AdventPro.ttf" "adventpro/AdventPro%5Bwdth,wght%5D.ttf"
      "sha256-tgqykguJvcS32t+ygsraxuA4M+eoCET56sCWNZsrl2Y=";

  pythonEnv = python3.withPackages (ps: [
    ps.pygobject3
    ps.pyqt6
  ]);

  runtimePath = [
    pythonEnv
    networkmanager
    iw
    pulseaudio # pactl (talks to PipeWire's pulse server)
    brightnessctl
    ddcutil
    zenity
    wl-clipboard
    fastfetch
    getent
    coreutils
    gnugrep
    bash
  ]
  ++ lib.optional (launcher != null) launcher;
  vicinae = if launcher == null then "vicinae" else lib.getExe' launcher "vicinae";
in
stdenv.mkDerivation {
  pname = "pond-interface";
  version = "0-unstable-2026-11-20";

  src = fetchFromGitHub {
    owner = "bflycomputer";
    repo = "pond-interface";
    rev = "7825829b44dea6a6a0fba1c3d1c5440bec1e00ed";
    hash = "sha256-KiI32YFJHWS+ViRZNOJgjcxsVdeGUxw/LE3kEssSDiE=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper
  ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    kdePackages.networkmanager-qt
    networkmanager # libnm, for networkmanager-qt's CMake config
    glib
    wayland
  ];

  # Two separate CMake projects, built by hand below; the QML plugins are loaded by Quickshell
  dontUseCmakeConfigure = true;
  dontWrapQtApps = true;
  # The helpers are run as `python3 <file>`; keep upstream's shebangs
  dontPatchShebangs = true;

  postPatch = ''
    # /usr/share/pond-interface -> the store
    grep -rlZ /usr/share/pond-interface . | xargs -0 sed -i "s#/usr/share/pond-interface#$out/share/pond-interface#g"
    # Absolute /usr/bin tools -> PATH (the qs wrapper, the session); the launcher by its full path
    grep -rlZ '/usr/bin/vicinae\b' . | xargs -0 sed -i -E 's#/usr/bin/vicinae\b#${vicinae}#g'
    grep -rlZE '/usr/bin/(qs|nmcli|iw|id|getent|systemctl|timedatectl)\b' . \
      | xargs -0 sed -i -E 's#/usr/bin/(qs|nmcli|iw|id|getent|systemctl|timedatectl)\b#\1#g'
    substituteInPlace shell/settings/system/control.py \
      --replace-fail /usr/share/X11/xkb/rules/ ${xkeyboard_config}/share/X11/xkb/rules/ \
      --replace-fail /usr/share/zoneinfo/zone.tab ${tzdata}/share/zoneinfo/zone.tab

    # Anything else under /usr would silently break at runtime: fail the build instead.
    # Left alone: /usr/bin/env shebangs, a python3 shebang (run via python3 anyway) and the
    # XDG_DATA_DIRS fallback in NiriMsg.qml (the session sets XDG_DATA_DIRS).
    if grep -rnE '/usr/' --include='*.qml' --include='*.js' --include='*.py' --include='*.kdl' --include='*.desktop' . \
        | grep -vE '#!/usr/bin/(env|python3)|"/usr/local/share:/usr/share"'; then
      echo "pond-interface: unhandled /usr path (above)" >&2
      exit 1
    fi
  '';

  buildPhase = ''
    runHook preBuild
    cmake -B build-system -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
    cmake --build build-system -j$NIX_BUILD_CORES
    cmake -B build-shot -S screenshot/native -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$out
    cmake --build build-shot -j$NIX_BUILD_CORES
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    share=$out/share/pond-interface
    qml=$out/lib/qt6/qml/Pond
    mkdir -p $share $qml
    cp -r shell lockscreen wallpaper screenshot config $share/
    rm -rf $share/screenshot/native
    find $share -name __pycache__ -type d -prune -exec rm -rf {} +

    # Pond.System: no install rule upstream, so copy the module dir and its backing library
    # (the plugin's RPATH is $ORIGIN)
    mkdir -p $qml/System
    cp -a build-system/Pond/System/. $qml/System/
    rm -f $qml/System/*.qrc
    find build-system -maxdepth 1 -name 'libpond_system*.so*' -exec cp -a {} $qml/System/ \;
    cmake --install build-shot # Pond.Screenshot.Native -> lib/qt6/qml/Pond/Screenshot/Native

    # Pure-QML modules stay in the share tree; link them onto the import path
    ln -s $share/wallpaper/desktop $qml/Wallpaper
    ln -s $share/wallpaper/daylight $qml/Daylight
    for f in qmldir State.qml Preview.qml clipboard.py assets; do
      ln -s $share/screenshot/$f $qml/Screenshot/$f
    done

    install -Dm644 config/applications/pond-manual.desktop $out/share/applications/pond-manual.desktop
    install -Dm644 ${onest} $out/share/fonts/truetype/Onest.ttf
    install -Dm644 ${adventPro} $out/share/fonts/truetype/AdventPro.ttf

    makeWrapper ${lib.getExe' quickshell "quickshell"} $out/bin/qs \
      --prefix PATH : $out/bin:${lib.makeBinPath runtimePath} \
      --prefix QML_IMPORT_PATH : $out/lib/qt6/qml \
      --prefix GI_TYPELIB_PATH : ${lib.getLib glib}/lib/girepository-1.0
    runHook postInstall
  '';

  passthru = { inherit pythonEnv; };

  meta = {
    description = "Pond's Quickshell desktop shell, lock screen, wallpaper and niri config";
    homepage = "https://github.com/bflycomputer/pond-interface";
    license = with lib.licenses; [
      bsd3
      ofl # Onest, Advent Pro
    ];
    platforms = lib.platforms.linux;
    mainProgram = "qs";
  };
}

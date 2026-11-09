# Consumer WARP on/off toggle: github.com/mrmoein/warp-cloudflare-gui, a small PyQt5 front end
# for warp-cli (connect / disconnect / status / registration show; nothing else). Upstream only
# ships an Ubuntu venv installer, so it's packaged here. Used by home/olivia/warp-gui.nix;
# build on its own with `nix build .#warp-cloudflare-gui`.
{
  lib,
  stdenv,
  python3,
  fetchFromGitHub,
  makeWrapper,
  qt5,
  # The GUI only shells out to `warp-cli`; pass the daemon's package so the CLI matches it
  cloudflare-warp,
}:
let
  # The animated toggle switch. Not in nixpkgs.
  qtwidgets = python3.pkgs.buildPythonPackage rec {
    pname = "qtwidgets";
    version = "1.1";
    pyproject = true;
    src = python3.pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-l7g3OER4iiLINvWhah5gye8Uab/ErtwJrnhvyaoLSd8=";
    };
    # colorbutton.py uses PyQt5 only if it's already imported, else hardcodes PySide2
    # (everything else goes through qtpy). Make that fallback qtpy too.
    postPatch = ''
      substituteInPlace qtwidgets/colorbutton/colorbutton.py \
        --replace-fail "from PySide2 import QtCore, QtGui, QtWidgets" "from qtpy import QtCore, QtGui, QtWidgets" \
        --replace-fail "from PySide2.QtCore import Qt, Signal" "from qtpy.QtCore import Qt, Signal"
    '';
    build-system = [ python3.pkgs.setuptools ];
    dependencies = with python3.pkgs; [
      markdown
      qtpy
      pyqt5
    ];
    pythonImportsCheck = [ "qtwidgets" ];
  };

  pythonEnv = python3.withPackages (ps: [
    ps.pyqt5
    ps.qtpy
    qtwidgets
  ]);
in
stdenv.mkDerivation {
  pname = "warp-cloudflare-gui";
  version = "0-unstable-2026-05-04";
  src = fetchFromGitHub {
    owner = "mrmoein";
    repo = "warp-cloudflare-gui";
    rev = "c2c8a7427a259eb6286165ecb7fa3a21cab4d4e1";
    hash = "sha256-eleiea/mBt7KicPdfLZ6mMkWZU2H2G5IAf/8iWRk88k=";
  };
  nativeBuildInputs = [
    makeWrapper
    qt5.wrapQtAppsHook
  ];
  buildInputs = [
    qt5.qtbase
    qt5.qtwayland
  ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    app=$out/share/warp-cloudflare-gui
    mkdir -p $app $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps
    cp -r main.py warp_gui icons $app/
    cp icons/logo.png $out/share/icons/hicolor/256x256/apps/warp-cloudflare-gui.png
    # main.py imports warp_gui from the current directory; it runs `warp-cli` via os.popen.
    makeWrapper ${pythonEnv}/bin/python $out/bin/warp-cloudflare-gui \
      --chdir $app --add-flags $app/main.py \
      --suffix PATH : ${lib.makeBinPath [ cloudflare-warp ]}
    cat > $out/share/applications/warp-cloudflare-gui.desktop <<DESKTOP
    [Desktop Entry]
    Type=Application
    Name=Cloudflare WARP
    Comment=Turn Cloudflare WARP on or off
    Exec=$out/bin/warp-cloudflare-gui
    Icon=warp-cloudflare-gui
    Terminal=false
    Categories=Network;
    DESKTOP
    runHook postInstall
  '';
  # wrapQtAppsHook wraps bin/ so PyQt5 finds the Qt platform plugins (Wayland/X11).

  meta = {
    description = "Tray toggle for consumer Cloudflare WARP (front end for warp-cli)";
    homepage = "https://github.com/mrmoein/warp-cloudflare-gui";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "warp-cloudflare-gui";
  };
}

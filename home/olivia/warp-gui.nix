# Consumer WARP on/off toggle. WARP's own tray app (warp-taskbar) only supports Zero Trust
# teams: with a free registration it opens a team-name sign-in screen and has no switch.
# This is github.com/mrmoein/warp-cloudflare-gui, a small PyQt5 front end for warp-cli
# (connect / disconnect / status / registration show; nothing else). Upstream only ships an
# Ubuntu venv installer, so it's packaged here instead.
{ pkgs, ... }:
let
  python = pkgs.python3;

  # The animated toggle switch. Not in nixpkgs.
  qtwidgets = python.pkgs.buildPythonPackage rec {
    pname = "qtwidgets";
    version = "1.1";
    pyproject = true;
    src = python.pkgs.fetchPypi {
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
    build-system = [ python.pkgs.setuptools ];
    dependencies = with python.pkgs; [
      markdown
      qtpy
      pyqt5
    ];
    pythonImportsCheck = [ "qtwidgets" ];
  };

  pythonEnv = python.withPackages (ps: [
    ps.pyqt5
    ps.qtpy
    qtwidgets
  ]);

  warp-cloudflare-gui = pkgs.stdenv.mkDerivation {
    pname = "warp-cloudflare-gui";
    version = "0-unstable-2026-05-04";
    src = pkgs.fetchFromGitHub {
      owner = "mrmoein";
      repo = "warp-cloudflare-gui";
      rev = "c2c8a7427a259eb6286165ecb7fa3a21cab4d4e1";
      hash = "sha256-eleiea/mBt7KicPdfLZ6mMkWZU2H2G5IAf/8iWRk88k=";
    };
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.qt5.wrapQtAppsHook
    ];
    buildInputs = [
      pkgs.qt5.qtbase
      pkgs.qt5.qtwayland
    ];
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      app=$out/share/warp-cloudflare-gui
      mkdir -p $app $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps
      cp -r main.py warp_gui icons $app/
      cp icons/logo.png $out/share/icons/hicolor/256x256/apps/warp-cloudflare-gui.png
      # main.py imports warp_gui from the current directory; warp-cli comes from the system.
      makeWrapper ${pythonEnv}/bin/python $out/bin/warp-cloudflare-gui \
        --chdir $app --add-flags $app/main.py \
        --suffix PATH : /run/current-system/sw/bin
      cat > $out/share/applications/warp-cloudflare-gui.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=Cloudflare WARP
      Comment=Turn Cloudflare WARP on or off
      Exec=$out/bin/warp-cloudflare-gui
      Icon=warp-cloudflare-gui
      Terminal=false
      Categories=Network;
      EOF
      runHook postInstall
    '';
    # wrapQtAppsHook wraps bin/ so PyQt5 finds the Qt platform plugins (Wayland/X11).
  };
in
{
  home.packages = [ warp-cloudflare-gui ];

  xdg.configFile = {
    # Start at login as a tray icon only (--hide); right-click → Hide / Show opens the window.
    "autostart/warp-cloudflare-gui.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Cloudflare WARP (tray)
      Exec=${warp-cloudflare-gui}/bin/warp-cloudflare-gui --hide
      Icon=warp-cloudflare-gui
      Terminal=false
    '';
    # Stop warp-taskbar autostarting (its entry is in /etc/xdg/autostart). A user file with the
    # same name overrides it; Hidden=true means "don't run". Otherwise there are two WARP icons.
    "autostart/com.cloudflare.WarpTaskbar.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Cloudflare Zero Trust
      Hidden=true
    '';
  };
}

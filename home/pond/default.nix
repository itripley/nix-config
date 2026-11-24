# niri with Pond's interface, for any account (DESIGN §13). Everything it starts hangs off
# niri.service, so Plasma on the same account doesn't see it. Pond's niri config is laid out as
# upstream ships it: config.kdl and shell/ are Pond's (read-only, follow package updates);
# cfg/*.kdl are personal settings, copied in once and then owned by the user (Pond's settings
# app writes to them).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # Pond's launcher: Butterfly's Vicinae fork (flake input). It builds itself with GCC 15 but takes
  # its calculator library (numen) from unstable's default GCC 16, and the two don't link: build
  # numen with GCC 15 too (tests off, they need a GCC 15 Catch2).
  launcherUnwrapped =
    (inputs.pond-launcher.packages.${system}.default.override {
      numen = inputs.pond-launcher.inputs.numen.packages.${system}.numen.override {
        stdenv = inputs.nixpkgs-unstable.legacyPackages.${system}.gcc15Stdenv;
        withRepl = false;
        doCheck = false;
      };
    }).overrideAttrs
      (old: {
        # Its own settings, history and cache, apart from the upstream Vicinae on the same account
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/server/src/vicinae.cpp \
            --replace-fail 'xdgpp::dataHome() / "vicinae"' 'xdgpp::dataHome() / "pond-launcher"' \
            --replace-fail 'xdgpp::configHome() / "vicinae"' 'xdgpp::configHome() / "pond-launcher"' \
            --replace-fail 'xdgpp::cacheHome() / "vicinae"' 'xdgpp::cacheHome() / "pond-launcher"'
          substituteInPlace src/lib/common/src/common.cpp \
            --replace-fail 'fs::path(s) / "vicinae"' 'fs::path(s) / "pond-launcher"' \
            --replace-fail '".local" / "state" / "vicinae"' '".local" / "state" / "pond-launcher"'
          substituteInPlace src/file-indexer/src/file-indexer/util.hpp \
            --replace-fail 'cacheHome() / "vicinae"' 'cacheHome() / "pond-launcher"' \
            --replace-fail 'dataHome() / "vicinae"' 'dataHome() / "pond-launcher"'
        '';
      });

  # What the launcher starts apps through. Chromium and Electron pick where logins are stored from
  # the desktop's name, and only "KDE" with version 6 means KWallet, as in Plasma. Only apps see
  # this: niri, the portals and autostart keep plain "niri".
  startApp = pkgs.writeShellScript "pond-app" ''
    export XDG_CURRENT_DESKTOP=niri:KDE KDE_SESSION_VERSION=6 ELECTRON_OZONE_PLATFORM_HINT=auto
    exec "$@"
  '';
  # Restarts the portal if it was started for another desktop
  portalCheck = pkgs.writeShellScript "portal-check" ''
    PATH=${
      lib.makeBinPath [
        pkgs.systemd
        pkgs.coreutils
        pkgs.gnused
      ]
    }
    unit=xdg-desktop-portal.service
    pid=$(systemctl --user show -P MainPID $unit)
    [ "$pid" -gt 0 ] || exit 0
    desktop='s/^XDG_CURRENT_DESKTOP=//p'
    has=$(tr '\0' '\n' < /proc/$pid/environ | sed -n "$desktop")
    wants=$(systemctl --user show-environment | sed -n "$desktop")
    [ "$has" = "$wants" ] && exit 0
    echo "portal was started for '$has', this is '$wants': restarting it"
    ''${PORTAL_CHECK_DRY_RUN:+echo would run:} systemctl --user restart $unit
  '';
  launcherSettings = pkgs.writeText "pond-launcher.json" (
    builtins.toJSON { providers.applications.preferences.launchPrefix = "${startApp}"; }
  );
  # On XDG_DATA_DIRS only its own data (the Pond themes), not its .desktop files
  launcher = pkgs.runCommand "pond-launcher" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/share
    ln -s ${launcherUnwrapped}/share/vicinae $out/share/vicinae
    makeWrapper ${launcherUnwrapped}/bin/vicinae $out/bin/vicinae \
      --set VICINAE_OVERRIDES ${launcherSettings} \
      --prefix XDG_DATA_DIRS : $out/share
  '';

  pond = pkgs.pond-interface.override { inherit launcher; };
  share = "${pond}/share/pond-interface";

  # Same for what niri starts itself (kitty, and what runs in it)
  miscKdl = pkgs.runCommand "misc.kdl" { } ''
    substitute ${share}/config/niri/cfg/misc.kdl $out --replace-fail \
      '    XDG_CURRENT_DESKTOP "niri"' \
      '    // KDE + version 6: Chromium and Electron logins from KWallet
        XDG_CURRENT_DESKTOP "niri:KDE"
        KDE_SESSION_VERSION "6"'
  '';

  # Nautilus with GVfs (modules/nixos/niri.nix), without setting it for every app
  nautilus = pkgs.runCommand "nautilus-gvfs" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    makeWrapper ${pkgs.nautilus}/bin/nautilus $out/bin/nautilus \
      --prefix GIO_EXTRA_MODULES : ${pkgs.gnome.gvfs}/lib/gio/modules
  '';

  # Pond's apps, listed only under niri and without file types or D-Bus services, so Plasma's menu,
  # default apps and "Show in folder" don't change
  tools = pkgs.runCommand "pond-tools" { } ''
    mkdir -p $out/bin $out/share/applications $out/share/icons
    ln -s ${pond}/bin/qs ${pkgs.kitty}/bin/kitty ${pkgs.kitty}/bin/kitten ${nautilus}/bin/nautilus $out/bin/
    for f in ${pond}/share/applications/pond-manual.desktop \
      ${pkgs.kitty}/share/applications/kitty.desktop \
      ${pkgs.nautilus}/share/applications/org.gnome.Nautilus.desktop; do
      sed -E \
        -e '/^(MimeType|DBusActivatable|OnlyShowIn|NotShowIn|Implements)=/d' \
        -e 's/^\[Desktop Entry\]$/&\nOnlyShowIn=niri;/' \
        "$f" > $out/share/applications/$(basename "$f")
    done
    for p in ${pkgs.kitty} ${pkgs.nautilus}; do
      cp -rs --no-preserve=mode $p/share/icons/hicolor $out/share/icons/
    done
  '';
in
{
  home.packages = [
    tools
    pkgs.xwayland-satellite # X11 apps; niri starts it on demand
  ];

  xdg.configFile = {
    "niri/config.kdl".source = "${share}/config/niri/config.kdl";
    "niri/shell".source = "${share}/config/niri/shell";
    "quickshell/pond-shell".source = "${share}/shell"; # `qs -c pond-shell`
    "kitty/pond-defaults.conf".source = "${share}/config/kitty/etc/kitty.conf";

    # "assign", not an alias list: Qt takes the first family after substitution
    "fontconfig/conf.d/60-pond-gramercy.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test name="family" qual="any"><string>Pond Gramercy</string></test>
          <edit name="family" mode="assign" binding="strong"><string>ABC Gramercy Trial</string></edit>
        </match>
      </fontconfig>
    '';

    # Plasma's settings script has nothing to configure under niri
    "autostart/plasma-manager-autostart.desktop" = lib.mkIf config.programs.plasma.enable {
      text = lib.mkAfter "NotShowIn=niri;";
    };
  };

  xdg.dataFile = {
    "fonts/pond".source = pkgs.callPackage ./fonts.nix { inherit pond; };
    # D-Bus starts Nautilus too (file dialogs under niri): the same wrapped one
    "dbus-1/services/org.gnome.Nautilus.service".text = ''
      [D-BUS Service]
      Name=org.gnome.Nautilus
      Exec=${nautilus}/bin/nautilus --gapplication-service
    '';
    # Pond's cursor: niri's config names it, nothing else does
    "icons/capitaine-cursors".source = "${pkgs.capitaine-cursors}/share/icons/capitaine-cursors";
  };

  # Personal files: copied once if missing, never overwritten
  home.activation.pondPersonalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    seed() { [ -e "$2" ] || run install -Dm644 "$1" "$2"; }
    # This PC's monitors, instead of Pond's example
    seed ${./display.kdl} "$HOME/.config/niri/cfg/display.kdl"
    seed ${miscKdl} "$HOME/.config/niri/cfg/misc.kdl"
    for f in ${share}/config/niri/cfg/*.kdl; do
      seed "$f" "$HOME/.config/niri/cfg/$(basename "$f")"
    done
    seed ${share}/config/kitty/current-theme.conf "$HOME/.config/kitty/current-theme.conf"
    seed ${share}/config/kitty/themes/default.conf "$HOME/.config/kitty/themes/default.conf"
    if [ ! -e "$HOME/.config/kitty/kitty.conf" ]; then
      run mkdir -p "$HOME/.config/kitty"
      run sh -c '{ echo "include pond-defaults.conf"; cat "$1"; echo; echo "include ~/nix-config/home/olivia/dotfiles/kitty/backgrounds.conf"; } > "$2"' sh \
        ${share}/config/kitty/kitty.conf "$HOME/.config/kitty/kitty.conf"
    fi
  '';

  systemd.user.services = {
    # Mod+Space, Mod+V in Pond's binds
    pond-launcher = {
      Unit = {
        Description = "Pond's launcher";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${launcher}/bin/vicinae server";
        Restart = "always";
        RestartSec = 5;
        KillMode = "process"; # leave the apps it started running
      };
      Install.WantedBy = [ "niri.service" ];
    };
    # The account's own Vicinae stays out of niri
    vicinae = lib.mkIf config.programs.vicinae.enable {
      Unit.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=niri";
    };

    # Unlocks KWallet with the login password, as Plasma's plasma-kwallet-pam.service does
    pond-kwallet = {
      Unit = {
        Description = "Unlock KWallet from the login password";
        After = [ "niri.service" ];
        Before = [
          "xdg-desktop-autostart.target"
          "pond-launcher.service"
        ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
        TimeoutStartSec = 10; # autostart waits for it
      };
      Install.WantedBy = [ "niri.service" ];
    };

    # Logging out of one desktop can restart the portal before the session is gone, and the next
    # desktop then gets the old one's backends (dark/light, file dialogs, screen sharing). Runs in
    # both desktops. Not before autostart: in Plasma that comes before graphical-session.target.
    portal-check = {
      Unit = {
        Description = "Restart the portal if it belongs to another desktop";
        After = [ "graphical-session.target" ];
        Before = [ "pond-launcher.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = portalCheck;
        TimeoutStartSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # niri has no polkit agent of its own (Pond uses polkit-gnome); Plasma has its own
    polkit-gnome.Install.WantedBy = lib.mkForce [ "niri.service" ];
  };
  services.polkit-gnome.enable = true;
}

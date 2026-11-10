# macOS settings, captured 2026-11-10 (docs/MACOS.md). Only values that differ from the defaults.
# Changes made in System Settings to anything here are reverted on the next switch.
{
  system.defaults = {
    dock = {
      orientation = "right";
      tilesize = 34;
      autohide = false;
      magnification = false;
      minimize-to-application = true;
      persistent-apps = [
        "/System/Applications/Apps.app"
        "/Applications/ForkLift.app"
        "/Users/olivi/Applications/Orion/WebApps/FileBrowser Quantum.app"
        "/Users/olivi/Applications/Orion/WebApps/NextExplorer.app"
        "/Users/olivi/Applications/Home Manager Apps/WezTerm.app"
        "/Applications/Firefox.app"
        "/Applications/Legcord.app"
        "/System/Applications/Photos.app"
        "/Users/olivi/Applications/Orion/WebApps/Immich.app"
        "/Applications/Plex.app"
        "/Applications/Plexamp.app"
        "/Applications/TIDAL.app"
        "/Applications/YouTube Music.app" # pear-desktop
        "/Applications/PhotoCraft.app"
        "/Applications/Obsidian.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Godot Mono.app"
        "/Applications/Claude.app"
        "/System/Applications/System Settings.app"
      ];
    };

    finder = {
      FXPreferredViewStyle = "Nlsv"; # list view
      ShowPathbar = true;
      NewWindowTarget = "Recents";
      ShowHardDrivesOnDesktop = false;
      ShowExternalHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;
      ShowMountedServersOnDesktop = false;
    };

    NSGlobalDomain = {
      AppleInterfaceStyleSwitchesAutomatically = true; # light/dark follows the time of day
      "com.apple.swipescrolldirection" = false; # natural scrolling off
      "com.apple.trackpad.scaling" = 0.875;
    };

    # Both trackpad domains (built-in and Bluetooth) are written
    trackpad = {
      Clicking = true; # tap to click
      TrackpadRightClick = false;
      TrackpadCornerSecondaryClick = 2; # bottom-right corner
      TrackpadPinch = false;
      TrackpadThreeFingerDrag = false;
    };

    menuExtraClock = {
      ShowAMPM = true;
      ShowDayOfWeek = true;
    };

    WindowManager = {
      GloballyEnabled = false; # Stage Manager off
      EnableTiledWindowMargins = false;
    };

    # Not covered by nix-darwin's typed options
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleKeyboardUIMode = 1; # the typed option only allows 0, 2, 3
        AppleMiniaturizeOnDoubleClick = false;
        AppleMenuBarFontSize = "large";
      };
      "com.apple.loginwindow".TALLogoutSavesState = false; # don't reopen windows at login
      "com.apple.screencapture".showsCursor = true;
    };
  };
}

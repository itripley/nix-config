# Homebrew, declared (docs/MACOS.md). GUI apps stay casks (Spotlight, signing, self-updates);
# CLI tools come from Nix (home/shared/cli.nix, home/darwin/cli.nix) except the brews below.
# Activation only installs what's missing: nothing is upgraded or removed.
{ pkgs, ... }:
{
  # `brew bundle check` needs mas for masApps; activation brings its own
  environment.systemPackages = [ pkgs.mas ];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "none"; # undeclared formulae and casks stay installed; ask before changing this
      autoUpdate = false;
      upgrade = false;
    };
    global.brewfile = true; # plain `brew bundle check` uses the generated Brewfile

    # Only the taps something below needs; the others stay tapped, unmanaged.
    # Third-party taps must be trusted or brew bundle refuses them (Homebrew 6+).
    taps = [
      {
        name = "pear-devs/pear";
        trusted = true;
      }
      {
        name = "viceverse-cz/serein";
        clone_target = "https://github.com/ViceVerse-cz/homebrew-serein";
        trusted = true;
      }
      {
        name = "anomalyco/tap";
        trusted = true;
      }
    ];

    # Review later. Mostly build tooling for brew/Xcode builds that expect /opt/homebrew paths,
    # plus tools with no Nix equivalent as good as Homebrew's.
    brews = [
      "aqtinstall"
      "autoconf-archive"
      "automake"
      "ccache"
      "cmake"
      "llvm@20"
      "nasm"
      "vcpkg"
      "nuget"
      "sdl2_mixer"
      "ffmpeg2theora"
      "php"
      "php@8.3"
      "httpd"
      "rbenv"
      "python@3.11"
      "python@3.13"
      "mpv"
      "mole"
      "chezmoi"
      "tailscale"
      "projectm"
      # Also in Nix, but services run Homebrew's paths: the openclaw gateway LaunchAgent
      # (/opt/homebrew/opt/node, plus its npm globals) and the Cloudflare tunnel LaunchDaemon
      "node"
      "cloudflared"
      "cliclick" # not in nixpkgs
      "anomalyco/tap/opencode" # nixpkgs' is older; unstable isn't cached
    ];

    casks = [
      "balenaetcher"
      "betterdisplay"
      "caffeine"
      "claude"
      "claude-code"
      "cloudflare-warp"
      "dotnet-sdk"
      "finetune"
      "helium-browser"
      "iina"
      "kde-connect"
      "legcord"
      "localsend"
      "mac-mouse-fix"
      "obs@beta"
      "obsidian"
      "orion"
      "pear-devs/pear/pear-desktop"
      "plex"
      "plexamp"
      "privadovpn"
      "raycast"
      "viceverse-cz/serein/serein"
      "sublime-text"
      "termius"
      "the-unarchiver"
      "tidal"
      "visual-studio-code"
    ];

    # Needs an App Store sign-in. Taphouse isn't listed: the store no longer has it (MACOS.md).
    masApps = {
      Keynote = 409183694;
    };
  };
}

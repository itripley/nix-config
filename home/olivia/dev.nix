{ lib, pkgs, ... }:
{
  # git, ssh hosts and Neovim are shared with the Mac (home/shared/); the Linux parts stay here
  programs.git = {
    package = pkgs.gitFull; # includes git-credential-libsecret (KWallet-backed)
    settings.credential.helper = "libsecret";
  };

  # C compiler + make for LazyVim's treesitter, ahead of the shared tools as before
  programs.neovim.extraPackages = lib.mkBefore (
    with pkgs;
    [
      gcc
      gnumake
    ]
  );

  # FHS build so marketplace extensions with native binaries work.
  # All extensions from Windows plus nix-ide, pinned in pkgs/vscode-marketplace/sources.json.
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
    profiles.default.extensions = pkgs.vscode-marketplace.extensions;
  };

  # CLI tools both machines use: home/shared/cli.nix
  home.packages = with pkgs; [
    # Plain package, not programs.wezterm: that module writes wezterm.lua, but
    # ~/.config/wezterm is a live link to dotfiles/wezterm (see default.nix)
    wezterm
    nodejs # LTS; the Mac runs nodejs_26 (home/darwin/cli.nix)
    # Godot C#: godot_4-mono brings its own .NET SDK, so no separate dotnet-sdk
    godot_4
    godot_4-mono
  ];
}

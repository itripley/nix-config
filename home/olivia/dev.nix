{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull; # includes git-credential-libsecret (KWallet-backed)
    settings = {
      user.email = "oliviacmcarmo@gmail.com";
      credential.helper = "libsecret";
      init.defaultBranch = "main";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Keys are not in the repo; copy them from /mnt/windows/Users/olivi/.ssh after install
    settings = {
      "github-artlivia" = {
        # remote: git@github-artlivia:itripley/artlivia.git
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_artlivia";
        IdentitiesOnly = true;
      };
      "unraid" = {
        HostName = "192.168.1.65";
        User = "root";
        IdentityFile = "~/.ssh/id_unraid";
        IdentitiesOnly = true;
      };
      "*" = {
        AddKeysToAgent = "yes";
      };
    };
  };

  # LazyVim config is linked from dotfiles/nvim (see default.nix)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # HM 26.05 always generates init.lua (provider toggles). ~/.config/nvim is a live link
    # to dotfiles/nvim (LazyVim's own init.lua), so pass HM's lines via the wrapper instead.
    sideloadInitLua = true;
    extraPackages = with pkgs; [
      gcc
      gnumake
      unzip
      ripgrep
      fd
      tree-sitter
      lazygit
      lua-language-server
      nil
      nixfmt
    ];
  };

  # FHS build so marketplace extensions with native binaries work.
  # All extensions from Windows plus nix-ide, pinned in pkgs/vscode-marketplace/sources.json.
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
    profiles.default.extensions = pkgs.vscode-marketplace.extensions;
  };

  home.packages = with pkgs; [
    # Plain package, not programs.wezterm: that module writes wezterm.lua, but
    # ~/.config/wezterm is a live link to dotfiles/wezterm (see default.nix)
    wezterm
    nodejs
    python3
    uv
    # Godot C#: godot_4-mono brings its own .NET SDK, so no separate dotnet-sdk
    godot_4
    godot_4-mono
    docker-compose
    tmux
    mc
    fastfetch
    jq
    gh
    # From Fedora
    go
    rustup # cargo/rustc; Fedora had cargo with ~/.cargo/bin on PATH
    lazydocker
  ];
}

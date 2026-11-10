# zsh is the Mac's login shell; WezTerm runs fish (home/shared/shell.nix). Homebrew stays on
# PATH but after Nix, so Nix's git, node, gh … win over the brew copies.
{ config, ... }:
{
  programs.zsh = {
    enable = true;
    history.path = "${config.home.homeDirectory}/.zsh_history"; # the existing history
    # nix-darwin's /etc/zshrc already runs compinit, with the Nix profiles on fpath
    enableCompletion = false;
    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
      typeset -U path
      path=(/etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin $path)
    '';
    initContent = ''
      eval "$(${config.home.homeDirectory}/.local/bin/mise activate zsh)"
    '';
  };

  programs.fish.shellInit = ''
    /opt/homebrew/bin/brew shellenv fish | source
    fish_add_path --global --move --prepend --path /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin
  '';

  home.sessionPath = [ "$HOME/.lmstudio/bin" ]; # LM Studio CLI (lms)

  # fish turns this on, but HM uses macOS's own man here, so it only produced a warning
  programs.man.generateCaches = false;
}

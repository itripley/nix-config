{ pkgs, ... }:
{
  # LazyVim config is linked from dotfiles/nvim (see default.nix)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # HM 26.05 always generates init.lua (provider toggles). ~/.config/nvim is a live link
    # to dotfiles/nvim (LazyVim's own init.lua), so pass HM's lines via the wrapper instead.
    sideloadInitLua = true;
    # The C compiler for treesitter is per platform (desktop: gcc in home/olivia/dev.nix;
    # Mac: the Xcode Command Line Tools' cc)
    extraPackages = with pkgs; [
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
}

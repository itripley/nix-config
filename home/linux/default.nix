# olivia's apps on any x86_64 Linux: the NixOS desktop (home/olivia), NixOS-WSL (hosts/wsl) and
# other distros (standalone home-manager, flake.nix). Plasma, Flatpak and the WARP tray need
# NixOS and stay in home/olivia.
{ config, ... }:
{
  imports = [
    ../shared
    ../olivia/apps.nix
    ../olivia/dev.nix
    ../olivia/firefox.nix
    ../olivia/obsidian.nix
    ../olivia/mpv.nix
    ../olivia/easyeffects.nix
  ];

  # fastfetch's symbols in Konsole: Qt only looks in the families fontconfig lists for the font
  xdg.configFile."fontconfig/conf.d/60-fastfetch-flowers.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="family"><string>monospace</string></test>
        <edit name="family" mode="append" binding="weak"><string>Fastfetch Flowers</string></edit>
      </match>
    </fontconfig>
  '';

  # Licensed fonts (TX-02 for WezTerm and Obsidian), kept out of git: dotfiles/fonts is gitignored,
  # all but fastfetch's symbols (fastfetch-flowers, BSD-3-Clause).
  # A live link into the checkout (~/nix-config), like the shared dotfiles.
  xdg.dataFile."fonts/nix-config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/home/olivia/dotfiles/fonts";
}

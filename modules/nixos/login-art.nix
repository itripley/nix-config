# Fedora's login-screen background and avatar (SilentSDDM, desktop.nix). Third-party art,
# gitignored: copy themes/art/sddm/ into the checkout and add both files to the store before
# building (home/olivia/themes/README.md). Import it only on machines that have them.
{ pkgs, ... }:
let
  art =
    name: hash:
    pkgs.requireFile {
      inherit name hash;
      message = ''
        ${name} is gitignored art. Add it to the store, then build again:
          nix store add-file ~/nix-config/home/olivia/themes/art/sddm/${name}
      '';
    };
in
{
  programs.silentSDDM = {
    backgrounds.rei2 = art "rei2.png" "sha256-Hu/hnIvhM8ClDcNUQFmJCR/hT495eRu3gZlYta0+bXc=";
    profileIcons.olivia = art "avatar.png" "sha256-3pdAQJ1e5xCpqMcPWMglKm0TxKa7eyDLy2/+KG5qWM8=";
    settings = {
      General.animated-background-placeholder = "rei2.png";
      LockScreen.background = "rei2.png";
      LoginScreen.background = "rei2.png";
    };
  };
}

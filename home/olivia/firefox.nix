# Firefox, with the Windows profile carried over as-is.
#
# Declarative here: the profile entry (same name/path as on Windows), userChrome.css,
# a few Linux-specific prefs (user.js) and the Bitwarden desktop bridge.
# Migrated by scripts/migrate-firefox-profile.sh: everything else — all add-ons and their
# settings/data (Sidebery panels & styles, uBlock filters, ScriptCat scripts, ...), themes,
# containers, logins, cookies, history, bookmarks, open tabs and the other ~440 prefs.
# Add-ons are deliberately NOT declared via Nix: a fresh install would come up with empty
# settings, and Nix-managed add-ons can't be toggled from about:addons.
{ pkgs, ... }:
let
  # Bitwarden desktop writes this manifest at runtime on other distros; declaring it makes
  # "Allow browser integration" (unlock with the desktop app) work regardless of profile layout.
  bitwardenNativeHost = pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/com.8bit.bitwarden.json" (
    builtins.toJSON {
      name = "com.8bit.bitwarden";
      description = "Bitwarden desktop <-> browser bridge";
      path = "${pkgs.bitwarden-desktop}/libexec/desktop_proxy";
      type = "stdio";
      allowed_extensions = [ "{446900e4-71c2-419f-a6a7-df9c091e268b}" ];
    }
  );
in
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ bitwardenNativeHost ];

    # Lives at ~/.config/mozilla/firefox/9ylnf32e.default-release (XDG layout, stateVersion 26.05)
    profiles."default-release" = {
      id = 0;
      isDefault = true;
      path = "9ylnf32e.default-release";

      # Sidebery-only layout: hides the native tab strip, new sidebar launcher and sidebar
      # header while Sidebery's panel is open. Was present but inactive on Windows.
      userChrome = ./dotfiles/firefox/userChrome.css;

      # Written to user.js and re-applied on every start; everything else stays in prefs.js
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # load userChrome.css
        "widget.use-xdg-desktop-portal.file-picker" = 1; # KDE file dialogs
        "media.ffmpeg.vaapi.enabled" = true; # hardware video decode on the 7800 XT
      };
    };
  };
}

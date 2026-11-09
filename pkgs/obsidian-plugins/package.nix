# Obsidian community plugins and themes, pinned in sources.json to the versions in the Windows
# vault (release files, with GitHub's API asset URL as a fallback). The result links them all, so
# `nix build .#obsidian-plugins` fetches and checks every file; home/olivia/obsidian.nix uses
# `.plugins.<id>` and `.themes.<name>`.
{
  lib,
  stdenvNoCC,
  fetchurl,
  linkFarm,
}:
let
  sources = lib.importJSON ./sources.json;

  # Store names allow only [A-Za-z0-9+-._?=]: "Tom's Theme" -> "tom-s-theme"
  storeName = name: lib.toLower (lib.replaceStrings [ " " "'" ] [ "-" "-" ] name);

  copyFiles =
    files:
    lib.concatStrings (
      lib.mapAttrsToList (name: file: ''
        cp ${
          fetchurl {
            inherit (file) urls hash;
            # The API asset URLs (second) need this; github.com and raw URLs ignore it
            curlOptsList = [
              "-H"
              "Accept: application/octet-stream"
            ];
          }
        } "$out/${name}"
      '') files
    );

  # manifestId: the folder name, read by home-manager's programs.obsidian (no IFD)
  mkItem =
    kind: postInstall: name: src:
    stdenvNoCC.mkDerivation {
      pname = "obsidian-${kind}-${storeName name}";
      inherit (src) version;
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        ${copyFiles src.files}
        chmod -R u+w $out
        ${postInstall}
        runHook postInstall
      '';
      passthru.manifestId = name;
      meta = {
        homepage = "https://github.com/${src.repo}";
        platforms = lib.platforms.all;
      };
    };

  # What Obsidian's installer does: drop the inline source map, then mark main.js
  plugins = lib.mapAttrs (mkItem "plugin" ''
    sed -i 's|^//# sourceMappingURL=data:.*$||' $out/main.js
    printf '\n/* nosourcemap */' >> $out/main.js
  '') sources.plugins;
  themes = lib.mapAttrs (mkItem "theme" "") sources.themes;
in
linkFarm "obsidian-plugins" (
  lib.mapAttrsToList (n: path: {
    name = "plugins/${n}";
    inherit path;
  }) plugins
  ++ lib.mapAttrsToList (n: path: {
    name = "themes/${storeName n}";
    inherit path;
  }) themes
)
// {
  inherit plugins themes;
}

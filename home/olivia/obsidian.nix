# Obsidian with the "weblivia" vault set up as on Windows: same plugins, themes, snippets and
# settings. Self-hosted LiveSync pulls the notes. See docs/MODULES.md and docs/OPERATIONS.md.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  vault = "Documents/obsidian/weblivia";
  inherit (pkgs.obsidian-plugins) plugins themes;

  # Copied into .obsidian/ only when missing, because Obsidian and plugins rewrite these files
  seed = ./obsidian/seed;
  # Same layout, placed by hand, never in the repo: LiveSync's and Paperless's data.json
  privateSeed = "${config.xdg.configHome}/obsidian-seed";

  disabled = pkg: {
    inherit pkg;
    enable = false;
  };
in
{
  programs.obsidian = {
    enable = true;
    vaults.weblivia = {
      target = vault;
      settings = {
        app = {
          userIgnoreFilters = [ "wiki/notes/memos/_knomo-system/" ];
          openBehavior = "";
          newFileLocation = "current";
          alwaysUpdateLinks = true;
          newFileFolderPath = "wiki/notes/general";
          propertiesInDocument = "visible";
          foldHeading = true;
          foldIndent = true;
        };
        appearance = {
          theme = "obsidian"; # dark
          accentColor = "#b13627";
          interfaceFontFamily = "TX-02";
          textFontFamily = "TX-02";
          baseFontSize = 15;
          showRibbon = true;
        };
        corePlugins = [
          "audio-recorder"
          "backlink"
          "bases"
          "bookmarks"
          "canvas"
          "command-palette"
          {
            name = "daily-notes";
            settings = {
              folder = "wiki/notes/memos/daily";
              format = "YYYY-MM-DD";
            };
          }
          "editor-status"
          "file-explorer"
          "file-recovery"
          "global-search"
          "graph"
          "note-composer"
          "outgoing-link"
          "outline"
          "page-preview"
          "properties"
          "switcher"
          "sync"
          "tag-pane"
          {
            name = "templates";
            settings.folder = "_templates";
          }
          "word-count"
        ];
        # Order of community-plugins.json on Windows
        communityPlugins = [
          plugins.obsidian-excalidraw-plugin
          plugins.templater-obsidian
          plugins.dataview
          plugins.obsidian-banners
          plugins.pdf-plus
          plugins.paperless
          plugins.calendar
          plugins.knomo
          (disabled plugins.obsidian-git) # the git backup runs on Windows; no repo here
          plugins.cmdr
          plugins.metadata-menu
          plugins.update-time-on-edit
          plugins.OA-file-hider
          plugins.obsidian-advanced-uri
          plugins.obsidian-livesync
          # Installed but off on Windows too
          (disabled plugins.current-view)
          (disabled plugins.dream-journal)
          (disabled plugins.fold-properties-by-default)
          (disabled plugins.obsidian-importer)
        ];
        cssSnippets = [
          ./obsidian/snippets/vault-colors.css
          ./obsidian/snippets/hide-properties-in-reading-mode.css
        ];
        themes = [
          themes.Minimal
          (disabled themes.Alien)
          (disabled themes.Elysian)
          (disabled themes.Nier)
          (disabled themes."Obsidian gruvbox")
          (disabled themes."Tom's Theme")
        ];
      };
    };
  };

  home.activation.obsidianSeed = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    obsidianDir="$HOME/${vault}/.obsidian"
    seedFrom() {
      [ -d "$1" ] || return 0
      (cd "$1" && find . -type f) | while read -r f; do
        if [ ! -e "$obsidianDir/$f" ]; then
          run install -D -m "$2" "$1/$f" "$obsidianDir/$f"
        fi
      done
    }
    seedFrom "${privateSeed}" 600
    seedFrom ${seed} 644
    if [ ! -e "$obsidianDir/plugins/obsidian-livesync/data.json" ]; then
      warnEcho "Obsidian: no LiveSync settings yet; see docs/OPERATIONS.md (Obsidian)"
    fi
  '';
}

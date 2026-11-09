# VS Code extensions from the marketplace, pinned in sources.json to the versions on Windows
# (the Linux x64 build where an extension is platform-specific). home/olivia/dev.nix installs
# `.extensions`; the package itself links them all, so `nix build .#vscode-marketplace` fetches
# and checks every VSIX.
{
  lib,
  vscode-utils,
  linkFarm,
}:
let
  extensions = vscode-utils.extensionsFromVscodeMarketplace (lib.importJSON ./sources.json);
in
linkFarm "vscode-marketplace" (
  map (ext: {
    name = ext.vscodeExtUniqueId;
    path = ext;
  }) extensions
)
// {
  inherit extensions;
}

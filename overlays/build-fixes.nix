# Local fixes for packages that fail to build in the pinned nixpkgs. Applied to both
# the stable package set and pkgs.unstable (see flake.nix).
# Each one is a workaround for an upstream bug: after `nh os switch --update`, try
# deleting it. If the package still builds without the fix, the fix can go.
# See docs/VERIFICATION.md ("First real build") for the failure logs.
final: prev: {
  # VS Code 1.144 moved its bundled ripgrep to
  #   node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg
  # but nixpkgs' postPatch still runs `rm .../@vscode/ripgrep/bin/rg` and fails.
  # Point both copies (asar-unpacked and the extracted node_modules) at nixpkgs' ripgrep.
  # vscode.fhs picks this up because its passthru uses finalAttrs.finalPackage.
  vscode = prev.vscode.overrideAttrs (old: {
    postPatch =
      let
        oldRg = "resources/app/node_modules/@vscode/ripgrep/bin/rg";
        broken = "rm ${oldRg}\nln -s ${final.ripgrep}/bin/rg ${oldRg}\n";
        fixed = ''
          for rg in resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg \
                    resources/app/node_modules/@vscode/ripgrep-universal/bin/linux-x64/rg \
                    ${oldRg}; do
            if [ -e "$rg" ]; then rm "$rg"; ln -s ${final.ripgrep}/bin/rg "$rg"; fi
          done
        '';
        patched = builtins.replaceStrings [ broken ] [ fixed ] old.postPatch;
      in
      # If nixpkgs changes this snippet, fail loudly instead of silently doing nothing
      assert final.lib.assertMsg (
        patched != old.postPatch || !final.lib.hasInfix oldRg old.postPatch
      ) "overlays/build-fixes.nix: vscode postPatch changed upstream; re-check the ripgrep fix";
      patched;
  });

  # OpenSSL 1.1 (EOL, only used by sublime4) fails its test_afalg self-test: the test
  # drives the *running* kernel's AF_ALG crypto socket, which Linux 7.x no longer serves
  # the way OpenSSL 1.1 expects. Only that one test is dropped; the rest of the suite runs.
  openssl_1_1 = prev.openssl_1_1.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      rm test/recipes/30-test_afalg.t
    '';
  });
}

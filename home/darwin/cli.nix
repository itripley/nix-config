# Mac-only CLI tools (shared ones: home/shared/cli.nix). Versions match or beat what Homebrew had:
# pkgs.unstable where stable is behind it. cliclick (not in nixpkgs) and opencode stay in Homebrew.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_26 # current release, as Homebrew had; the desktop runs the LTS
    unstable.croc # v11, as Homebrew had (stable is v10)
    # Docker via Colima. unstable.colima uses lima 2.2, the version the existing VM was made with
    unstable.colima
    docker-client
    unstable.docker-buildx
    docker-credential-helpers
    unstable.kubernetes-helm # helm 4 (stable is 3)
    cloudflared
    imagemagick
    pv
    rsync # macOS ships openrsync
    unar
    pipx
    unstable.ente-cli
    git-lfs
  ];
}

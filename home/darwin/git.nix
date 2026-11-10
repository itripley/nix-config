# The Mac's git and ssh additions (shared parts: home/shared/git.nix)
{ pkgs, ... }:
let
  # gh as the GitHub credential helper, as `gh auth setup-git` had set it up
  gh = [
    ""
    "!${pkgs.gh}/bin/gh auth git-credential"
  ];
in
{
  programs.git = {
    lfs.enable = true;
    ignores = [ "**/.claude/settings.local.json" ];
    settings = {
      user.name = "olivia";
      credential."https://github.com".helper = gh;
      credential."https://gist.github.com".helper = gh;
    };
  };

  programs.ssh.includes = [ "~/.colima/ssh_config" ]; # colima's VM (`ssh colima`)
}

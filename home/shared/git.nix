# Credential helpers are per platform: libsecret on the desktop (home/olivia/dev.nix),
# gh on the Mac (home/darwin/git.nix)
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "olivia"; # same author name from both machines
      user.email = "oliviacmcarmo@gmail.com";
      init.defaultBranch = "main";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Keys are not in the repo; copy them by hand (desktop: from /mnt/windows/Users/olivi/.ssh)
    settings = {
      "github-artlivia" = {
        # remote: git@github-artlivia:itripley/artlivia.git
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_artlivia";
        IdentitiesOnly = true;
      };
      "unraid" = {
        HostName = "192.168.1.65";
        User = "root";
        IdentityFile = "~/.ssh/id_unraid";
        IdentitiesOnly = true;
      };
      "*" = {
        AddKeysToAgent = "yes";
      };
    };
  };
}

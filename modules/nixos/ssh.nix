# SSH server, key login only: lets the Unraid Claude container connect as olivia
_: {
  services.openssh = {
    enable = true; # also opens TCP 22 in the firewall
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users.olivia.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHusH1Fkj1KWMgpWXbypjrIr5yLkxyhsaKI2hMx4cX0t claude-unraid-manager -> nixos"
  ];
}

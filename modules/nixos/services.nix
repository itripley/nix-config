_: {
  virtualisation.docker.enable = true;

  # Local LLMs. CPU build here; amd.nix switches it to ROCm
  services.ollama.enable = true;

  # mDNS / .local discovery (replaces Apple Bonjour)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}

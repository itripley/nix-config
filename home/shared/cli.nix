# CLI tools on both machines (desktop-olivia and macbook-olivia)
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python3
    uv
    docker-compose
    tmux
    mc
    fastfetch
    jq
    gh
    btop
    # From Fedora
    go
    rustup # cargo/rustc; Fedora had cargo with ~/.cargo/bin on PATH
    lazydocker
  ];
}

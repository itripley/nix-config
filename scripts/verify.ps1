# Evaluates the flake from Windows using Docker on the Unraid server (no Nix needed locally).
# Streams the tracked files to a throwaway nixos/nix container over SSH; the Nix store is
# cached in the `nixos-eval-store` Docker volume on the server. Nothing is built or installed.
#   pwsh -File scripts\verify.ps1
param(
    [string]$SshHost = 'root@192.168.1.65',
    [string]$SshKey = "$HOME\.ssh\id_unraid"
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$tmp = Join-Path ([IO.Path]::GetTempPath()) "nix-config-verify"
New-Item -ItemType Directory -Force $tmp | Out-Null

$run = @'
N="nix --extra-experimental-features nix-command --extra-experimental-features flakes --accept-flake-config"
$N eval --raw path:.#nixosConfigurations.desktop-olivia.config.system.build.toplevel.drvPath >/tmp/out 2>/tmp/err
rc=$?
grep -v '^copying path' /tmp/err | grep -i 'warning' | sort -u
if [ $rc = 0 ]; then echo "OK: $(cat /tmp/out)"; else
  grep -oE "derivation '[^']+'" /tmp/err | uniq | tail -5
  grep -E 'source/(home|hosts|modules|flake)' /tmp/err | tail -6
  grep -v '^copying path' /tmp/err | tail -12
  exit 1
fi
'@
[IO.File]::WriteAllText("$tmp\run.sh", $run.Replace("`r`n", "`n"))

git -C $repo add -A  # flakes only see tracked files
git -C $repo ls-files | Set-Content "$tmp\files.txt"
Remove-Item "$tmp\cfg.tar" -ErrorAction SilentlyContinue
tar -cf "$tmp\cfg.tar" -C $repo -T "$tmp\files.txt"
tar -rf "$tmp\cfg.tar" -C $tmp run.sh

$remote = "docker run -i --rm -v nixos-eval-store:/nix nixos/nix sh -c 'mkdir /cfg && cd /cfg && tar xf - && sh run.sh'"
cmd /c "ssh -i `"$SshKey`" -o BatchMode=yes $SshHost `"$remote`" < `"$tmp\cfg.tar`" 2>&1"
if ($LASTEXITCODE) { throw 'evaluation failed (see errors above)' }

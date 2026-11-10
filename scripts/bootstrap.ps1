# Sets up NixOS in WSL on a Windows machine and applies hosts/wsl from this repo. Run it in
# PowerShell as yourself (it asks for administrator rights only to install WSL itself):
#   irm https://raw.githubusercontent.com/itripley/nixos-config/main/scripts/bootstrap.ps1 | iex
# or from a checkout: pwsh -File scripts\bootstrap.ps1
# Steps: WSL (once; needs a reboot) -> the NixOS distro from NixOS-WSL's latest release ->
# scripts/bootstrap.sh inside it -> the restarts NixOS-WSL documents for a new default user.
# Native Windows apps aren't managed by Nix; see docs/MIGRATION.md.

function Invoke-NixosWslBootstrap {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'  # Invoke-WebRequest is slow with the progress bar
    $env:WSL_UTF8 = '1'                       # wsl.exe prints UTF-8 instead of UTF-16
    $distro = 'NixOS'
    $raw = 'https://raw.githubusercontent.com/itripley/nixos-config/main'
    $tmp = [IO.Path]::GetTempPath()

    # 1. WSL itself
    wsl.exe --status *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host '==> WSL is not installed. Installing it (administrator prompt), then reboot.' -ForegroundColor Magenta
        Start-Process wsl.exe -ArgumentList '--install', '--no-distribution' -Verb RunAs -Wait
        Write-Host 'Reboot Windows, then run this script again.'
        return
    }

    # 2. The NixOS distro (NixOS-WSL's .wsl image)
    $distros = (wsl.exe --list --quiet) -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if ($distros -notcontains $distro) {
        $image = Join-Path $tmp 'nixos.wsl'
        Write-Host '==> Downloading NixOS-WSL (latest release)' -ForegroundColor Magenta
        Invoke-WebRequest 'https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos.wsl' -OutFile $image -UseBasicParsing
        Write-Host "==> Installing it as the '$distro' distro" -ForegroundColor Magenta
        wsl.exe --install --from-file $image --name $distro --no-launch
        if ($LASTEXITCODE -ne 0) { throw 'wsl --install --from-file failed. It needs WSL 2.4.4 or newer: run wsl --update' }
        Remove-Item $image
    }

    # 3. bootstrap.sh inside it: the one next to this script, or the published one
    $sh = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'bootstrap.sh' } else { '' }
    if (-not $sh -or -not (Test-Path $sh)) {
        $sh = Join-Path $tmp 'nixos-config-bootstrap.sh'
        Invoke-WebRequest "$raw/scripts/bootstrap.sh" -OutFile $sh -UseBasicParsing
    }
    $linuxPath = (wsl.exe -d $distro -- wslpath -u ($sh -replace '\\', '/')).Trim()
    wsl.exe -d $distro -- bash $linuxPath
    if ($LASTEXITCODE -ne 0) { throw 'bootstrap.sh failed inside WSL (its output is above)' }

    # 4. A new default user only takes effect after these restarts (NixOS-WSL's docs)
    $user = (wsl.exe -d $distro -- id -un).Trim()
    if ($user -ne 'olivia') {
        Write-Host '==> Restarting the distro so that olivia becomes the default user' -ForegroundColor Magenta
        wsl.exe -t $distro | Out-Null
        wsl.exe -d $distro --user root exit
        wsl.exe -t $distro | Out-Null
        $user = (wsl.exe -d $distro -- id -un).Trim()
    }
    Write-Host "==> Done: the default user is $user. Open it with: wsl -d $distro" -ForegroundColor Magenta
    Write-Host "    Make it the default distro: wsl --set-default $distro"
}

Invoke-NixosWslBootstrap

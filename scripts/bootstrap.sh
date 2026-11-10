#!/usr/bin/env bash
# sudo runs only the tool: output goes to files the user owns, input comes from the terminal
# shellcheck disable=SC2024
#
# Sets up a machine from this repo. Run it on the machine itself:
#   bash <(curl -fsSL https://raw.githubusercontent.com/itripley/nixos-config/main/scripts/bootstrap.sh)
# or from a checkout: ~/nixos-config/scripts/bootstrap.sh
#
# What it does depends on where it runs (docs/OPERATIONS.md, "Setting up a new machine"):
#   NixOS USB installer   new PC: writes hosts/<name>/, wipes the disk you pick (typed
#                         confirmation), installs NixOS. A known host is reinstalled as it is.
#   NixOS, installed      known hostname: switches to it. Otherwise adopts this install as
#                         hosts/<name>/ (keeps its disks), then `nixos-rebuild boot`.
#   NixOS-WSL             hosts/wsl (scripts/bootstrap.ps1 runs this part from Windows)
#   macOS, Apple Silicon  nix-darwin: a known or new hosts/<name>/, or home-manager only
#   other Linux, WSL      installs Nix if missing, then standalone home-manager
# Windows itself: scripts/bootstrap.ps1.
set -euo pipefail

REPO_URL=${NIXOS_CONFIG_REPO:-https://github.com/itripley/nixos-config.git}
CHECKOUT=${NIXOS_CONFIG_DIR:-$HOME/nixos-config}
# Flakes for every nix call here, whatever the machine's nix.conf says: NIX_CONFIG reaches the
# tools nix starts (home-manager), the flags reach the sudo calls, which drop the environment
NIX_FLAGS=(--extra-experimental-features "nix-command flakes")
export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG$'\n'}extra-experimental-features = nix-command flakes"

say() { printf '\033[1;35m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}
# Prompts read the terminal, so `curl … | bash` works too
ask() {
  local reply
  read -r -p "$1 " reply </dev/tty
  printf '%s' "$reply"
}
confirm() { [[ $(ask "$1 [y/N]") == [yY]* ]]; }
nixf() { nix "${NIX_FLAGS[@]}" "$@"; }
git() {
  if command -v git >/dev/null; then command git "$@"; else nixf run nixpkgs#git -- "$@"; fi
}

valid_name() { [[ $1 =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; }
ask_name() { # prompt, default
  local name
  while :; do
    name=$(ask "$1${2:+ [$2]}:")
    name=${name:-${2:-}}
    valid_name "$name" && break
    warn "use lowercase letters, digits and dashes"
  done
  printf '%s' "$name"
}

get_checkout() {
  if [[ -d $CHECKOUT/.git ]]; then
    say "Using the checkout in $CHECKOUT"
    [[ -z $(git -C "$CHECKOUT" status --porcelain) ]] ||
      warn "$CHECKOUT has uncommitted changes; they are used as they are"
  else
    say "Cloning $REPO_URL into $CHECKOUT"
    git clone "$REPO_URL" "$CHECKOUT"
  fi
  cd "$CHECKOUT"
}

nixpkgs_release() { nixf eval --raw --inputs-from . nixpkgs#lib.trivial.release; }

# Evaluates the whole system before anything is touched: errors show up here, not mid-install
preflight() {
  say "Evaluating nixosConfigurations.$1"
  nixf eval --raw ".#nixosConfigurations.$1.config.system.build.toplevel.drvPath" >/dev/null
}

# login-art.nix pulls in gitignored files with requireFile; the build fails without them
uses_login_art() { grep -qE '^\s*\.\./\.\./modules/nixos/login-art\.nix' "hosts/$1/configuration.nix"; }
add_login_art() {
  uses_login_art "$1" || return 0
  local f art=home/olivia/themes/art/sddm
  for f in rei2.png avatar.png; do
    [[ -f $art/$f ]] || die "hosts/$1 imports login-art.nix, but $art/$f is missing (gitignored art).
Copy it in (home/olivia/themes/README.md), or comment out that import, then run this again."
  done
  for f in rei2.png avatar.png; do nixf store add-file "$art/$f" >/dev/null; done
  say "Login-screen art added to the store"
}

# Unraid credentials for storage.nix, never in the repo
smb_secrets() { # root of the target system ("" for this one)
  local file=$1/etc/nixos/smb-secrets user pass
  [[ -e $file ]] && return 0
  user=$(ask "Unraid SMB username (Enter to skip; add $file later):")
  [[ -n $user ]] || return 0
  read -r -s -p "Unraid SMB password: " pass </dev/tty
  echo >&2
  sudo install -d -m 755 "$1/etc/nixos"
  sudo install -m 600 /dev/null "$file"
  printf 'username=%s\npassword=%s\n' "$user" "$pass" | sudo tee "$file" >/dev/null
}

# ---------- disks (NixOS installer)

# The stable name of a whole disk: by-id with model and serial when there is one
disk_id() {
  local dev=$1 link best=""
  for link in /dev/disk/by-id/*; do
    [[ $link == *-part[0-9]* ]] && continue
    [[ $(readlink -f "$link") == "$dev" ]] || continue
    case ${link##*/} in
      wwn-* | nvme-eui.* | nvme-nvme.*) [[ -n $best ]] || best=$link ;;
      *)
        best=$link
        break
        ;;
    esac
  done
  printf '%s' "${best:-$dev}"
}

installer_disk() {
  local src
  src=$(findmnt -no SOURCE /iso 2>/dev/null) || return 0
  src=$(readlink -f "$src")
  printf '/dev/%s' "$(lsblk -no PKNAME "$src" | head -n1)"
}

# Lists the disks, asks for one, prints its stable name
pick_disk() {
  local line dev size model tran usb n=0 choice
  local -a devs=()
  usb=$(installer_disk)
  say "Disks:"
  while read -r line; do
    [[ $line =~ NAME=\"([^\"]*)\"\ SIZE=\"([^\"]*)\"\ TYPE=\"disk\"\ TRAN=\"([^\"]*)\"\ MODEL=\"([^\"]*)\" ]] || continue
    dev=${BASH_REMATCH[1]} size=${BASH_REMATCH[2]} tran=${BASH_REMATCH[3]} model=${BASH_REMATCH[4]}
    [[ $dev == /dev/zram* || $dev == /dev/loop* ]] && continue
    n=$((n + 1))
    devs+=("$dev")
    printf '  %d) %-14s %8s %-5s %-30s %s%s\n' "$n" "$dev" "$size" "$tran" "$model" \
      "$(lsblk -no FSTYPE "$dev" | sort -u | tr '\n' ' ')" \
      "$([[ $dev == "$usb" ]] && echo '(this installer)')" >&2
  done < <(lsblk -dpnP -o NAME,SIZE,TYPE,TRAN,MODEL)
  ((n)) || die "no disks found"
  choice=$(ask "Install on which disk? (1-$n)")
  if ! [[ $choice =~ ^[0-9]+$ ]] || ((choice < 1 || choice > n)); then die "no such disk"; fi
  dev=${devs[choice - 1]}
  [[ $dev != "$usb" ]] || die "that is the USB installer"
  disk_id "$dev"
}

# The disks a host's disko config partitions, one per line
host_disks() {
  nixf eval --raw ".#nixosConfigurations.$1.config.disko.devices.disk" \
    --apply 'd: builtins.concatStringsSep "" (map (x: x.device + "\n") (builtins.attrValues d))'
}

# Shows each disk a host's disko config would wipe and asks for its name to be typed
confirm_wipe() {
  local name=$1 id dev
  local -a ids
  mapfile -t ids < <(host_disks "$name")
  ((${#ids[@]})) || die "hosts/$name has no disk layout (disko) to install onto"
  for id in "${ids[@]}"; do
    [[ -e $id ]] || die "$id (hosts/$name) is not connected. Check the disk id in hosts/$name."
    dev=$(readlink -f "$id")
    echo >&2
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL "$dev" >&2
    printf '\n\033[1;31mEVERYTHING on %s (%s) will be erased.\033[0m\n' "$dev" "$id" >&2
    [[ $(ask "Type ${dev#/dev/} to erase it:") == "${dev#/dev/}" ]] || die "not confirmed; nothing was changed"
  done
}

# ---------- host files

# Which GPU module(s) to import, from the PCI vendor ids of the graphics cards
gpu_modules() {
  local card vendors=""
  for card in /sys/class/drm/card*; do
    [[ $card =~ card[0-9]+$ && -r $card/device/vendor ]] && vendors+=" $(<"$card/device/vendor")"
  done
  if [[ $vendors == *0x10de* ]]; then
    echo nvidia
    [[ $vendors == *0x1002* || $vendors == *0x8086* ]] &&
      warn "NVIDIA plus an integrated GPU (laptop?): hybrid graphics (PRIME) needs hardware.nvidia.prime set by hand"
  elif [[ $vendors == *0x1002* ]]; then
    echo amd
  fi
  return 0
}

# configuration.nix of a PC. Args: name, release, disk id ("" = keep this install's disks),
# EFI mount point ("" = /boot), GPU modules…
pc_config() {
  local name=$1 release=$2 disk=$3 esp=$4 gpu
  shift 4
  local -a gpus=("$@")
  has() { [[ " ${gpus[*]} " == *" $1 "* ]]; }
  printf '# %s: written by scripts/bootstrap.sh on %s\n{\n  imports = [\n' "$name" "$(date +%F)"
  printf '    ./hardware-configuration.nix\n'
  [[ -n $disk ]] && printf '    ../../modules/nixos/disk-layout.nix\n'
  printf '    ../../modules/nixos/common.nix\n    ../../modules/nixos/boot.nix\n'
  for gpu in amd nvidia; do
    if has "$gpu"; then
      printf '    ../../modules/nixos/%s.nix\n' "$gpu"
    else
      printf '    # ../../modules/nixos/%s.nix\n' "$gpu"
    fi
  done
  printf '    ../../modules/nixos/desktop.nix\n'
  printf '    # ../../modules/nixos/login-art.nix # once themes/art/sddm/ is copied in (gitignored)\n'
  printf '    ../../modules/nixos/%s.nix\n' audio networking storage gaming services
  printf '  ];\n\n'
  if [[ -n $disk ]]; then
    # nixfmt's layout: on one line if it fits in 100 columns, else the value on the next
    local line="  disko.devices.disk.main.device = \"$disk\";"
    ((${#line} <= 100)) || line="  disko.devices.disk.main.device =\n    \"$disk\";"
    printf '%b\n\n' "$line"
  fi
  [[ -n $esp && $esp != /boot ]] && printf '  boot.loader.efi.efiSysMountPoint = "%s";\n\n' "$esp"
  printf '  networking.hostName = "%s";\n\n' "$name"
  printf '  system.stateVersion = "%s"; # the release it was installed with; never change it\n}\n' "$release"
}

# A name as a Nix attribute: bare when it can be, quoted otherwise
nix_attr() { if [[ $1 =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then printf '%s' "$1"; else printf '"%s"' "$1"; fi; }

# darwin-configuration.nix of a Mac. Args: name, user, nix-darwin state version
mac_config() {
  local user
  user=$(nix_attr "$2")
  cat <<EOF
# $1: written by scripts/bootstrap.sh on $(date +%F)
{
  imports = [ ../../modules/darwin/common.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "$1";
  networking.computerName = "$1";

  system.primaryUser = "$2";
  users.users.$user.home = "/Users/$2";
  home-manager.users.$user = import ../../home/darwin;

  system.stateVersion = $3; # never change it
}
EOF
}

# ---------- NixOS USB installer: a new PC, or a known one reinstalled

nixos_installer() {
  [[ $(uname -m) == x86_64 ]] || die "the PC config is x86_64-only (most of its apps are)"
  [[ -d /sys/firmware/efi ]] || die "the USB booted in legacy BIOS mode; boot it in UEFI mode (systemd-boot needs it)"
  get_checkout
  local name disk
  name=$(ask_name "Name for this machine (a known host, e.g. desktop-olivia, is reinstalled as it is)")
  if [[ -f hosts/$name/darwin-configuration.nix ]]; then
    die "hosts/$name is a Mac"
  elif [[ -f hosts/$name/configuration.nix ]]; then
    say "hosts/$name exists: reinstalling it with its own disk settings"
  else
    disk=$(pick_disk)
    mkdir -p "hosts/$name"
    sudo nixos-generate-config --no-filesystems --show-hardware-config >"hosts/$name/hardware-configuration.nix"
    # shellcheck disable=SC2046 # one word per GPU module
    pc_config "$name" "$(nixpkgs_release)" "$disk" "" $(gpu_modules) >"hosts/$name/configuration.nix"
    git add "hosts/$name"
    say "Wrote hosts/$name (disk $disk)"
  fi
  preflight "$name"
  add_login_art "$name"
  confirm_wipe "$name"

  say "Partitioning (disko asks once more)"
  sudo nix "${NIX_FLAGS[@]}" run --inputs-from . disko -- --mode destroy,format,mount --flake ".#$name" </dev/tty
  smb_secrets /mnt
  say "Installing; it asks for a root password at the end (emergency mode uses it)"
  sudo nixos-install --flake ".#$name" --no-channel-copy </dev/tty
  say "Password for olivia"
  sudo nixos-enter --root /mnt -c 'passwd olivia' </dev/tty
  # The config expects the checkout at ~/nixos-config (dotfile links, nh)
  sudo cp -a "$CHECKOUT" /mnt/home/olivia/
  sudo nixos-enter --root /mnt -c 'chown -R olivia:users /home/olivia/nixos-config'
  say "Done. Reboot into $name. Then:"
  cat >&2 <<EOF
  - commit and push hosts/$name from ~/nixos-config (gh auth login first)
  - the rest of the hand steps: README.md, "After setting up"
EOF
}

# ---------- NixOS, already installed: switch, or adopt it as a new host

nixos_installed() {
  get_checkout
  local host name esp
  host=$(hostname)
  if [[ -f hosts/$host/configuration.nix ]]; then
    say "This is $host: switching to hosts/$host"
    sudo nixos-rebuild switch --flake ".#$host"
    return
  fi
  [[ $(uname -m) == x86_64 ]] || die "the PC config is x86_64-only (most of its apps are)"
  [[ -d /sys/firmware/efi ]] || die "this system booted in BIOS mode; the config uses systemd-boot, which needs UEFI"
  say "hostname $host isn't in hosts/: adopting this install, keeping its disks and filesystems"
  name=$(ask_name "Name for this machine" "$host")
  [[ ! -e hosts/$name ]] || die "hosts/$name already exists"
  esp=$(sudo bootctl --print-esp-path 2>/dev/null || echo /boot)
  mkdir -p "hosts/$name"
  # With filesystems this time: they are the ones already on disk
  sudo nixos-generate-config --show-hardware-config >"hosts/$name/hardware-configuration.nix"
  # shellcheck disable=SC2046 # one word per GPU module
  pc_config "$name" "$(nixpkgs_release)" "" "$esp" $(gpu_modules) >"hosts/$name/configuration.nix"
  git add "hosts/$name"
  say "Wrote hosts/$name. Read it before going on; the bootloader becomes systemd-boot on $esp"
  preflight "$name"
  add_login_art "$name"
  confirm "Build it and make it the next boot entry?" || die "stopped; hosts/$name is left for you to edit"
  smb_secrets ""
  sudo nixos-rebuild boot --flake ".#$name"
  say "Reboot. olivia is created on boot without a password: from another account (or a TTY), run"
  echo "  sudo passwd olivia" >&2
  [[ $CHECKOUT == /home/olivia/nixos-config ]] || cat >&2 <<EOF
Then move the checkout to where the config expects it:
  sudo cp -a $CHECKOUT /home/olivia/ && sudo chown -R olivia:users /home/olivia/nixos-config
EOF
  echo "Commit and push hosts/$name afterwards." >&2
}

# ---------- NixOS-WSL

is_wsl() { [[ -n ${WSL_DISTRO_NAME:-} ]] || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; }

nixos_wsl() {
  get_checkout
  if [[ $(id -un) == olivia ]]; then
    sudo nixos-rebuild switch --flake .#wsl
    return
  fi
  # First run, as NixOS-WSL's default user. NixOS-WSL's steps for a new default user: build
  # with `boot` (not switch), then restart the distro twice (bootstrap.ps1 does that).
  say "Building hosts/wsl (default user olivia)"
  sudo nixos-rebuild boot --flake .#wsl
  # Same uid 1000 as olivia, so the copy keeps the right owner
  if [[ $CHECKOUT != /home/olivia/nixos-config ]]; then
    sudo install -d -o "$(id -u)" -g users -m 700 /home/olivia
    cp -a "$CHECKOUT" /home/olivia/
  fi
  say "Built. In Windows, restart the distro: wsl -t NixOS; wsl -d NixOS --user root exit; wsl -t NixOS"
}

# ---------- Nix itself (non-NixOS)

load_nix() {
  local f=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  command -v nix >/dev/null && return 0
  [[ -e $f ]] || return 1
  set +u
  # shellcheck disable=SC1090
  . "$f"
  set -u
}

ensure_nix() {
  load_nix && return 0
  say "Installing Nix (NixOS's nix-installer, flakes on)"
  local installer
  installer=$(mktemp)
  curl -sSfL https://artifacts.nixos.org/nix-installer -o "$installer"
  sh "$installer" install --enable-flakes </dev/tty
  rm -f "$installer"
  load_nix || die "Nix installed, but not found; open a new terminal and run this again"
}

# ---------- standalone home-manager (other Linux, WSL distros, a Mac without nix-darwin)

nix_system() { nixf config show system 2>/dev/null || nixf show-config | awk '$1 == "system" { print $3 }'; }

standalone_home() {
  local user system attr
  user=$(id -un)
  system=$(nix_system)
  attr="$user@$system"
  [[ $(nixf eval --raw .#homeConfigurations --apply "h: if h ? \"$attr\" then \"yes\" else \"no\"") == yes ]] ||
    die "no homeConfigurations.\"$attr\": add \"$user\" to standaloneUsers in flake.nix (system $system), git add, run again"
  say "home-manager switch to $attr (replaced dotfiles are kept as *.hm-backup)"
  nixf run --inputs-from . home-manager -- switch --flake ".#$attr" -b hm-backup </dev/tty
  if [[ $system == *-linux ]]; then
    local setup=$HOME/.nix-profile/bin/non-nixos-gpu-setup
    [[ -x $setup ]] || setup=${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager/home-path/bin/non-nixos-gpu-setup
    if [[ -x $setup ]] && confirm "GPU drivers for the Nix GUI apps need a one-time root step ($setup). Run it now?"; then
      sudo "$setup"
    fi
  fi
  local fish
  fish=$(command -v fish || true)
  [[ -n $fish ]] && say "To make fish the login shell: echo $fish | sudo tee -a /etc/shells && chsh -s $fish"
  return 0
}

other_linux() {
  case $(uname -m) in
    x86_64 | aarch64) ;;
    *) die "unsupported CPU $(uname -m)" ;;
  esac
  is_wsl && say "WSL distro: standalone home-manager (for full NixOS in WSL, run scripts/bootstrap.ps1 in Windows)"
  ensure_nix
  get_checkout
  standalone_home
}

# ---------- macOS

darwin_switch() {
  say "nix-darwin switch to hosts/$1 (installs the Homebrew and App Store apps too; the first run takes a while)"
  if command -v darwin-rebuild >/dev/null; then
    sudo darwin-rebuild switch --flake ".#$1"
  else
    nixf build ".#darwinConfigurations.$1.system"
    sudo ./result/sw/bin/darwin-rebuild switch --flake ".#$1" ||
      die "if it stopped at \"Unexpected files in /etc\", rename each listed file to <name>.before-nix-darwin and run this again"
  fi
}

new_mac_host() {
  local name user version
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    confirm "Homebrew isn't installed; nix-darwin declares the apps but needs it. Install it now (brew.sh)?" ||
      die "install Homebrew from https://brew.sh, then run this again"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
  fi
  user=$(id -un)
  name=$(ask_name "Name for this Mac (also becomes its hostname)" "$(scutil --get LocalHostName | tr '[:upper:]' '[:lower:]')")
  [[ ! -e hosts/$name ]] || die "hosts/$name already exists"
  version=$(nixf eval --raw .#darwinConfigurations --apply 'c: toString (builtins.head (builtins.attrValues c)).config.system.maxStateVersion')
  mkdir -p "hosts/$name"
  mac_config "$name" "$user" "$version" >"hosts/$name/darwin-configuration.nix"
  git add "hosts/$name"
  say "Wrote hosts/$name for user $user. Sign in to the App Store first, or the App Store apps fail."
  confirm "Switch to it now?" || die "stopped; hosts/$name is left for you to edit"
  darwin_switch "$name"
  say "Done. Commit and push hosts/$name. Hand steps: README.md, \"After setting up\"."
}

mac() {
  [[ $(uname -m) == arm64 ]] || die "Intel Macs aren't supported: nixpkgs 26.05 is the last release for them"
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    die "install the Command Line Tools from the dialog, then run this again"
  fi
  ensure_nix
  get_checkout
  local host
  host=$(scutil --get LocalHostName)
  if [[ -f hosts/$host/darwin-configuration.nix ]]; then
    darwin_switch "$host"
    return
  fi
  say "$host isn't in hosts/."
  echo "  1) take over this Mac with nix-darwin (apps, macOS settings, Touch ID sudo)" >&2
  echo "  2) home-manager only: CLI tools and dotfiles, nothing system-wide (a work Mac)" >&2
  case $(ask "Which? (1/2)") in
    1) new_mac_host ;;
    2) standalone_home ;;
    *) die "nothing chosen" ;;
  esac
}

main() {
  case $(uname -s) in
    Darwin) mac ;;
    Linux)
      if [[ ! -e /etc/NIXOS ]]; then
        other_linux
      elif is_wsl; then
        nixos_wsl
      elif [[ -d /iso || $(findmnt -no FSTYPE /) == tmpfs ]] && command -v nixos-install >/dev/null; then
        nixos_installer
      else
        nixos_installed
      fi
      ;;
    *) die "unsupported OS $(uname -s). On Windows, run scripts/bootstrap.ps1 in PowerShell." ;;
  esac
}

# Sourcing with BOOTSTRAP_SOURCED=1 loads the functions only (for testing)
[[ ${BOOTSTRAP_SOURCED:-} == 1 ]] || main "$@"

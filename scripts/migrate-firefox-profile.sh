#!/usr/bin/env bash
# Moves the Windows Firefox profile onto NixOS, keeping everything: add-ons and their
# settings/data (Sidebery panels & styles, uBlock filters, ScriptCat scripts, ...), themes,
# containers, logins, cookies, history, bookmarks, open tabs and prefs.
#
# Run on NixOS as olivia after the first `nh os switch`, with Firefox closed on BOTH systems:
#   ~/nix-config/scripts/migrate-firefox-profile.sh [WINDOWS_PROFILE_DIR]
set -euo pipefail

PROFILE=9ylnf32e.default-release
WIN_DIR='C:\Users\olivi\AppData\Roaming\Mozilla\Firefox\Profiles\'"$PROFILE"
WIN_URI="file:///C:/Users/olivi/AppData/Roaming/Mozilla/Firefox/Profiles/$PROFILE"
SRC=${1:-/mnt/windows/Users/olivi/AppData/Roaming/Mozilla/Firefox/Profiles/$PROFILE}
DST=${FIREFOX_PROFILE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox/$PROFILE}

die() { echo "error: $*" >&2; exit 1; }
warn() { echo "warning: $*" >&2; }

[ -f "$SRC/prefs.js" ] || die "no Firefox profile at $SRC (is /mnt/windows mounted? Windows Fast Startup must be off)"
[ -e "$DST/user.js" ] || die "$DST/user.js not found; run 'nh os switch' first so home-manager creates the profile"
command -v jq >/dev/null || die "jq is required"
if pgrep -u "$(id -u)" -x 'firefox|firefox-bin|\.firefox-wrappe' >/dev/null; then die "close Firefox first"; fi

# Version guard. The nixpkgs wrapper sets MOZ_ALLOW_DOWNGRADE=1, so Firefox itself won't stop
# an older build from opening (and possibly damaging) a profile last used by a newer one.
src_ver=$(sed -n 's/^LastVersion=\([^_]*\)_.*/\1/p' "$SRC/compatibility.ini" | tr -d '\r')
if [ -z "${SKIP_VERSION_CHECK:-}" ]; then
  nix_ver=$(firefox --version | sed 's/.* //')
  if [ "$(printf '%s\n%s\n' "$src_ver" "$nix_ver" | sort -V | tail -n1)" != "$nix_ver" ]; then
    die "the Windows profile was last used by Firefox $src_ver but NixOS has $nix_ver; run 'nh os switch --update' first"
  fi
fi
[ -f "$SRC/sessionstore.jsonlz4" ] || warn "no sessionstore.jsonlz4: Firefox on Windows may not have closed cleanly (open tabs might not restore)"

# Anything Firefox already wrote here (e.g. from launching it once) is moved aside, keeping
# home-manager's links (user.js, chrome/userChrome.css) in the fresh directory.
if [ -e "$DST/prefs.js" ]; then
  bak="$DST.before-migration-$(date +%Y%m%d-%H%M%S)"
  mv "$DST" "$bak"
  mkdir -p "$DST/chrome"
  for f in user.js chrome/userChrome.css .keep; do
    if [ -e "$bak/$f" ] || [ -L "$bak/$f" ]; then cp -P "$bak/$f" "$DST/$f"; fi
  done
  echo "previous contents moved to $bak"
fi

echo "copying $SRC -> $DST ..."
excludes=(
  ./parent.lock ./lock ./.parentlock
  ./compatibility.ini     # platform changed: makes Firefox re-check add-ons and caches
  ./addonStartup.json.lz4 # Windows add-on locations; rebuilt on start
  ./user.js ./chrome/userChrome.css # managed by home-manager
  ./gmp-widevinecdm ./gmp-gmpopenh264 # Windows DRM/codec DLLs; Firefox downloads Linux ones
  ./startupCache ./cache2 ./shader-cache ./jumpListCache ./thumbnails
  ./crashes ./minidumps ./datareporting ./saved-telemetry-pings
)
tar -C "$SRC" -cf - "${excludes[@]/#/--exclude=}" . | tar -C "$DST" -xf - --no-same-owner
chmod -R u+rwX,go-rwx "$DST"

# extensions.json stores absolute Windows paths for every profile add-on; point them here.
ext="$DST/extensions.json"
jq --arg win "$WIN_DIR" --arg winuri "$WIN_URI" --arg dst "$DST" '
  .addons |= map(
    if ((.path // "") | startswith($win)) then
      .path = $dst + (.path[($win | length):] | gsub("\\\\"; "/"))
      | .rootURI = ((.rootURI // "") | if startswith("jar:" + $winuri) then "jar:file://" + $dst + .[("jar:" + $winuri | length):]
                                       elif startswith($winuri) then "file://" + $dst + .[($winuri | length):]
                                       else . end)
    else . end)' "$ext" > "$ext.tmp"
mv "$ext.tmp" "$ext"
left=$(grep -o 'C:\\\\\|file:///C:' "$ext" | wc -l || true)
[ "$left" -eq 0 ] || warn "$left Windows paths remain in extensions.json (Firefox should still rescan them)"

# The only Windows path in prefs.js is the last download folder
sed -i '/"browser\.download\.lastDir"/d' "$DST/prefs.js"

n_addons=$(jq '[.addons[] | select(.location == "app-profile")] | length' "$ext")
n_active=$(jq '[.addons[] | select(.location == "app-profile" and .active)] | length' "$ext")
echo "done: $n_addons profile add-ons ($n_active enabled) carried over. Start Firefox normally."

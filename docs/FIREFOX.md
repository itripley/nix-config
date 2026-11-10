# Firefox

Goal: Firefox on NixOS behaves exactly like Firefox on Windows, with every extension and its settings,
Sidebery's panels and styles, themes, `userChrome.css`, logins, history and open tabs.

## What's in the Windows profile

Profile `9ylnf32e.default-release` (`%APPDATA%\Mozilla\Firefox\Profiles\`), Firefox **159.0.1**,
about 2 GB (mostly site storage).

| | |
|---|---|
| Extensions | **110** installed, **20 enabled** (Sidebery, uBlock Origin, Bitwarden, SponsorBlock, SingleFile, ScriptCat, Web Scrobbler, …) |
| Themes | **15**; active: *Sleeping Hatsune Miku Animated 2* |
| Language pack | pt-PT (installed; UI language is en-US) |
| `chrome/userChrome.css` | Sidebery companion styles. **Present but inactive** (see below) |
| Sidebery | v5.6.1 `{3c078156-…}` (a second, disabled old copy also exists); its data is in IndexedDB under `storage/default/moz-extension+++fa306da0-…` |
| Firefox Sync | signed in (oliviacmcarmo@gmail.com) |
| Native messaging | Bitwarden desktop bridge `com.8bit.bitwarden` |
| Startup | restores the previous session (`browser.startup.page = 3`), native vertical tabs on |

## The approach: migrate the profile, declare only the Linux-specific bits

### Why not declare the extensions in Nix?

home-manager *can* install extensions declaratively (e.g. from the NUR add-ons collection), but:

- **An extension's settings and data aren't part of the extension.** They live in the profile
  (`storage/default/moz-extension+++<uuid>/…`, `storage-sync-v2.sqlite`), keyed by a per-profile
  internal UUID. A fresh install gets a fresh UUID and **empty settings**: no Sidebery panels, no
  uBlock filter lists, no ScriptCat scripts.
- Nix-managed extensions can't be toggled or removed from `about:addons`, which fights the way this
  profile is used (90 extensions kept installed but disabled).
- Themes, containers, logins, cookies and the open session aren't declarable at all.

So the profile is **copied once**, and Nix declares only what has to differ on Linux.

### Declarative part: `home/olivia/firefox.nix`

| What | Why |
|---|---|
| Profile `default-release` with `path = "9ylnf32e.default-release"`, `isDefault` | Same directory name as Windows, so the copied data drops straight in and Firefox opens it by default. |
| `userChrome = ./dotfiles/firefox/userChrome.css` | Version-controlled; HM links it into `chrome/`. |
| `user.js` prefs (re-applied every start) | `toolkit.legacyUserProfileCustomizations.stylesheets = true` (load userChrome), `widget.use-xdg-desktop-portal.file-picker = 1` (KDE file dialogs), `media.ffmpeg.vaapi.enabled = true` (hardware video decode on the 7800 XT). Every other pref stays in the migrated `prefs.js`. |
| `nativeMessagingHosts = [ bitwardenNativeHost ]` | A manifest pointing at `bitwarden-desktop`'s `libexec/desktop_proxy`, allowed only for the Bitwarden extension ID. Same fields as the Windows manifest. Declared because the desktop app normally writes it at runtime, and its location must match the profile layout below. |

The system-wide `programs.firefox` is **not** enabled, so exactly one Firefox (159.0.1) is installed.

### Where the profile lives

With `home.stateVersion = "26.05"`, home-manager uses the XDG layout:
`~/.config/mozilla/firefox/9ylnf32e.default-release`, **not** the traditional `~/.mozilla/firefox`.
(Confirmed by reading the pinned home-manager source and by evaluating `programs.firefox.configPath`.)
HM writes `profiles.ini`, `user.js`, `chrome/userChrome.css` and a `.keep` there. Nothing else in the
profile is touched by HM, so it can't collide with the migrated data.

### userChrome.css: inactive on Windows, active on NixOS

Firefox 159 ships `toolkit.legacyUserProfileCustomizations.stylesheets = false` (checked in Firefox's
own `omni.ja` defaults), and the Windows profile never turned it on. So **`userChrome.css` has never
actually been applied on Windows.** You chose to activate it on NixOS. With Sidebery's panel open it
now hides the native tab strip, Firefox's new sidebar launcher and splitter, and the sidebar header,
and it shows the window buttons in the nav-bar.

**Fixed 2026-11-09:** the native sidebar (the vertical-tabs launcher) still showed with Sidebery
open. The rule hid `#sidebar-main`, but in Firefox 159 that id is gone: `<sidebar-main>` has no id
and its parent box is `#sidebar-container` (checked in 159.0.1's `omni.ja`). The rule now lists
`#sidebar-container` too, and keeps `#sidebar-main` for older versions. The `#sidebar-box[checked]`
condition still matches in 159: `browser-sidebar.js` sets `checked="true"` on that box.

A stray ` */` after the last rule was removed. It came after all real rules, so it hadn't been
cutting anything off.

To get the Windows look back, delete the `legacyUserProfileCustomizations` line in `firefox.nix`.

## Migration part: `scripts/migrate-firefox-profile.sh`

Run once on NixOS, as olivia, after the first `nh os switch`, with Firefox closed on both systems:

```sh
~/nixos-config/scripts/migrate-firefox-profile.sh            # reads from /mnt/windows
~/nixos-config/scripts/migrate-firefox-profile.sh /path/to/profile   # or another copy
```

What it does, in order:

1. **Preflight:** the source profile exists (`/mnt/windows` mounted; it needs Fast Startup off), the
   HM-managed profile exists (`user.js` present), `jq` is available, and Firefox isn't running.
2. **Version guard:** compares `LastVersion` in the Windows `compatibility.ini` with
   `firefox --version` and **refuses if Windows used a newer Firefox**. Opening a profile with an
   older Firefox can damage it. Firefox normally refuses on its own, but the nixpkgs wrapper sets
   `MOZ_ALLOW_DOWNGRADE=1`, which turns that protection off. Fix: `nh os switch --update`.
   (`SKIP_VERSION_CHECK=1` overrides; don't.)
3. **Clean-shutdown hint:** warns if `sessionstore.jsonlz4` is missing (open tabs may not restore).
4. **Backup:** if Firefox already created data here (e.g. it was launched once), the directory is
   moved to `…before-migration-<timestamp>` and HM's links are restored into a fresh one.
5. **Copy** everything except:

   | Excluded | Why |
   |---|---|
   | `parent.lock`, `lock`, `.parentlock` | Lock files of the Windows instance. |
   | `compatibility.ini` | Records the Windows build/platform; removing it makes Firefox treat this as a platform change and re-check add-ons and caches. |
   | `addonStartup.json.lz4` | Cached add-on locations (Windows paths); rebuilt on start. |
   | `user.js`, `chrome/userChrome.css` | Managed by home-manager. |
   | `gmp-widevinecdm`, `gmp-gmpopenh264` | Windows DRM/codec DLLs; Firefox downloads the Linux versions. |
   | `startupCache`, `cache2`, `shader-cache`, `jumpListCache`, `thumbnails`, crash/telemetry dirs | Caches and Windows-only data. |

   Then permissions are set private (dirs 700, files 600). NTFS mounts show everything as 755/777.
6. **Fix add-on paths:** `extensions.json` stores absolute Windows paths for every profile add-on
   (`path` = `C:\Users\…\extensions\{id}.xpi`, `rootURI` = `jar:file:///C:/Users/…/{id}.xpi!/`).
   `jq` rewrites both to the new location. Built-in add-ons (`resource://…`) are untouched, and
   enabled/disabled state is preserved. Together with step 5 (no `compatibility.ini` /
   `addonStartup.json.lz4`) Firefox also rescans, so either mechanism alone should be enough.
7. **prefs.js:** removes `browser.download.lastDir`, the only Windows path in it.
8. Prints how many add-ons were carried over.

Logins (`logins.json` + `key4.db`), cookies, history, bookmarks, containers, themes and the
Sidebery/extension storage are all portable files, copied as-is.

## After migrating

- Firefox Sync stays signed in. If it asks, sign in again; nothing is lost.
- Bitwarden: in the desktop app enable *Settings → Allow browser integration*, then in the extension
  *Settings → Unlock with biometrics / desktop app*.
- The Windows and NixOS profiles are now **independent copies**. Firefox Sync keeps bookmarks,
  history, passwords and the add-on list in step; it does **not** sync extension settings or
  Sidebery panels. Sidebery has its own sync (Settings → Sync) if you want panels shared.
- Editing `userChrome.css`: change it in the repo, then `nh os switch`.

## Testing done and not done

- ✅ The config evaluates, and the generated `profiles.ini`, `user.js` and native-messaging host were
  inspected (see [VERIFICATION.md](VERIFICATION.md)).
- ✅ The script was run against a **mock profile** built from the real `extensions.json` and
  `compatibility.ini` plus dummy data, using the same pinned nixpkgs tools NixOS will have. All 136
  add-on records were kept, paths rewritten, enabled/disabled state identical, Sidebery data copied,
  excluded files skipped, HM links intact, permissions 700/600, backup made. A newer-version profile
  was correctly refused.
- ✅ **Ran on the install (2026-11-08).** Windows and NixOS both had Firefox 159.0.1, and Windows had
  closed Firefox cleanly (`sessionstore.jsonlz4` written at shutdown). Output: `126 profile add-ons
  (22 enabled) carried over`. The fresh profile Firefox had created on first launch was moved to
  `~/.config/mozilla/firefox/9ylnf32e.default-release.before-migration-20261108-222716`
  (delete it once the migrated profile is confirmed good).
- ❓ **Still to confirm by eye:** add-ons, Sidebery panels, logins and open tabs after opening Firefox.
  If add-ons show as missing, they're all in Firefox Sync's add-on list to reinstall from, though
  without their settings. The backup and the untouched Windows original mean the copy can always be
  redone.

# Ice 27 builds and verification

This branch uses Ice PR #997 at
`c3df598f36100b0500fd159a1cfd9ac5d2dc2525`, including its macOS 26 prerequisites.
Upstream architecture and attribution remain in [MACOS27.md](../MACOS27.md).
This is a local fork, not an official upstream release.

## Build

Requires full Xcode 27 on an Apple Silicon Mac. No iOS simulator is needed.

```sh
bash Scripts/test-macos27.sh
bash Scripts/package-release.sh
```

Packages and SHA-256 checksums are written to `build/release/` (ignored by Git).
Both DMG and ZIP contain the app, license and Chinese usage notes. Debug builds remain available through `Scripts/build-debug.sh`.

Release uses optimized compilation, no debugger-attachment entitlement or
preview dylib, and no upstream update feed. The internal bundle identifier
`com.jordanbaird.Ice.macos27debug` is deliberately retained for settings and TCC
continuity; the displayed application name is Ice 27.

## Signing

`Scripts/sign-local.py` creates a persistent local development certificate on
first use and reuses it for subsequent builds on the same Mac.
Its private, nonextractable key lives in a dedicated keychain under
`~/Library/Application Support/IceLocalDevelopmentSigning`. Nothing in that
directory is packaged or committed. Do not remove it: replacing the certificate
changes application identity and can invalidate privacy grants. Signing does
not change system certificate trust or the default/search-list keychains.

Generated packages use a self-signed development identity, not a Developer ID
identity, and are not notarized. Public pre-releases are experimental and have
not been validated on a clean Mac; Gatekeeper may block downloaded builds. The native-compatibility build retains the tested runtime
configuration. To verify identity continuity on a disposable changed copy:

```sh
python3 Scripts/test-signing-continuity.py "$HOME/Applications/Ice 27.app"
```

## Local fixes

- Match hosted menu-bar geometry by identity, avoiding stale concealed frames.
- Reveal native overflow and verify stable geometry before a requested move.
- Infer section membership only from drawn items. At launch, keep spacers withdrawn,
  reveal native overflow, refresh all owners and capture images before hiding.
  Layout uses the same discovery path.
- Resolve newly published boundaries live for moves into empty sections.
- Use persistent signing to preserve privacy grants across local rebuilds.
- Anchor newly opened, movable Ice Bar popups under Ice's menu-bar button.
  Watch window notifications before opening and use immediate, bounded polling
  to reduce repositioning delay. Existing unrelated windows are left alone.

## Verification

Ten standalone test suites pass, including 14 hosted-geometry and six popup
positioning cases. Tests cover ordering, dynamic ownership, visibility, image
cropping, display geometry, native bridging and invalid/stale coordinates.

On macOS 27.0 (26A428), local runtime checks confirmed item enumeration and
images, physical move commits, hiding/revealing Joplin, actual drag restoration,
restart section recovery, and retained accessibility/screen-capture grants
across signed binary updates. State's popup was verified below Ice's menu-bar button.
The notification build removes avoidable delay; first-frame animation remains
controlled by the third-party application.

## Restart regression check

With macOS native overflow collapsed, quit Ice with Settings on General, then
relaunch and open Ice Bar without visiting Layout. The startup log should show
`Launch discovery completed: hidden=10` for this machine's current arrangement,
and Ice Bar should contain all ten images (including six State items and Lark).
Repeat after another quit. The prior build initially assigned only two hidden
items in this scenario; the recovery must run before Ice conceals them again.
No new privacy permission or changed section setting should be needed.

## Limitations and usage

See [Chinese release notes](RELEASE-NOTES.zh-CN.md). Startup discovery may briefly
expand the native menu bar to refresh anonymous items. Multiple displays and older
macOS versions have not been tested locally. Keep one running Ice instance.

# macOS 27 support

macOS 27 moved every status item into `MenuBarAgent`, which draws them into a
single bar. There are no per-item windows any more, and an oversized status
item (Ice's old 10,000-point divider) is discarded instead of pushing other
items off screen. This is why older Ice builds show "Loading menu bar items"
and hide nothing on macOS 27.

This branch builds on the upstream `macos-26` branch and the experimental
macOS 27 work from [jordanbaird/Ice#980](https://github.com/jordanbaird/Ice/pull/980),
with additional hardening. Every macOS 27 path is gated on
`#available(macOS 27.0, *)`.

## What works on macOS 27

- Hiding and showing the Hidden section with Ice's button or a hotkey.
- The Always Hidden section (Option-click or hotkey), with a safety check.
- The Menu Bar Layout editor: item thumbnails and moving items between sections.
- Menu bar appearance settings.
- Native input for every other item. The clock still opens Notification Center.

## What doesn't

- The Ice Bar, search panel, show on hover/click/scroll, auto-rehide, item
  spacing and app-menu hiding are disabled on macOS 27.
- Hidden items move into Apple's native overflow (the « button), so they are
  still reachable from there.
- Toggling very quickly can leave fading icons for a moment.
- Clock, Control Center and other items hosted by `MenuBarAgent` can't be
  dragged from the Layout editor. You can still Command-drag them yourself.
- Opening the Layout editor shows every item until you leave it.

## How it works

**Enumeration.** Items are read through Accessibility from each running app's
extras menu bar. Items without a stable identifier are tracked by process-local
AX equality, so labels that change (such as a CPU percentage) keep their tile.

**Hiding.** Ice owns a blank status item immediately to the left of its visible
button. To hide, Ice widens it to fit the native status region, so
`MenuBarAgent`'s own overflow takes everything to its left. To show, Ice
withdraws it, because even a one-point item reserves a visible slot. No private
API is used.

**Alignment.** Before hiding, Ice checks through its own accessibility frames
that the blank item sits directly left of its button. If it doesn't, for example
after you Command-dragged items across Ice, Ice moves only its own blank item
with one native Command-drag.

**Layout.** Moving an item between sections performs a native Command-drag and
then verifies the new order through Accessibility.

**Thumbnails.** One screenshot of the menu bar strip is cropped using fresh AX
frames, and the glyph is separated from the bar's background. Screen Recording
is only needed for these thumbnails.

## Hardening in this branch

- Ice never drags its boundary without a user action. Launch and background
  refreshes leave items expanded if alignment would need a drag. A click or
  hotkey within the last 3 seconds allows it.
- Native drags wait for you to stop typing, moving the pointer, and holding
  modifiers or buttons, and give up after 5 seconds. While the synthetic
  Command key is down, physical keyboard and mouse input is suppressed, so a
  keystroke can't become a Command shortcut.
- The Layout editor can't drag items hosted by `MenuBarAgent`. Synthetic drags
  of those items crashed `MenuBarAgent` during testing of #980.
- After a spacer is widened, Ice confirms that its own button is still on the
  bar. If not (for example, if the Always Hidden spacer landed to the right of
  Ice), it withdraws the spacers and shows everything.
- `MenuBarItemService` accepts ad-hoc-signed builds
  ([jordanbaird/Ice#950](https://github.com/jordanbaird/Ice/pull/950)).
- Probe tools that posted real input or used the private assessment-mode API
  were removed.

## Building

You need Xcode 27. SwiftUI's `@State` is a macro in the macOS 27 SDK, and its
plugin only ships with Xcode, so Command Line Tools can't build Ice.

To build a locally signed copy without an Apple Developer team:

```sh
xcodebuild -project Ice.xcodeproj -scheme Ice -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  build
```

Copy `build/Build/Products/Release/Ice.app` to `/Applications`, then grant
Accessibility (required) and Screen Recording (optional) when asked. An ad-hoc
signature changes on every build, so macOS may ask for these permissions again
after you rebuild.

## Unit tests

The decision logic has standalone tests that build with `swiftc`:

```sh
xcrun swiftc -O Ice/MenuBar/MenuBarItems/MacOS27NativeBoundary.swift \
  Tests/NativeMenuBarBoundaryTests.swift -o /tmp/ice-boundary-tests && /tmp/ice-boundary-tests
xcrun swiftc -O Ice/MenuBar/LayoutBar/MenuBarGlyphImage.swift \
  Tests/MenuBarGlyphImageTests.swift -o /tmp/ice-glyph-image-tests && /tmp/ice-glyph-image-tests
```

## Attribution

The macOS 27 compatibility work is by PWB97 in
[jordanbaird/Ice#980](https://github.com/jordanbaird/Ice/pull/980).
Accessibility enumeration was adapted from the GPLv3
[Thaw project](https://github.com/thaw-app/Thaw).

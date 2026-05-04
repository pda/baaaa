# Baaaa 🐑

A modern macOS desktop pet that walks around your screen, falls under
gravity, and lands on top of your application windows — inspired by the
classic Windows eSheep / [desktopPet](https://adrianotiger.github.io/desktopPet/).

Written in Swift + AppKit. No Xcode required to build — uses Swift
Package Manager and a small Makefile to assemble a `.app` bundle.

## Requirements

- macOS 13 (Ventura) or newer
- Swift 5.9+ toolchain (`swift --version`)

## Run

```sh
swift run -c release
```

A 🐑 icon appears in the menu bar; the sheep is dropped from the top of
your main display, falls until it meets either the bottom of the screen
or the top edge of an application window, then strolls around. Walking
off an edge makes it fall again.

## Build a `.app` bundle

```sh
make app          # produces ./Baaaa.app
open Baaaa.app    # or `make open`
```

The bundle is registered as an `LSUIElement` (menu-bar accessory) so it
won't clutter the Dock or `⌘-Tab` switcher.

## Sign the app

By default the bundle is signed ad hoc for local use:

```sh
make app
make verify
```

To sign with a real Apple certificate, pass the identity name from your
keychain:

```sh
make sign-identities
make app SIGN_IDENTITY='Apple Development: Your Name (TEAMID)'
make verify SIGN_IDENTITY='Apple Development: Your Name (TEAMID)'
```

`Apple Development` signatures are suitable for local development, but
Gatekeeper will still reject them for general distribution. Use a
`Developer ID Application` identity if you want `spctl` to pass and the
app to open cleanly on other Macs.

If you need custom entitlements, pass an entitlements plist too:

```sh
make app \
  SIGN_IDENTITY='Apple Development: Your Name (TEAMID)' \
  ENTITLEMENTS='Resources/YourApp.entitlements'
```

## Controls

Click and drag a sheep with the mouse to pick it up and reposition it;
when you release, it falls from wherever you let go and resumes its
business on the next surface it meets.

Click the 🐑 in the menu bar for:

- **New Sheep** — spawn another sheep
- **Remove All** — clear the flock and start over with one
- **About Baaaa**
- **Quit**

## How it works

- Each sheep lives in its own borderless, transparent `NSWindow` at
  `.floating` level so it sits above ordinary windows. The window
  accepts mouse events (so you can grab the sheep) but never becomes
  key or main, so it doesn't steal focus from the app underneath.
- A 30 Hz timer steps a tiny physics model with four modes —
  *falling* (gravity + terminal velocity), *dazed* (a brief
  impact-bounce → stars-spinning → sit-up sequence played after
  landing from a real fall, lifted from the upstream eSheep
  `fall soft` animation), *walking* (constant horizontal speed with
  occasional pauses and direction flips), and *dragging* (position
  driven directly by the cursor) — and chooses the next sprite frame
  accordingly.
- For "land on top of any window", the controller queries
  `CGWindowListCopyWindowInfo` each tick, filters to ordinary
  application windows (`kCGWindowLayer == 0`), and treats the highest
  window-top below the sheep as ground. Occluders in front of a
  candidate window are subtracted from its top edge as 1-D x-spans, so
  the sheep only walks on the *visible* portion of a partially-covered
  window — at least 40% of its footprint must overlap a visible span
  before that window counts as walkable.
- `CGWindowListCopyWindowInfo` returns lots of "ghost" entries from
  other Spaces, off-screen Stage Manager stages, and hidden
  Electron-style background windows, with no reliable way to tell them
  apart from windows the user can actually see. To stay sane the
  controller restricts surface candidates to windows owned by the
  user's currently frontmost application, tracked via
  `NSWorkspace.didActivateApplicationNotification` in
  `FrontmostApp.swift`. Our own process is deliberately never recorded
  as frontmost, so clicking the 🐑 status item doesn't strand the
  sheep.
- The sprite sheet is a 16×11 grid of 40×40 tiles taken from the eSheep
  project. Magenta (`#FF00FF`) is stripped to alpha at load time, and
  tiles are rendered into a `CALayer` with nearest-neighbour
  magnification so the pixel art stays crisp at 2× display scale.

## Limitations

- Only the windows of the currently frontmost application are treated
  as walkable surfaces. Switch apps and the sheep re-targets onto the
  newly-frontmost app's windows (and falls if its current perch is no
  longer in scope). This is a deliberate trade-off to dodge the ghost
  windows returned by `CGWindowListCopyWindowInfo` on modern macOS
  with Stage Manager and multiple Spaces.

## Credits & licensing

Sprite art: **eSheep** by Adriano Petrucci — see
<https://github.com/Adrianotiger/desktopPet>. The eSheep project and its
art are distributed under the GNU GPL; the bundled `esheep.png` sprite
sheet inherits that licence. The Swift code in this repository is
provided under the same terms.

# Baaaa 🐑

A modern macOS desktop pet that walks around your screen, falls under
gravity, and lands on top of your application windows — a love letter
to the classic Windows "screen mate" sheep that wandered countless
desktops in the 1990s.

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

For accurate Dock perching, macOS may ask you to grant Accessibility
access so Baaaa can read the Dock's on-screen bounds.

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
- The sheep now treats the Dock as a real finite platform instead of a
  full-width screen strip. Its bounds come from the Dock process's
  accessibility `AXList` elements, converted from top-left AX screen
  coordinates into AppKit space; if Accessibility access isn't granted,
  the sheep falls to the desktop bottom instead.
- Grass tufts occasionally spawn on the Dock using spare eSheep sprite
  tiles. When a sheep is walking on the Dock it turns toward the nearest
  tuft, plays the nibble animation once it reaches the grass, then the
  tuft disappears and a later one respawns.
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

## Credits, history & licensing

Baaaa stands on the shoulders of a long line of "screen mate" sheep,
each one redrawing or reimplementing the work that came before it.

- **Tatsutoshi Nomura — *Stray Sheep* (1994).** The character was
  created by Japanese animator Tatsutoshi Nomura for the *Stray Sheep*
  series of five-minute animated shorts shown at midnight on
  [Fuji Television](https://www.fujitv.co.jp/straysheep/). The sheep
  later spawned books, merchandise, and even PlayStation games.
- **Village Center, Inc. — *Stray Sheep: The Screen Mate* (1995).**
  Under licence from Fuji TV,
  [Village Center](http://web.archive.org/web/20060625192044/www.villagecenter.co.jp/english/poe.html)
  published the original 16-bit Windows 3.1 / 95 retail "Screen Mate"
  that walks on top of your windows, falls off the edges, and otherwise
  wanders your desktop. This is the program that defined the genre, and
  every later sheep — including this one — is descended from it. It was
  variously known as Stray Sheep, Sheep, Scmpoo, and Screen Mate Poo.
- **Sheep / Screen Mate Poo (English release).** The English-language
  port of the Village Center program is the version most Western users
  remember; the
  [mentadd.com sheep page](https://mentadd.com/sheep/) preserves the
  original installer, its help file, and a careful accounting of the
  copyright information that later releases tended to discard.
- **Adriano Petrucci — *eSheep / desktopPet* (2005, ongoing).**
  Adriano Petrucci's
  [eSheep / desktopPet](https://adrianotiger.github.io/desktopPet/)
  project rebuilt the screen mate as a 64-bit Windows application so
  the sheep could keep walking on modern hardware. The bundled
  `esheep.png` sprite sheet in this repository — a 16×11 grid of 40×40
  tiles, with magenta as the transparent colour — comes from that
  project (image rip credited there to *LiL_Stenly*), and the
  *fall soft* dazed-after-landing animation sequence in Baaaa was
  lifted directly from eSheep's animation script.

Baaaa itself is just a fresh Swift + AppKit reimplementation of the
same idea for macOS — none of the original Village Center code is
present, but the behaviour, the silhouette, and the sprite sheet all
descend from the work above. All credit for the character, art, and
the screen-mate concept belongs to those creators; any bugs in this
port are mine.

The eSheep project and its sprite art are distributed under the
**GNU GPL**, so the bundled `esheep.png` inherits that licence and the
Swift code in this repository is released under the same terms.

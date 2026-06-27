# Mango 🐾🥭

[![CI](https://github.com/lasyapriyakatkam/Mango/actions/workflows/ci.yml/badge.svg)](https://github.com/lasyapriyakatkam/Mango/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform: macOS 13+](https://img.shields.io/badge/platform-macOS%2013%2B-blue)

Meet **Mango** — a native macOS desktop pet. A little orange-tabby cat that
lives on top of all your windows, inspired by
[comnyang](https://www.comnyang.com/). Built with Swift + AppKit, no external
dependencies, and all artwork is drawn programmatically (original vector art,
not comnyang's assets).

## Behaviors

- **Wander** — walks and runs around the bottom of the screen, changing
  direction on its own.
- **Idle / sit / sleep** — pauses, sits, and curls up for a nap with a rising
  `z z z`; blinks while awake.
- **Drag** — grab the cat with the mouse and fling it; it reacts with surprise
  and gets thrown with real momentum.
- **Gravity & falling** — when released or knocked off a ledge it falls, bounces
  off the screen sides, and lands.
- **Click** — a quick click (no drag) gets a happy `^^` reaction.
- **Climb & hang on window edges** — detects the top edges of your real
  application windows, lands and walks along them, paces back at the ends, and
  sometimes clings and hangs off the edge before climbing back up.

## Install

Mango is currently distributed as source — you build it once, then keep the
`.app` like any other application. (No prebuilt download yet; the binary is
unsigned, so building it yourself is the cleanest route.)

**1. Get the code & build it.** You need the Xcode Command Line Tools (Swift) —
install them with `xcode-select --install` if you don't have them. No Homebrew
or Xcode IDE required.

```bash
git clone https://github.com/lasyapriyakatkam/Mango.git
cd Mango
./build.sh            # produces ./Mango.app
```

**2. Move it to Applications** (so it lives with your other apps):

```bash
mv ./Mango.app /Applications/
```

**3. Launch it:**

```bash
open /Applications/Mango.app
```

> **First launch:** because the app isn't code-signed, macOS may say it "cannot
> be opened." Either **right-click `Mango.app` → Open → Open**, or clear the
> quarantine flag once:
> ```bash
> xattr -dr com.apple.quarantine /Applications/Mango.app
> ```

**Launch at login (optional):** System Settings → General → Login Items → add
`Mango.app`, so Mango greets you every time you start your Mac.

**Uninstall:** quit from the 🐾 menu, then `rm -rf /Applications/Mango.app`.

## Usage

The app has no Dock icon (it's a menu-bar agent). Control Mango from the **🐾**
menu in the menu bar:

- **Come Here** — teleports Mango to your mouse and drops him there.
- **Toggle Sleep** — put him to sleep / wake him.
- **Quit Mango** — exit.

### Mouse controls

| Action | Result |
|--------|--------|
| Click the cat | happy reaction |
| Click & drag | pick up and throw it |

Clicks anywhere *off* the cat pass straight through to the app underneath, so it
never gets in your way.

## How it works

| File | Role |
|------|------|
| `Sources/Mango/main.swift` | Entry point; runs as an accessory (menu-bar) app. |
| `AppDelegate.swift` | Creates the full-screen transparent overlay panel, the 60 fps update loop, the menu-bar item, and per-frame click-through toggling. |
| `PetPanel.swift` | The non-activating floating panel + the view that draws the cat and forwards mouse events. |
| `Pet.swift` | State machine + physics: wandering AI, gravity, dragging/throwing, landing on shelves, edge climbing/hanging. |
| `CatRenderer.swift` | Draws the cat in every pose with Core Graphics vector primitives. |
| `WindowEdges.swift` | Uses `CGWindowList` to find the top edges of on-screen windows (no special permission needed — only window *bounds* are read). |
| `Tools/preview.swift` | Dev-only: renders each pose to a PNG for inspection. Not part of the app. |

## Notes & limitations

- Runs on the **main display** only; multi-monitor support isn't implemented yet.
- Window-edge detection reads window geometry via `CGWindowList`, which needs no
  permissions. If edges ever seem stale, it's because the list is polled ~every
  0.6 s.
- The overlay floats at the status-bar window level, so it sits above ordinary
  windows. It will not appear above other always-on-top status-level windows.

## Ideas to extend

- Multi-monitor roaming.
- More characters / color skins (swap the palette in `CatRenderer`).
- Drop-in PNG sprite sheets instead of vector art.
- Feeding / petting interactions, a settings window, launch-at-login.

## Contributing

Contributions are very welcome — bug fixes, new behaviors, new color skins, or
multi-monitor support. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for how to
build, run, and submit changes, and the
[Code of Conduct](CODE_OF_CONDUCT.md). Good first issues:

- Add a new color skin by tweaking the palette in `CatRenderer.swift`.
- Make Mango roam across multiple displays.
- Add a "launch at login" toggle.

## License

MIT — see [LICENSE](LICENSE). Contributions welcome.

Inspired by [comnyang](https://www.comnyang.com/), but **not affiliated** with
it. All artwork here is original and drawn programmatically; no comnyang assets
are used.

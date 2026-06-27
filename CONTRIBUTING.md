# Contributing to Mango 🐾

Thanks for your interest in helping Mango! This is a small, friendly project and
contributions of all sizes are welcome — typo fixes, new behaviors, art tweaks,
docs, or bigger features.

## Prerequisites

- **macOS 13+**
- **Xcode Command Line Tools** (provides `swift`/`swiftc`):
  ```bash
  xcode-select --install
  ```

No Homebrew, Node, or full Xcode IDE required.

## Build & run

```bash
./build.sh        # compiles Sources/Mango/*.swift into ./Mango.app
open ./Mango.app  # launches it (quit from the 🐾 menu-bar icon)
```

`build.sh` compiles every Swift file in `Sources/Mango/`, assembles the
`Mango.app` bundle, and copies in `Info.plist` and the icon.

## Project layout

| Path | Role |
|------|------|
| `Sources/Mango/main.swift` | Entry point; runs as a menu-bar accessory app. |
| `Sources/Mango/AppDelegate.swift` | Overlay panel, 60 fps update loop, menu-bar item, click-through. |
| `Sources/Mango/PetPanel.swift` | Transparent floating panel + the view that draws Mango and handles the mouse. |
| `Sources/Mango/Pet.swift` | State machine + physics: wander AI, gravity, drag/throw, shelves, climbing/hanging. |
| `Sources/Mango/CatRenderer.swift` | Draws Mango in every pose with Core Graphics vector primitives (no image assets). |
| `Sources/Mango/WindowEdges.swift` | Finds window top-edges via `CGWindowList` so Mango can climb them. |
| `Tools/preview.swift` | Dev tool: renders each pose to a PNG for inspection. |
| `Tools/makeicon.swift` | Dev tool: renders the app icon master from the live art. |
| `build.sh` | Builds the `.app` bundle. |

## Working on the art

All art is vector-drawn in `CatRenderer.swift`. To eyeball poses without
launching the full overlay, render them to PNGs:

```bash
cp Tools/preview.swift /tmp/main.swift
swiftc -O -framework AppKit \
    Sources/Mango/Pet.swift Sources/Mango/CatRenderer.swift /tmp/main.swift \
    -o /tmp/preview && /tmp/preview
# writes Tools/preview-<pose>.png
```

To regenerate the app icon after art changes, do the same with
`Tools/makeicon.swift`, then rebuild the `.icns`:

```bash
sips ... # see the commands in the project history, or just run makeicon + iconutil
iconutil -c icns Tools/AppIcon.iconset -o Tools/AppIcon.icns
```

## Coding style

- Match the surrounding code: 4-space indentation, clear names, `// MARK:`
  sections.
- Keep comments focused on *why*, not *what*.
- Coordinates are bottom-left origin, y-up, in the overlay view's space; `pos`
  is Mango's feet (bottom-center of the sprite). Keep new physics in those units.

## Submitting a change

1. Fork the repo and create a branch: `git checkout -b my-feature`.
2. Make your change. Run `./build.sh` and launch the app to confirm it works.
3. Commit with a clear message describing the change and why.
4. Open a Pull Request. Describe what you changed and include a screenshot/GIF
   if it affects how Mango looks or moves.

CI will build the app on macOS for every PR — please make sure it's green.

## Reporting bugs / ideas

Open an issue using the templates. For bugs, include your macOS version and
steps to reproduce. For features, describe the behavior and why it'd be fun or
useful.

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).

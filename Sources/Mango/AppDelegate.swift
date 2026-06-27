import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panels: [PetPanel] = []          // one overlay window per display
    private var views: [PetView] = []
    private var pet: Pet!
    private var timer: Timer?
    private var statusItem: NSStatusItem!

    private var unionRect: CGRect = .zero
    private var lastTick: TimeInterval = 0
    private var shelfClock: Double = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        let union = desktopUnion()
        unionRect = union
        let main = NSScreen.main ?? NSScreen.screens.first!

        pet = Pet(bounds: union.size)
        pet.pos = CGPoint(x: main.frame.midX - union.minX, y: main.frame.minY - union.minY)
        pet.setFloors(buildFloors(union))

        buildOverlays(union)
        setupStatusItem()
        refreshShelves()

        // Rebuild when displays are added/removed/rearranged.
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        lastTick = ProcessInfo.processInfo.systemUptime
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)         // keep animating during mouse tracking
        timer = t
    }

    // MARK: Display geometry

    /// Bounding box (in global AppKit coordinates) covering every display.
    private func desktopUnion() -> CGRect {
        var r = CGRect.null
        for s in NSScreen.screens { r = r.union(s.frame) }
        return r.isNull ? (NSScreen.main?.frame ?? .zero) : r
    }

    /// One floor segment per display, in the overlay's local (union) space.
    private func buildFloors(_ union: CGRect) -> [Shelf] {
        NSScreen.screens.map { s in
            Shelf(y: s.frame.minY - union.minY,
                  xMin: s.frame.minX - union.minX,
                  xMax: s.frame.maxX - union.minX,
                  isFloor: true)
        }
    }

    /// Create one transparent overlay window per display. A single window can't
    /// span displays when "Displays have separate Spaces" is on (the default),
    /// so we give each display its own and share one cat across them.
    private func buildOverlays(_ union: CGRect) {
        for screen in NSScreen.screens {
            let frame = screen.frame
            let panel = PetPanel(contentRect: frame,
                                 styleMask: [.borderless, .nonactivatingPanel],
                                 backing: .buffered, defer: false)
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.level = .statusBar
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary,
                                        .fullScreenAuxiliary, .ignoresCycle]

            let offset = CGPoint(x: frame.minX - union.minX, y: frame.minY - union.minY)
            let view = PetView(frame: NSRect(origin: .zero, size: frame.size),
                               pet: pet, screenOffset: offset)
            view.wantsLayer = true
            panel.contentView = view
            panel.setFrame(frame, display: true)
            panel.orderFrontRegardless()

            panels.append(panel)
            views.append(view)
        }
    }

    @objc private func screensChanged() {
        let union = desktopUnion()
        unionRect = union
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        views.removeAll()
        pet.bounds = union.size
        pet.setFloors(buildFloors(union))
        buildOverlays(union)
        refreshShelves()
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        var dt = now - lastTick
        lastTick = now
        if dt > 0.1 { dt = 0.1 }                       // clamp after sleep/stalls

        pet.update(dt: dt)

        // Click-through everywhere except when the pointer is over the cat.
        let m = NSEvent.mouseLocation
        let mouseUnion = CGPoint(x: m.x - unionRect.minX, y: m.y - unionRect.minY)
        let interactive = pet.dragging || pet.catRect.contains(mouseUnion)
        for panel in panels { panel.ignoresMouseEvents = !interactive }

        for view in views { view.needsDisplay = true }

        shelfClock += dt
        if shelfClock >= 0.6 {
            shelfClock = 0
            refreshShelves()
            pet.revalidateGround()
        }
    }

    private func refreshShelves() {
        pet.shelves = WindowEdges.shelves(unionOrigin: unionRect.origin,
                                          unionSize: unionRect.size,
                                          excluding: panels.first?.windowNumber ?? -1)
    }

    // MARK: Status bar menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🐾"

        let menu = NSMenu()
        let header = menu.addItem(withTitle: "Hi, I'm Mango! 🐾", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(.separator())
        menu.addItem(withTitle: "Come Here", action: #selector(comeHere), keyEquivalent: "c").target = self
        menu.addItem(withTitle: "Toggle Sleep", action: #selector(toggleSleep), keyEquivalent: "s").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Mango", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    @objc private func comeHere() {
        let m = NSEvent.mouseLocation
        pet.comeTo(CGPoint(x: m.x - unionRect.minX, y: m.y - unionRect.minY))
    }

    @objc private func toggleSleep() { pet.toggleSleep() }

    @objc private func quit() { NSApp.terminate(nil) }
}

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: PetPanel!
    private var view: PetView!
    private var pet: Pet!
    private var timer: Timer?
    private var statusItem: NSStatusItem!

    private var lastTick: TimeInterval = 0
    private var shelfClock: Double = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = screen.frame

        pet = Pet(bounds: frame.size)
        pet.pos = CGPoint(x: frame.width * 0.5, y: 0)

        panel = PetPanel(contentRect: frame,
                         styleMask: [.borderless, .nonactivatingPanel],
                         backing: .buffered,
                         defer: false)
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar                     // float above ordinary windows
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true              // toggled per-frame when over the cat
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary,
                                    .fullScreenAuxiliary, .ignoresCycle]

        view = PetView(frame: NSRect(origin: .zero, size: frame.size), pet: pet)
        view.wantsLayer = true
        panel.contentView = view
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()

        setupStatusItem()
        refreshShelves(screenFrame: frame, viewSize: frame.size)

        lastTick = ProcessInfo.processInfo.systemUptime
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)         // keep animating during mouse tracking
        timer = t
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        var dt = now - lastTick
        lastTick = now
        if dt > 0.1 { dt = 0.1 }                       // clamp after sleep/stalls

        pet.update(dt: dt)

        // Click-through everywhere except when the pointer is over the cat.
        if pet.dragging {
            panel.ignoresMouseEvents = false
        } else {
            let m = NSEvent.mouseLocation
            let local = CGPoint(x: m.x - panel.frame.minX, y: m.y - panel.frame.minY)
            panel.ignoresMouseEvents = !pet.catRect.contains(local)
        }

        view.needsDisplay = true

        shelfClock += dt
        if shelfClock >= 0.6 {
            shelfClock = 0
            let screen = NSScreen.main ?? NSScreen.screens.first!
            refreshShelves(screenFrame: screen.frame, viewSize: screen.frame.size)
            pet.revalidateGround()
        }
    }

    private func refreshShelves(screenFrame: CGRect, viewSize: CGSize) {
        pet.shelves = WindowEdges.shelves(screenFrame: screenFrame,
                                          excluding: panel.windowNumber,
                                          viewSize: viewSize)
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
        pet.comeTo(CGPoint(x: m.x - panel.frame.minX, y: m.y - panel.frame.minY))
    }

    @objc private func toggleSleep() { pet.toggleSleep() }

    @objc private func quit() { NSApp.terminate(nil) }
}

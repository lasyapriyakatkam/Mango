import AppKit

/// A borderless, non-activating floating panel. Non-activating means clicking
/// the cat won't steal focus from whatever app you're using.
final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Full-screen transparent view that draws the cat and forwards mouse events.
final class PetView: NSView {
    let pet: Pet

    init(frame: NSRect, pet: Pet) {
        self.pet = pet
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override var isOpaque: Bool { false }
    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        ctx.saveGState()
        ctx.translateBy(x: pet.pos.x, y: pet.pos.y)
        CatRenderer.draw(pet: pet, in: ctx)
        ctx.restoreGState()
    }

    override func mouseDown(with event: NSEvent) {
        pet.beginGrab(at: convert(event.locationInWindow, from: nil))
    }
    override func mouseDragged(with event: NSEvent) {
        pet.dragMove(to: convert(event.locationInWindow, from: nil))
    }
    override func mouseUp(with event: NSEvent) {
        pet.endGrab()
    }
}

import AppKit

/// A borderless, non-activating floating panel. Non-activating means clicking
/// the cat won't steal focus from whatever app you're using.
final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Transparent per-display view that draws the cat and forwards mouse events.
///
/// The cat's position lives in global "desktop" coordinates (the union of all
/// displays). `screenOffset` is this display's bottom-left in that union space,
/// so we subtract it to draw and add it to interpret the mouse. A view whose
/// display doesn't currently contain the cat simply draws him off its own
/// bounds (clipped), so the same cat appears on whichever screen he's on — and
/// seamlessly across a seam when he straddles two displays.
final class PetView: NSView {
    let pet: Pet
    var screenOffset: CGPoint

    init(frame: NSRect, pet: Pet, screenOffset: CGPoint) {
        self.pet = pet
        self.screenOffset = screenOffset
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override var isOpaque: Bool { false }
    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private func toUnion(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x + screenOffset.x, y: p.y + screenOffset.y)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        ctx.saveGState()
        ctx.translateBy(x: pet.pos.x - screenOffset.x, y: pet.pos.y - screenOffset.y)
        CatRenderer.draw(pet: pet, in: ctx)
        ctx.restoreGState()
    }

    override func mouseDown(with event: NSEvent) {
        pet.beginGrab(at: toUnion(convert(event.locationInWindow, from: nil)))
    }
    override func mouseDragged(with event: NSEvent) {
        pet.dragMove(to: toUnion(convert(event.locationInWindow, from: nil)))
    }
    override func mouseUp(with event: NSEvent) {
        pet.endGrab()
    }
}

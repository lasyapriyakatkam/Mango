import AppKit

// Renders the cat in each state to PNGs so the art can be eyeballed without
// launching the live overlay. Compiled together with the renderer sources.

func render(state: PetState, eye: EyeState, facingLeft: Bool, name: String) {
    let size = 128
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else { return }
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    // Light checker background so transparency/edges are visible.
    NSColor(white: 0.93, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
    NSColor(white: 0.85, alpha: 1).setFill()
    for r in 0..<8 { for c in 0..<8 where (r + c) % 2 == 0 {
        NSBezierPath(rect: NSRect(x: c * 16, y: r * 16, width: 16, height: 16)).fill()
    }}

    let pet = Pet(bounds: CGSize(width: 128, height: 128))
    pet.state = state
    pet.eye = eye
    pet.facingLeft = facingLeft
    pet.frame = 0.35

    cg.saveGState()
    cg.translateBy(x: 64, y: 18)
    CatRenderer.draw(pet: pet, in: cg)
    cg.restoreGState()

    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "Tools/preview-\(name).png"))
    print("wrote preview-\(name).png")
}

render(state: .idle,  eye: .open,      facingLeft: false, name: "idle")
render(state: .walk,  eye: .open,      facingLeft: true,  name: "walk")
render(state: .sit,   eye: .happy,     facingLeft: false, name: "sit")
render(state: .sleep, eye: .closed,    facingLeft: false, name: "sleep")
render(state: .drag,  eye: .surprised, facingLeft: false, name: "drag")
render(state: .hang,  eye: .surprised, facingLeft: false, name: "hang")

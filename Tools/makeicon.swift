import AppKit

// Renders a 1024×1024 app-icon master PNG: the cat sitting on a warm,
// rounded squircle background. Reuses the live CatRenderer so the icon always
// matches the actual pet art.

let S = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: S, pixelsHigh: S,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

// Rounded-rect (squircle-ish) background with a warm vertical gradient.
let inset: CGFloat = 70
let bg = NSBezierPath(roundedRect: NSRect(x: inset, y: inset,
                                          width: CGFloat(S) - inset * 2,
                                          height: CGFloat(S) - inset * 2),
                      xRadius: 210, yRadius: 210)
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 1.00, green: 0.93, blue: 0.82, alpha: 1),
    NSColor(srgbRed: 1.00, green: 0.80, blue: 0.58, alpha: 1)
])!
gradient.draw(in: bg, angle: -90)

// The cat, scaled up and centered.
let pet = Pet(bounds: CGSize(width: 1024, height: 1024))
pet.state = .sit
pet.eye = .happy
pet.facingLeft = false
pet.frame = 0.0

cg.saveGState()
cg.translateBy(x: 512, y: 250)
cg.scaleBy(x: 7.6, y: 7.6)
CatRenderer.draw(pet: pet, in: cg)
cg.restoreGState()

NSGraphicsContext.restoreGraphicsState()

let url = URL(fileURLWithPath: "Tools/icon-master.png")
try! rep.representation(using: .png, properties: [:])!.write(to: url)
print("wrote \(url.path)")

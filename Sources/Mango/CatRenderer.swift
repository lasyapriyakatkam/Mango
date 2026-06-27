import AppKit

/// Draws an original cute chibi orange-tabby cat purely with vector primitives,
/// in the soft outlined cartoon style of the reference art: big round glossy
/// eyes with highlights, white muzzle / chest / paws, pink nose & inner ears,
/// tabby stripes (including the forehead "M"), and a soft brown outline.
///
/// The context is assumed to already be translated so (0, 0) is the cat's feet
/// (bottom-center), y-up. The view handles that translation.
enum CatRenderer {

    // Palette
    private static let fur     = NSColor(srgbRed: 0.97, green: 0.66, blue: 0.34, alpha: 1)
    private static let furDark = NSColor(srgbRed: 0.86, green: 0.49, blue: 0.18, alpha: 1)
    private static let cream    = NSColor(srgbRed: 1.00, green: 0.97, blue: 0.90, alpha: 1)
    private static let pink    = NSColor(srgbRed: 0.95, green: 0.62, blue: 0.64, alpha: 1)
    private static let pinkEar = NSColor(srgbRed: 0.97, green: 0.76, blue: 0.76, alpha: 1)
    private static let ink     = NSColor(srgbRed: 0.18, green: 0.12, blue: 0.09, alpha: 1)
    private static let outline = NSColor(srgbRed: 0.43, green: 0.27, blue: 0.13, alpha: 0.92)
    private static let white   = NSColor.white

    static func draw(pet: Pet, in ctx: CGContext) {
        ctx.saveGState()
        if pet.facingLeft { ctx.scaleBy(x: -1, y: 1) }   // mirror to face left

        let t = pet.frame
        switch pet.state {
        case .sleep:
            drawSleeping(t: t)
        case .drag, .fall:
            drawAirborne(eye: pet.eye, t: t)
        case .hang:
            drawHanging(t: t)
        case .sit, .land:
            drawSitting(eye: pet.eye, t: t)
        default:
            let phase = (pet.state == .walk || pet.state == .run) ? t : 0
            let fast = pet.state == .run
            drawStanding(eye: pet.eye, t: t, walkPhase: phase, running: fast)
        }

        ctx.restoreGState()
    }

    // MARK: Poses

    private static func drawStanding(eye: EyeState, t: CGFloat, walkPhase: CGFloat, running: Bool) {
        let swing = sin(walkPhase * (running ? 13 : 8)) * (running ? 7 : 5)
        tail(baseAt: CGPoint(x: -20, y: 30), angle: 118 + sin(t * 3) * 6)
        leg(x: -13, swing: -swing)
        leg(x:  18, swing: -swing * 0.8)
        body(center: CGPoint(x: 0, y: 27), w: 48, h: 38, chest: true)
        leg(x:  -3, swing:  swing)
        leg(x:  10, swing:  swing * 0.8)
        head(center: CGPoint(x: 12, y: 63), r: 21, eye: eye, t: t)
    }

    private static func drawSitting(eye: EyeState, t: CGFloat) {
        tail(baseAt: CGPoint(x: -15, y: 18), angle: 110 + sin(t * 2.5) * 5)
        body(center: CGPoint(x: 0, y: 24), w: 46, h: 42, chest: true)
        pawPair(y: 3)
        head(center: CGPoint(x: 8, y: 60), r: 21, eye: eye, t: t)
    }

    private static func drawAirborne(eye: EyeState, t: CGFloat) {
        tail(baseAt: CGPoint(x: -21, y: 30), angle: 35)
        leg(x: -19, swing: -11)
        leg(x:  17, swing:  11)
        body(center: CGPoint(x: 0, y: 32), w: 48, h: 38, chest: true)
        leg(x:  -8, swing:  -6)
        leg(x:  12, swing:   6)
        head(center: CGPoint(x: 12, y: 64), r: 21, eye: eye == .open ? .surprised : eye, t: t)
    }

    private static func drawHanging(t: CGFloat) {
        // Clinging to a ledge: body hangs below the surface line (y = 0).
        tail(baseAt: CGPoint(x: -16, y: -28), angle: -78 + sin(t * 4) * 12)
        leg(x: -11, swing: 28)      // forelegs reach up over the edge
        leg(x:  11, swing: 28)
        body(center: CGPoint(x: 0, y: -22), w: 44, h: 38, chest: true)
        head(center: CGPoint(x: 8, y: 4), r: 19, eye: .surprised, t: t)
    }

    private static func drawSleeping(t: CGFloat) {
        tail(baseAt: CGPoint(x: -24, y: 16), angle: 158)
        body(center: CGPoint(x: 0, y: 16), w: 60, h: 30, chest: false)
        head(center: CGPoint(x: 19, y: 23), r: 18, eye: .closed, t: t)

        let rise  = (t.truncatingRemainder(dividingBy: 2.0)) / 2.0
        drawZ(at: CGPoint(x: 32 + rise * 10, y: 42 + rise * 26), size: 8 + rise * 4, alpha: 1 - rise)
        let rise2 = ((t + 1).truncatingRemainder(dividingBy: 2.0)) / 2.0
        drawZ(at: CGPoint(x: 32 + rise2 * 10, y: 42 + rise2 * 26), size: 8 + rise2 * 4, alpha: 1 - rise2)
    }

    // MARK: Parts

    private static func fillStroke(_ path: NSBezierPath, _ color: NSColor,
                                   stroke: NSColor? = outline, width: CGFloat = 2.0) {
        color.setFill(); path.fill()
        if let s = stroke { s.setStroke(); path.lineWidth = width; path.stroke() }
    }

    private static func body(center: CGPoint, w: CGFloat, h: CGFloat, chest: Bool) {
        let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
        fillStroke(NSBezierPath(ovalIn: rect), fur, width: 2.2)

        // Back tabby stripes (short dark chevrons along the top of the body).
        furDark.setStroke()
        for i in 0..<3 {
            let p = NSBezierPath()
            let sx = center.x - 12 + CGFloat(i) * 11
            p.move(to: CGPoint(x: sx - 4, y: center.y + h * 0.20))
            p.line(to: CGPoint(x: sx,     y: center.y + h * 0.38))
            p.line(to: CGPoint(x: sx + 4, y: center.y + h * 0.20))
            p.lineWidth = 3.0
            p.lineCapStyle = .round
            p.lineJoinStyle = .round
            p.stroke()
        }

        // White chest bib on the front of the body.
        if chest {
            cream.setFill()
            let c = CGRect(x: center.x + w * 0.04, y: center.y - h * 0.52,
                           width: w * 0.42, height: h * 0.78)
            NSBezierPath(ovalIn: c).fill()
        }
    }

    private static func head(center c: CGPoint, r: CGFloat, eye: EyeState, t: CGFloat) {
        // Ears: bases sit on the head circle so the face (drawn next) overlaps
        // the seam and they read as growing out of the head.
        ear(c: c, r: r, baseA: 152, baseB: 96, tipDeg: 124, tipLen: r * 1.62)   // left
        ear(c: c, r: r, baseA: 84,  baseB: 28, tipDeg: 56,  tipLen: r * 1.62)   // right

        // Face.
        fillStroke(NSBezierPath(ovalIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                   fur, width: 2.2)

        // Forehead tabby "M" / stripes.
        furDark.setStroke()
        for dx in [-r * 0.30, CGFloat(0), r * 0.30] {
            let p = NSBezierPath()
            p.move(to: CGPoint(x: c.x + dx, y: c.y + r * 0.92))
            p.line(to: CGPoint(x: c.x + dx, y: c.y + r * 0.55))
            p.lineWidth = 2.6; p.lineCapStyle = .round; p.stroke()
        }

        // White muzzle.
        cream.setFill()
        NSBezierPath(ovalIn: CGRect(x: c.x - r * 0.62, y: c.y - r * 0.95,
                                    width: r * 1.35, height: r * 1.05)).fill()

        eyePair(center: c, r: r, eye: eye)

        // Nose.
        let nose = NSBezierPath()
        let nx = c.x + r * 0.05, ny = c.y - r * 0.28
        nose.move(to: CGPoint(x: nx - r * 0.16, y: ny))
        nose.line(to: CGPoint(x: nx + r * 0.16, y: ny))
        nose.curve(to: CGPoint(x: nx, y: ny - r * 0.22),
                   controlPoint1: CGPoint(x: nx + r * 0.10, y: ny - r * 0.18),
                   controlPoint2: CGPoint(x: nx + r * 0.04, y: ny - r * 0.22))
        nose.close()
        fillStroke(nose, pink, stroke: pink, width: 1)

        // Tiny mouth.
        ink.withAlphaComponent(0.7).setStroke()
        let mouth = NSBezierPath()
        mouth.move(to: CGPoint(x: nx, y: ny - r * 0.22))
        mouth.line(to: CGPoint(x: nx, y: ny - r * 0.40))
        mouth.lineWidth = 1.4; mouth.stroke()

        // Whiskers — three on each side, fanning out clearly past the face.
        ink.withAlphaComponent(0.5).setStroke()
        for dy in [r * 0.16, -r * 0.02, -r * 0.20] {
            let rp = NSBezierPath()
            rp.move(to: CGPoint(x: c.x + r * 0.28, y: c.y - r * 0.30 + dy * 0.4))
            rp.line(to: CGPoint(x: c.x + r * 1.45, y: c.y - r * 0.30 + dy))
            rp.lineWidth = 1.2; rp.stroke()

            let lp = NSBezierPath()
            lp.move(to: CGPoint(x: c.x - r * 0.18, y: c.y - r * 0.30 + dy * 0.4))
            lp.line(to: CGPoint(x: c.x - r * 1.40, y: c.y - r * 0.30 + dy))
            lp.lineWidth = 1.2; lp.stroke()
        }
    }

    private static func eyePair(center c: CGPoint, r: CGFloat, eye: EyeState) {
        let eyeY = c.y + r * 0.02
        let lx = c.x - r * 0.40
        let rx = c.x + r * 0.50
        switch eye {
        case .closed, .blink:
            ink.setStroke()
            for ex in [lx, rx] {
                let p = NSBezierPath()
                p.move(to: CGPoint(x: ex - r * 0.26, y: eyeY))
                p.curve(to: CGPoint(x: ex + r * 0.26, y: eyeY),
                        controlPoint1: CGPoint(x: ex - r * 0.08, y: eyeY - r * 0.22),
                        controlPoint2: CGPoint(x: ex + r * 0.08, y: eyeY - r * 0.22))
                p.lineWidth = 2.0; p.lineCapStyle = .round; p.stroke()
            }
        case .happy:
            ink.setStroke()
            for ex in [lx, rx] {
                let p = NSBezierPath()
                p.move(to: CGPoint(x: ex - r * 0.26, y: eyeY - r * 0.05))
                p.curve(to: CGPoint(x: ex + r * 0.26, y: eyeY - r * 0.05),
                        controlPoint1: CGPoint(x: ex - r * 0.08, y: eyeY + r * 0.24),
                        controlPoint2: CGPoint(x: ex + r * 0.08, y: eyeY + r * 0.24))
                p.lineWidth = 2.4; p.lineCapStyle = .round; p.stroke()
            }
        default:
            let rad: CGFloat = (eye == .surprised) ? r * 0.42 : r * 0.36
            for ex in [lx, rx] {
                ink.setFill()
                NSBezierPath(ovalIn: CGRect(x: ex - rad, y: eyeY - rad,
                                            width: rad * 2, height: rad * 2)).fill()
                // Big glossy highlight + small secondary.
                white.setFill()
                NSBezierPath(ovalIn: CGRect(x: ex - rad * 0.55, y: eyeY + rad * 0.10,
                                            width: rad * 0.7, height: rad * 0.7)).fill()
                white.withAlphaComponent(0.8).setFill()
                NSBezierPath(ovalIn: CGRect(x: ex + rad * 0.15, y: eyeY - rad * 0.55,
                                            width: rad * 0.34, height: rad * 0.34)).fill()
            }
        }
    }

    /// Draws an ear whose two base corners lie on the head circle (radius `r`,
    /// center `c`) at angles `baseA`/`baseB`, with the tip at `tipDeg` a
    /// distance `tipLen` from the center. The base is just inside the circle so
    /// the face overlaps it, making the ear look attached.
    private static func ear(c: CGPoint, r: CGFloat,
                            baseA: CGFloat, baseB: CGFloat, tipDeg: CGFloat, tipLen: CGFloat) {
        func pt(_ deg: CGFloat, _ rad: CGFloat) -> CGPoint {
            let a = deg * .pi / 180
            return CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
        }
        func lerp(_ p: CGPoint, _ q: CGPoint, _ f: CGFloat) -> CGPoint {
            CGPoint(x: p.x + (q.x - p.x) * f, y: p.y + (q.y - p.y) * f)
        }
        let b1 = pt(baseA, r * 0.90)
        let b2 = pt(baseB, r * 0.90)
        let tip = pt(tipDeg, tipLen)

        // Soft triangle: straight sides into a gently rounded apex.
        let tipL = lerp(tip, b1, 0.24)
        let tipR = lerp(tip, b2, 0.24)
        let p = NSBezierPath()
        p.move(to: b1)
        p.line(to: tipL)
        p.curve(to: tipR, controlPoint1: tip, controlPoint2: tip)
        p.line(to: b2)
        p.close()
        p.lineJoinStyle = .round
        fillStroke(p, fur, width: 2.0)

        // Pink inner ear, also softly rounded at the tip.
        pinkEar.setFill()
        let m1 = lerp(b1, tip, 0.5)
        let m2 = lerp(b2, tip, 0.5)
        let innerTip = lerp(tip, c, 0.18)
        let itL = lerp(innerTip, m1, 0.28)
        let itR = lerp(innerTip, m2, 0.28)
        let q = NSBezierPath()
        q.move(to: m1)
        q.line(to: itL)
        q.curve(to: itR, controlPoint1: innerTip, controlPoint2: innerTip)
        q.line(to: m2)
        q.close()
        q.fill()
    }

    private static func leg(x: CGFloat, swing: CGFloat) {
        let r = CGRect(x: x - 5 + swing, y: -2, width: 10, height: 17)
        fillStroke(NSBezierPath(roundedRect: r, xRadius: 5, yRadius: 5), fur, width: 2.0)
        // White sock / paw tip.
        cream.setFill()
        NSBezierPath(roundedRect: CGRect(x: x - 4.2 + swing, y: -2, width: 8.4, height: 7),
                     xRadius: 4, yRadius: 4).fill()
    }

    private static func pawPair(y: CGFloat) {
        for x in [CGFloat(-3), CGFloat(12)] {
            let r = CGRect(x: x, y: y, width: 12, height: 11)
            fillStroke(NSBezierPath(roundedRect: r, xRadius: 5.5, yRadius: 5.5), cream, width: 1.8)
        }
    }

    private static func tail(baseAt: CGPoint, angle: CGFloat) {
        // `angle` is the direction the tail points (deg: 0=right, 90=up,
        // 180=left, -90=down). The tail is a single curl growing that way, so
        // it never sweeps across the body and reads as one tail.
        let a = angle * .pi / 180
        let L: CGFloat = 50
        let dir  = CGVector(dx: cos(a), dy: sin(a))
        let perp = CGVector(dx: -sin(a), dy: cos(a))
        func P(_ along: CGFloat, _ side: CGFloat) -> CGPoint {
            CGPoint(x: baseAt.x + dir.dx * along + perp.dx * side,
                    y: baseAt.y + dir.dy * along + perp.dy * side)
        }
        let tip = P(L, 7)
        let p = NSBezierPath()
        p.move(to: baseAt)
        p.curve(to: tip, controlPoint1: P(L * 0.45, 7), controlPoint2: P(L * 0.9, 18))
        // Outlined orange tail.
        outline.setStroke(); p.lineWidth = 13; p.lineCapStyle = .round; p.lineJoinStyle = .round; p.stroke()
        fur.setStroke();     p.lineWidth = 10; p.stroke()
        // Cream tip.
        cream.setFill()
        NSBezierPath(ovalIn: CGRect(x: tip.x - 5, y: tip.y - 5, width: 10, height: 10)).fill()
        // Striped rings across the tail.
        furDark.setStroke()
        for f in [CGFloat(0.42), 0.64, 0.84] {
            let mid = P(L * f, 9)
            let ring = NSBezierPath()
            ring.move(to: CGPoint(x: mid.x + perp.dx * 4, y: mid.y + perp.dy * 4))
            ring.line(to: CGPoint(x: mid.x - perp.dx * 4, y: mid.y - perp.dy * 4))
            ring.lineWidth = 3.5; ring.lineCapStyle = .round; ring.stroke()
        }
    }

    private static func drawZ(at p: CGPoint, size: CGFloat, alpha: CGFloat) {
        ink.withAlphaComponent(max(0, alpha)).setStroke()
        let path = NSBezierPath()
        path.move(to: CGPoint(x: p.x, y: p.y + size))
        path.line(to: CGPoint(x: p.x + size, y: p.y + size))
        path.line(to: CGPoint(x: p.x, y: p.y))
        path.line(to: CGPoint(x: p.x + size, y: p.y))
        path.lineWidth = 1.8; path.stroke()
    }
}

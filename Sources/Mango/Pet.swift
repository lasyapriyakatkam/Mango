import AppKit

// MARK: - Types

/// Animation / behavior state of the cat.
enum PetState {
    case idle, walk, run, sit, sleep, drag, fall, land, hang, react
}

/// What the eyes are doing on this frame.
enum EyeState {
    case open, blink, happy, surprised, closed
}

/// A horizontal surface the cat can stand on. The screen floor is a special
/// shelf; every other shelf is the top edge of an on-screen window.
struct Shelf {
    var y: CGFloat
    var xMin: CGFloat
    var xMax: CGFloat
    var isFloor: Bool
}

// MARK: - Pet

/// Owns the cat's position, velocity and behavior. All coordinates are in the
/// overlay view's space: origin bottom-left, y increasing upward. `pos` is the
/// cat's feet (bottom-center of the sprite).
final class Pet {

    // Tunables
    private let walkSpeed: CGFloat = 55
    private let runSpeed: CGFloat = 145
    private let gravity: CGFloat = 1700
    private let throwCap: CGFloat = 1400
    private let margin: CGFloat = 30

    let spriteSize = CGSize(width: 96, height: 96)

    // Live state
    var pos = CGPoint(x: 200, y: 0)
    var vel = CGVector(dx: 0, dy: 0)
    var state: PetState = .idle
    var eye: EyeState = .open
    var facingLeft = false
    var grounded = true
    var frame: CGFloat = 0          // seconds of animation time accumulated

    var bounds: CGSize
    var floorY: CGFloat                     // resting height of the floor (above the Dock)
    var shelves: [Shelf] = []
    var currentShelf: Shelf

    // Behavior timers
    private var decisionTimer: Double = 1.5
    private var blinkTimer: Double = 2.0
    private var stateTimer: Double = 0      // for transient states (land/react/hang)
    private var walkDir: CGFloat = 0        // -1, 0, 1
    private var tailFlick: Double = 0

    // Dragging
    var grabbed = false
    var dragging = false
    private var grabOffset = CGPoint.zero
    private var dragStart = CGPoint.zero
    private var dragTarget = CGPoint.zero
    private var dragVel = CGVector.zero

    init(bounds: CGSize, floorY: CGFloat = 0) {
        self.bounds = bounds
        self.floorY = floorY
        self.currentShelf = Shelf(y: floorY, xMin: 0, xMax: bounds.width, isFloor: true)
    }

    /// Hit area used to decide whether the mouse is "over" the cat.
    var catRect: CGRect {
        CGRect(x: pos.x - spriteSize.width / 2,
               y: pos.y - 8,
               width: spriteSize.width,
               height: spriteSize.height)
    }

    private var floorShelf: Shelf {
        Shelf(y: floorY, xMin: 0, xMax: bounds.width, isFloor: true)
    }

    // MARK: Main update

    func update(dt: Double) {
        frame += CGFloat(dt)
        updateBlink(dt)

        if grabbed && dragging {
            updateDrag(dt)
            return
        }
        if !grounded {
            updateFalling(dt)
            return
        }
        updateGrounded(dt)
    }

    // MARK: Blink / eyes

    private func updateBlink(_ dt: Double) {
        if state == .sleep { eye = .closed; return }
        if state == .react || state == .drag { return }   // keep expressive eyes
        guard eye == .open || eye == .blink else { return }

        blinkTimer -= dt
        if blinkTimer <= 0 {
            if eye == .blink {
                eye = .open
                blinkTimer = Double.random(in: 2.0...5.0)
            } else {
                eye = .blink
                blinkTimer = 0.12
            }
        }
    }

    // MARK: Grounded behavior

    private func updateGrounded(_ dt: Double) {
        switch state {
        case .land:
            stateTimer -= dt
            if stateTimer <= 0 { state = .idle; decisionTimer = Double.random(in: 0.6...1.6) }
            pos.y = currentShelf.y
            return
        case .react:
            stateTimer -= dt
            if stateTimer <= 0 { state = .idle; eye = .open; decisionTimer = Double.random(in: 0.6...1.6) }
            pos.y = currentShelf.y
            return
        case .hang:
            stateTimer -= dt
            if stateTimer <= 0 {                 // climb back up and walk away from the edge
                state = .walk
                walkDir = -walkDir
                facingLeft = walkDir < 0
                eye = .open
            }
            pos.y = currentShelf.y
            return
        default:
            break
        }

        decisionTimer -= dt
        if decisionTimer <= 0 {
            if state == .sleep { eye = .open }
            chooseNewAction()
        }

        if state == .walk || state == .run {
            if eye == .closed { eye = .open }
            let speed = (state == .run ? runSpeed : walkSpeed)
            pos.x += walkDir * speed * CGFloat(dt)
            facingLeft = walkDir < 0

            if currentShelf.isFloor {
                if pos.x < margin { pos.x = margin; walkDir = 1; facingLeft = false }
                else if pos.x > bounds.width - margin { pos.x = bounds.width - margin; walkDir = -1; facingLeft = true }
            } else {
                // Reached the end of a window's top edge.
                if pos.x <= currentShelf.xMin + 2 || pos.x >= currentShelf.xMax - 2 {
                    pos.x = min(max(pos.x, currentShelf.xMin + 2), currentShelf.xMax - 2)
                    let r = Double.random(in: 0..<1)
                    if r < 0.45 {                       // pace back along the edge
                        walkDir = -walkDir
                        facingLeft = walkDir < 0
                    } else if r < 0.72 {                // cling and hang off the edge
                        state = .hang
                        stateTimer = Double.random(in: 0.8...1.7)
                    } else {                            // hop off into a fall
                        grounded = false
                        state = .fall
                        vel = CGVector(dx: walkDir * speed * 0.6, dy: 70)
                        return
                    }
                }
            }
        }

        pos.y = currentShelf.y
    }

    private func chooseNewAction() {
        let r = Double.random(in: 0..<1)
        switch r {
        case ..<0.30:
            state = .idle; walkDir = 0; decisionTimer = Double.random(in: 1.0...2.5)
        case ..<0.45:
            state = .sit;  walkDir = 0; decisionTimer = Double.random(in: 2.0...5.0)
        case ..<0.57:
            state = .sleep; walkDir = 0; eye = .closed; decisionTimer = Double.random(in: 5.0...12.0)
        case ..<0.90:
            state = .walk; walkDir = Bool.random() ? 1 : -1; eye = .open; decisionTimer = Double.random(in: 1.5...4.0)
        default:
            state = .run;  walkDir = Bool.random() ? 1 : -1; eye = .open; decisionTimer = Double.random(in: 0.8...1.8)
        }
    }

    // MARK: Falling / gravity

    private func updateFalling(_ dt: Double) {
        vel.dy -= gravity * CGFloat(dt)
        vel.dx *= 0.99
        let prevY = pos.y
        pos.x += vel.dx * CGFloat(dt)
        pos.y += vel.dy * CGFloat(dt)
        if vel.dx < -5 { facingLeft = true } else if vel.dx > 5 { facingLeft = false }

        // Bounce off the side walls.
        if pos.x < 4 { pos.x = 4; vel.dx = abs(vel.dx) * 0.4 }
        else if pos.x > bounds.width - 4 { pos.x = bounds.width - 4; vel.dx = -abs(vel.dx) * 0.4 }

        guard vel.dy <= 0 else { state = .fall; return }   // only land while descending

        var landing: Shelf?
        for s in shelves + [floorShelf] where pos.x >= s.xMin && pos.x <= s.xMax {
            if prevY >= s.y && pos.y <= s.y {              // crossed this surface top-down
                if landing == nil || s.y > landing!.y { landing = s }
            }
        }

        if let s = landing {
            pos.y = s.y
            currentShelf = s
            grounded = true
            vel = .zero
            state = .land
            stateTimer = 0.22
            eye = .open
        } else {
            state = .fall
        }
    }

    // MARK: Dragging

    func beginGrab(at p: CGPoint) {
        grabbed = true
        dragging = false
        dragStart = p
        grabOffset = CGPoint(x: pos.x - p.x, y: pos.y - p.y)
    }

    func dragMove(to p: CGPoint) {
        if !dragging {
            if hypot(p.x - dragStart.x, p.y - dragStart.y) > 4 {
                dragging = true
                state = .drag
                eye = .surprised
                grounded = false
                dragVel = .zero
            } else {
                return
            }
        }
        dragTarget = CGPoint(x: p.x + grabOffset.x, y: p.y + grabOffset.y)
    }

    func endGrab() {
        grabbed = false
        if dragging {
            dragging = false
            grounded = false
            state = .fall
            vel = CGVector(dx: min(max(dragVel.dx, -throwCap), throwCap),
                           dy: min(max(dragVel.dy, -throwCap), throwCap))
        } else {
            // A click without a drag: a happy little reaction.
            state = .react
            stateTimer = 0.7
            eye = .happy
            decisionTimer = 0.7
        }
    }

    private func updateDrag(_ dt: Double) {
        let prev = pos
        var t = dragTarget
        t.x = min(max(t.x, 0), bounds.width)
        t.y = min(max(t.y, 0), bounds.height)
        pos = t
        if dt > 0 {
            let nvx = (pos.x - prev.x) / CGFloat(dt)
            let nvy = (pos.y - prev.y) / CGFloat(dt)
            dragVel = CGVector(dx: 0.6 * dragVel.dx + 0.4 * nvx,
                               dy: 0.6 * dragVel.dy + 0.4 * nvy)
        }
        if dragVel.dx < -5 { facingLeft = true } else if dragVel.dx > 5 { facingLeft = false }
        state = .drag
    }

    // MARK: Shelf maintenance & menu actions

    /// Called after the window list is refreshed so a cat standing on a window
    /// rides it as it moves, or drops if its window vanished.
    func revalidateGround() {
        guard grounded, !currentShelf.isFloor else { return }
        var match: Shelf?
        for s in shelves where pos.x >= s.xMin - 6 && pos.x <= s.xMax + 6 && abs(s.y - pos.y) < 60 {
            if match == nil || abs(s.y - pos.y) < abs(match!.y - pos.y) { match = s }
        }
        if let m = match {
            currentShelf = m
            pos.y = m.y
        } else {
            grounded = false
            state = .fall
            vel = CGVector(dx: 0, dy: -20)
        }
    }

    func comeTo(_ p: CGPoint) {
        pos = CGPoint(x: min(max(p.x, margin), bounds.width - margin), y: p.y)
        grounded = false
        state = .fall
        vel = .zero
        eye = .surprised
    }

    func toggleSleep() {
        if state == .sleep {
            state = .idle; eye = .open; decisionTimer = Double.random(in: 0.5...1.5)
        } else if grounded {
            state = .sleep; eye = .closed; walkDir = 0; decisionTimer = Double.random(in: 6.0...14.0)
        }
    }
}

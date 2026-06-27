import AppKit

/// Discovers the top edges of on-screen application windows so the cat can
/// land on, walk along, and hang off them. Uses CGWindowList, which reports
/// window *bounds* without needing Screen Recording / Accessibility
/// permission (only window titles and images are gated).
enum WindowEdges {

    /// - Parameters:
    ///   - unionOrigin: bottom-left of the overlay in global AppKit coordinates
    ///     (the bounding box of all displays).
    ///   - unionSize: size of that overlay.
    ///   - windowNumber: our own overlay window, to skip.
    static func shelves(unionOrigin: CGPoint, unionSize: CGSize, excluding windowNumber: Int) -> [Shelf] {
        // CGWindowList coordinates are global, top-left origin, y-down. AppKit
        // is bottom-left origin, y-up. The flip reference is the primary
        // display's height (the screen whose origin is (0,0)).
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? unionSize.height

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var result: [Shelf] = []
        for info in infoList {
            // Only normal application windows (layer 0); skip the Dock, menu
            // bar, our own overlay, etc.
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            if let num = info[kCGWindowNumber as String] as? Int, num == windowNumber { continue }

            guard let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: boundsDict) else { continue }

            if rect.width < 90 || rect.height < 40 { continue }   // ignore tiny panels

            // CG global (top-left origin) -> AppKit global (bottom-left) -> overlay-local.
            let topEdgeGlobalY = primaryHeight - rect.minY
            let vy = topEdgeGlobalY - unionOrigin.y
            let vxMin = rect.minX - unionOrigin.x
            let vxMax = rect.maxX - unionOrigin.x

            // Keep only edges that fall within the overlay.
            if vy < 40 || vy > unionSize.height - 10 { continue }
            if vxMax < 0 || vxMin > unionSize.width { continue }

            result.append(Shelf(y: vy,
                                xMin: max(vxMin, 0),
                                xMax: min(vxMax, unionSize.width),
                                isFloor: false))
        }
        return result
    }
}

import AppKit

/// Discovers the top edges of on-screen application windows so the cat can
/// land on, walk along, and hang off them. Uses CGWindowList, which reports
/// window *bounds* without needing Screen Recording / Accessibility
/// permission (only window titles and images are gated).
enum WindowEdges {

    static func shelves(screenFrame: CGRect, excluding windowNumber: Int, viewSize: CGSize) -> [Shelf] {
        // CGWindowList coordinates are global, top-left origin, y-down. AppKit
        // is bottom-left origin, y-up. The flip reference is the primary
        // display's height (the screen whose origin is (0,0)).
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? screenFrame.height

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

            let topEdgeGlobalY = primaryHeight - rect.minY            // AppKit global y of the window top
            let vy = topEdgeGlobalY - screenFrame.minY                // into overlay-view space
            let vxMin = rect.minX - screenFrame.minX
            let vxMax = rect.maxX - screenFrame.minX

            // Keep only edges that fall within this screen.
            if vy < 40 || vy > viewSize.height - 10 { continue }
            if vxMax < 0 || vxMin > viewSize.width { continue }

            result.append(Shelf(y: vy,
                                xMin: max(vxMin, 0),
                                xMax: min(vxMax, viewSize.width),
                                isFloor: false))
        }
        return result
    }
}

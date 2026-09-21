import CoreGraphics

/// All coordinates are in Quartz's global, top-left coordinate space.
enum MacOS27PopupGeometry {
    static func origin(size: CGSize, anchor: CGRect, visibleScreen: CGRect) -> CGPoint? {
        let values = [size.width, size.height, anchor.minX, anchor.minY, anchor.width,
                      anchor.height, visibleScreen.minX, visibleScreen.minY,
                      visibleScreen.width, visibleScreen.height]
        guard values.allSatisfy(\.isFinite), size.width > 0, size.height > 0,
              anchor.width > 0, anchor.height > 0,
              visibleScreen.width > 0, visibleScreen.height > 0 else { return nil }
        let left = visibleScreen.minX + 4
        let right = max(left, visibleScreen.maxX - size.width - 4)
        // Prefer below the status icon, but keep a tall panel above the Dock.
        let top = visibleScreen.minY + 4
        let bottom = max(top, visibleScreen.maxY - size.height - 4)
        return CGPoint(x: min(max(anchor.midX - size.width / 2, left), right),
                       y: min(max(anchor.maxY + 4, top), bottom))
    }
}

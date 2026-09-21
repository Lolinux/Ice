import CoreGraphics

@main
enum MacOS27PopupGeometryTests {
    static func main() {
        let screen = CGRect(x: 0, y: 33, width: 1512, height: 900)
        let anchor = CGRect(x: 1000, y: 0, width: 32, height: 33)
        precondition(MacOS27PopupGeometry.origin(size: CGSize(width: 400, height: 500), anchor: anchor, visibleScreen: screen) == CGPoint(x: 816, y: 37))
        let right = MacOS27PopupGeometry.origin(size: CGSize(width: 800, height: 500), anchor: anchor, visibleScreen: screen)!
        precondition(right.x + 800 <= screen.maxX - 4, "Wide popups must stay on screen")
        let secondary = CGRect(x: -1920, y: -100, width: 1920, height: 1040)
        let secondAnchor = CGRect(x: -1900, y: -133, width: 32, height: 33)
        precondition(MacOS27PopupGeometry.origin(size: CGSize(width: 500, height: 600), anchor: secondAnchor, visibleScreen: secondary) == CGPoint(x: -1916, y: -96), "Negative display coordinates must stay global")
        let tall = MacOS27PopupGeometry.origin(size: CGSize(width: 400, height: 890), anchor: anchor, visibleScreen: screen)!
        precondition(tall.y == 37 && tall.y + 890 <= screen.maxY, "Tall panels remain within the work area")
        precondition(MacOS27PopupGeometry.origin(size: .zero, anchor: anchor, visibleScreen: screen) == nil)
        precondition(MacOS27PopupGeometry.origin(size: CGSize(width: CGFloat.infinity, height: 20), anchor: anchor, visibleScreen: screen) == nil)
        print("PASS: 6 popup anchor geometry cases")
    }
}

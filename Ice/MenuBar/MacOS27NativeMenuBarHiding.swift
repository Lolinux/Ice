//
//  MacOS27NativeMenuBarHiding.swift
//  Ice
//

import ApplicationServices
import Cocoa
import OSLog

/// Hides a contiguous section by resizing an Ice-owned blank status item.
/// macOS lays out and handles every other item, including overflow and clicks.
@MainActor
final class MacOS27NativeMenuBarHiding {
    private struct Spacer {
        let item: NSStatusItem
    }

    private let logger = Logger(category: "MacOS27NativeMenuBarHiding")

    private var spacers = [MenuBarSection.Name: Spacer]()

    /// The frame of the item to the right of each concealing spacer, recorded
    /// before the spacer was widened, while the bar was still expanded.
    private var concealedControlFrames = [MenuBarSection.Name: CGRect]()

    isolated deinit {
        removeAll()
    }

    /// A short description of a section's spacer, for logging.
    func debugDescription(for section: MenuBarSection.Name) -> String {
        guard let spacer = spacers[section] else { return "no spacer" }
        return "spacer visible=\(spacer.item.isVisible) length=\(spacer.item.length)"
    }

    func isConcealing(_ section: MenuBarSection.Name) -> Bool {
        guard let spacer = spacers[section] else { return false }
        return spacer.item.isVisible && spacer.item.length > 1
    }

    func prepare(section: MenuBarSection.Name, anchorPosition: CGFloat) {
        guard spacers[section] == nil else { return }
        let name = "Ice.NativeBoundary.\(section.rawValue).v2"
        // Equal preferred positions have unstable ordering after a relaunch.
        // The spacer must sort strictly to the left of the visible Ice item.
        let key = "NSStatusItem Preferred Position \(name)"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(anchorPosition + 1, forKey: key)
        }
        let item = NSStatusBar.system.statusItem(withLength: 1)
        item.autosaveName = name
        item.button?.title = ""
        item.button?.image = nil
        item.button?.isEnabled = false
        item.button?.setAccessibilityIdentifier(name)
        spacers[section] = Spacer(item: item)
        withdraw(item)
    }

    /// AppKit reserves a real slot even for a one-point item. Publish the
    /// narrow boundary only while an explicit operation needs a drag handle.
    func prepareForHiding(anchorPosition: CGFloat) {
        prepare(section: .hidden, anchorPosition: anchorPosition)
        if let spacer = spacers[.hidden] { showNarrow(spacer.item) }
    }

    func showForLayout(anchorPosition: CGFloat, alwaysHiddenAnchor: CGFloat?) {
        prepare(section: .hidden, anchorPosition: anchorPosition)
        if let alwaysHiddenAnchor {
            prepare(section: .alwaysHidden, anchorPosition: alwaysHiddenAnchor)
        }
        for (section, spacer) in spacers {
            if section == .hidden || alwaysHiddenAnchor != nil {
                showNarrow(spacer.item)
            } else {
                withdraw(spacer.item)
            }
        }
    }

    private func showNarrow(_ item: NSStatusItem) {
        if item.length != 1 { item.length = 1 }
        if item.button?.isEnabled == false { item.button?.isEnabled = true }
        if !item.isVisible { item.isVisible = true }
    }

    private func withdraw(_ item: NSStatusItem) {
        guard item.isVisible else { return }
        logger.notice("Withdrawing \(item.autosaveName ?? "spacer", privacy: .public) (length \(item.length))")
        // Hiding an NSStatusItem clears its saved position. Preserve only our
        // own position; the pre-hide check reconciles native user reordering.
        let key = "NSStatusItem Preferred Position \(item.autosaveName ?? "")"
        let position = UserDefaults.standard.object(forKey: key)
        item.isVisible = false
        if let position { UserDefaults.standard.set(position, forKey: key) }
        if item.button?.isEnabled == true { item.button?.isEnabled = false }
    }

    /// Sets whether a section's spacer conceals the items to its left.
    ///
    /// - Parameter controlFrame: The current frame of the item immediately to
    ///   the right of the spacer, in global display coordinates. When known,
    ///   the spacer is sized to the space actually available to its left.
    @available(macOS 27.0, *)
    func setHidden(
        _ hidden: Bool,
        section: MenuBarSection.Name,
        anchorPosition: CGFloat,
        screen: NSScreen,
        controlFrame: CGRect? = nil
    ) {
        guard hidden else {
            concealedControlFrames[section] = nil
            guard let spacer = spacers[section] else { return }
            withdraw(spacer.item)
            return
        }

        prepare(section: section, anchorPosition: anchorPosition)
        guard let spacer = spacers[section] else { return }

        let length: CGFloat
        if let controlFrame {
            concealedControlFrames[section] = controlFrame
            let menusMaxX = Self.applicationMenuMaxX(on: screen)
            length = Self.concealingLength(
                controlMinX: controlFrame.minX,
                screen: screen,
                applicationMenuMaxX: menusMaxX
            )
            logger.notice("Concealing \(section.rawValue, privacy: .public) with control at \(controlFrame.minX), app menus ending at \(menusMaxX ?? -1)")
        } else if spacer.item.isVisible, spacer.item.length > 1 {
            // Without a fresh frame, keep the length that is already concealing.
            length = spacer.item.length
        } else {
            // An item wider than the entire native status region is discarded on
            // macOS 27. A width within that region makes its left neighbors overflow.
            let regionWidth = screen.auxiliaryTopRightArea?.width
                ?? (screen.frame.width - (screen.getApplicationMenuFrame()?.width ?? 300))
            length = max(32, regionWidth - 32)
        }

        if spacer.item.button?.isEnabled == true { spacer.item.button?.isEnabled = false }
        if spacer.item.length != length {
            logger.notice("Sizing \(section.rawValue, privacy: .public) spacer to \(length) (control frame: \(controlFrame?.debugDescription ?? "unknown", privacy: .public))")
            spacer.item.length = length
        }
        if !spacer.item.isVisible { spacer.item.isVisible = true }
    }

    /// Recomputes a concealing spacer's length after the application menus
    /// may have changed width, such as when another app becomes frontmost.
    @available(macOS 27.0, *)
    func refreshConcealingLength(section: MenuBarSection.Name, screen: NSScreen) {
        guard
            isConcealing(section),
            let spacer = spacers[section],
            let controlFrame = concealedControlFrames[section]
        else {
            return
        }
        let menusMaxX = Self.applicationMenuMaxX(on: screen)
        let length = Self.concealingLength(
            controlMinX: controlFrame.minX,
            screen: screen,
            applicationMenuMaxX: menusMaxX
        )
        // Small differences aren't worth making the whole bar reflow.
        guard abs(length - spacer.item.length) > 8 else { return }
        logger.notice("Resizing \(section.rawValue, privacy: .public) spacer from \(spacer.item.length) to \(length) for app menus ending at \(menusMaxX ?? -1)")
        spacer.item.length = length
    }

    /// Returns the right edge of the frontmost application's menus on the
    /// given screen.
    private static func applicationMenuMaxX(on screen: NSScreen) -> CGFloat? {
        frontmostApplicationMenuMaxX(on: screen) ?? screen.getApplicationMenuFrame()?.maxX
    }

    /// Reads the right edge of the frontmost application's menus from its
    /// accessibility menu bar. The system-wide hit test that
    /// `getApplicationMenuFrame()` relies on finds no menu bar on macOS 27.
    private static func frontmostApplicationMenuMaxX(on screen: NSScreen) -> CGFloat? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.25)
        guard
            let menuBarValue = copyAttribute(kAXMenuBarAttribute, of: application),
            CFGetTypeID(menuBarValue) == AXUIElementGetTypeID()
        else {
            return nil
        }
        let menuBar = unsafeBitCast(menuBarValue, to: AXUIElement.self)
        guard let children = copyAttribute(kAXChildrenAttribute, of: menuBar) as? [AXUIElement] else {
            return nil
        }
        let display = CGDisplayBounds(screen.displayID)
        let strip = CGRect(x: display.minX, y: display.minY, width: display.width, height: 40)
        return children
            .compactMap { frame(of: $0) }
            .filter { $0.width > 0 && strip.contains(CGPoint(x: $0.midX, y: $0.midY)) }
            .map(\.maxX)
            .max()
    }

    private static func copyAttribute(_ attribute: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        guard
            let positionValue = copyAttribute(kAXPositionAttribute, of: element),
            let sizeValue = copyAttribute(kAXSizeAttribute, of: element),
            CFGetTypeID(positionValue) == AXValueGetTypeID(),
            CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else {
            return nil
        }
        var position = CGPoint.zero
        var size = CGSize.zero
        guard
            AXValueGetValue(unsafeBitCast(positionValue, to: AXValue.self), .cgPoint, &position),
            AXValueGetValue(unsafeBitCast(sizeValue, to: AXValue.self), .cgSize, &size)
        else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    /// Returns a spacer length that fills the space available to the left of
    /// the item at `controlMinX`, so every item to the spacer's left overflows.
    ///
    /// On macOS 27, a status item that doesn't fit is discarded, and items
    /// that don't fit right of the notch move to its left. A spacer beside an
    /// item right of the notch must therefore be wider than the remaining gap
    /// there, so that it moves left of the notch and fills that side instead.
    static func concealingLength(
        controlMinX: CGFloat,
        screen: NSScreen,
        applicationMenuMaxX: CGFloat?
    ) -> CGFloat {
        // Leave room for the native overflow indicator.
        let margin: CGFloat = 32
        let minimumLength: CGFloat = 32
        let menusMaxX = max(screen.frame.minX, applicationMenuMaxX ?? screen.frame.minX)

        guard
            let leftArea = screen.auxiliaryTopLeftArea,
            let rightArea = screen.auxiliaryTopRightArea
        else {
            return max(minimumLength, controlMinX - menusMaxX - margin)
        }

        let notchMinX = leftArea.maxX
        let notchMaxX = rightArea.minX
        guard controlMinX >= notchMaxX else {
            return max(minimumLength, min(controlMinX, notchMinX) - menusMaxX - margin)
        }

        let rightGap = controlMinX - notchMaxX
        let leftSegment = notchMinX - menusMaxX - margin
        if leftSegment > rightGap {
            return leftSegment
        }
        // The left side is too small to hold a spacer wider than the right
        // gap. Fill the right gap; items can still show left of the notch.
        return max(minimumLength, rightGap - margin)
    }

    func removeAll() {
        for spacer in spacers.values {
            spacer.item.isVisible = false
            NSStatusBar.system.removeStatusItem(spacer.item)
        }
        spacers.removeAll()
    }
}

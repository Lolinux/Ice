@preconcurrency import AXSwift
import Cocoa
import OSLog

/// Reanchors only a newly opened, movable popup of the clicked item's owner.
/// Existing application windows and windows away from a menu bar are untouched.
@available(macOS 27.0, *)
@MainActor
final class MacOS27PopupPositioner {
    private struct Window {
        let id: CGWindowID
        let pid: pid_t
        let frame: CGRect
    }

    private static let logger = Logger(category: "MacOS27PopupPositioner")
    private let pids: Set<pid_t>
    private let previousIDs: Set<CGWindowID>
    private let anchor: CGRect
    private let visibleScreen: CGRect
    private var observers = [AXSwift.Observer]()
    private var movedWindow: (element: UIElement, origin: CGPoint)?

    init?(item: MenuBarItem) {
        let geometry = MacOS27MenuBarItemProvider.agentGeometry()
        let controls = geometry.containersByOwner[ProcessInfo.processInfo.processIdentifier, default: []]
            .filter { $0.identifier == MenuBarItemTag.visibleControlItem.title }
        guard controls.count == 1, let anchor = controls.first?.frame,
              !geometry.overflowFrames.contains(where: { $0.intersects(anchor) }),
              let screen = NSScreen.screens.first(where: { CGDisplayBounds($0.displayID).contains(anchor) })
        else { return nil }
        self.anchor = anchor
        let display = CGDisplayBounds(screen.displayID)
        let visible = screen.visibleFrame
        visibleScreen = CGRect(x: display.minX + visible.minX - screen.frame.minX,
                               y: display.minY + screen.frame.maxY - visible.maxY,
                               width: visible.width, height: visible.height)
        pids = Set([item.ownerPID, item.sourcePID].compactMap { $0 })
        previousIDs = Set(Self.windows(ownedBy: pids).map(\.id))
        // Install before AXPress: popup notifications can arrive as soon as
        // the action returns, without waiting for a polling interval.
        for pid in pids {
            guard let app = NSRunningApplication(processIdentifier: pid),
                  let axApp = AXHelpers.application(for: app),
                  let observer = try? AXSwift.Observer(processID: pid, callback: { [weak self] _, element, _ in
                      MainActor.assumeIsolated { self?.positionIfReady(preferred: element) }
                  })
            else { continue }
            for notification: AXNotification in [.windowCreated, .focusedWindowChanged, .mainWindowChanged] {
                try? observer.addNotification(notification, forElement: axApp)
            }
            observers.append(observer)
        }
    }

    func positionNewPopup() async {
        defer {
            observers.forEach { $0.stop() }
            observers.removeAll()
        }
        // Check immediately. State may reuse a panel without sending a create
        // notification; short bounded polling handles that case as well.
        for attempt in 0 ..< 50 {
            guard !Task.isCancelled else { return }
            positionIfReady()
            if let movedWindow {
                do { try await Task.sleep(for: .milliseconds(80)) } catch { return }
                if let actual = AXHelpers.frame(for: movedWindow.element),
                   abs(actual.minX - movedWindow.origin.x) < 2, abs(actual.minY - movedWindow.origin.y) < 2 {
                    Self.logger.notice("Positioned popup below Ice at \(movedWindow.origin.debugDescription, privacy: .public)")
                } else {
                    Self.logger.notice("Popup owner did not retain the requested position")
                }
                return
            }
            do { try await Task.sleep(for: .milliseconds(attempt < 25 ? 8 : 50)) } catch { return }
        }
        Self.logger.debug("No new movable menu-bar popup was exposed by the clicked owner")
    }

    private func positionIfReady(preferred: UIElement? = nil) {
        guard movedWindow == nil else { return }
        let candidates = Self.windows(ownedBy: pids).filter { window in
            !previousIDs.contains(window.id) && window.frame.width > 40 && window.frame.height > 40 &&
            NSScreen.screens.contains { screen in
                let display = CGDisplayBounds(screen.displayID)
                return window.frame.minY >= display.minY && window.frame.minY <= display.minY + 80
            }
        }
        guard candidates.count == 1, let candidate = candidates.first,
              let app = NSRunningApplication(processIdentifier: candidate.pid),
              let axApp = AXHelpers.application(for: app)
        else { return }
        var windows: [UIElement] = preferred.map { [$0] } ?? []
        windows += (try? axApp.arrayAttribute(.windows)) ?? []
        for window in windows {
            guard AXHelpers.pid(for: window) == candidate.pid,
                  let frame = AXHelpers.frame(for: window),
                  abs(frame.minX - candidate.frame.minX) < 2,
                  abs(frame.minY - candidate.frame.minY) < 2,
                  abs(frame.width - candidate.frame.width) < 2,
                  abs(frame.height - candidate.frame.height) < 2,
                  (try? window.attributeIsSettable(.position)) == true,
                  let origin = MacOS27PopupGeometry.origin(size: frame.size, anchor: anchor, visibleScreen: visibleScreen)
            else { continue }
            // Mark before setting: AXPosition can itself emit notifications.
            movedWindow = (window, origin)
            do {
                try window.setAttribute(.position, value: origin)
            } catch {
                Self.logger.notice("Popup position is not writable: \(error, privacy: .public)")
            }
            return
        }
    }

    private static func windows(ownedBy pids: Set<pid_t>) -> [Window] {
        guard let entries = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]] else { return [] }
        return entries.compactMap { entry in
            guard let pid = entry[kCGWindowOwnerPID as String] as? pid_t, pids.contains(pid),
                  let id = entry[kCGWindowNumber as String] as? CGWindowID,
                  let bounds = entry[kCGWindowBounds as String] as? [String: Any],
                  let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary)
            else { return nil }
            return Window(id: id, pid: pid, frame: frame)
        }
    }
}

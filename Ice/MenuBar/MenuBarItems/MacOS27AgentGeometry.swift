import CoreGraphics

/// Matches one owner's hosted containers without confusing identities after a
/// drag. Owner-side AX frames can still describe the order before the move.
enum MacOS27AgentGeometry {
    struct Container {
        var identifier: String?
        var frame: CGRect
    }

    static func isDrawn(frame: CGRect?, otherFrames: [CGRect], overflowFrames: [CGRect]) -> Bool {
        guard let frame, frame.width > 0, frame.height > 0 else { return false }
        return !overflowFrames.contains { $0.intersects(frame) } &&
            !otherFrames.contains { $0.intersection(frame).width > 6 }
    }

    /// MenuBarAgent adds padding around an owner's narrow content frame. Keep
    /// the live owner check, but compare the centered content to its host slot.
    static func contentMatchesContainer(content: CGRect, container: CGRect) -> Bool {
        let values = [content.minX, content.minY, content.width, content.height,
                      container.minX, container.minY, container.width, container.height]
        guard values.allSatisfy(\.isFinite), content.width > 0, content.height > 0 else { return false }
        return container.insetBy(dx: -1, dy: -1).contains(content) &&
            abs(content.midX - container.midX) <= 1 &&
            abs(content.midY - container.midY) <= 1 &&
            container.width - content.width <= 16 &&
            container.height - content.height <= 12
    }

    /// Items are supplied in their old left-to-right order. Identified hosted
    /// containers take precedence; only unnamed containers can use that order.
    static func match(identifiers: [String], containers: [Container]) -> [Int: CGRect] {
        var result = [Int: CGRect]()
        var reserved = Set<Int>()
        for index in identifiers.indices {
            let identifier = identifiers[index]
            guard identifiers.filter({ $0 == identifier }).count == 1 else { continue }
            let matches = containers.indices.filter { containers[$0].identifier == identifier }
            guard matches.count == 1, let match = matches.first else { continue }
            result[index] = containers[match].frame
            reserved.insert(match)
        }

        // A known but ambiguous identifier must not be reinterpreted as an
        // unrelated item. Missing containers likewise cannot shift every match.
        let remainingItems = identifiers.indices.filter { index in
            result[index] == nil && !containers.contains { $0.identifier == identifiers[index] }
        }
        let remainingContainers = containers.indices.filter {
            !reserved.contains($0) && containers[$0].identifier == nil
        }.sorted { containers[$0].frame.minX < containers[$1].frame.minX }
        guard remainingItems.count == remainingContainers.count else { return result }
        for (item, container) in zip(remainingItems, remainingContainers) {
            result[item] = containers[container].frame
        }
        return result
    }
}

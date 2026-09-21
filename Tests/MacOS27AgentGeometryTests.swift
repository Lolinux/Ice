import CoreGraphics

@main
enum MacOS27AgentGeometryTests {
    static func main() {
        typealias Container = MacOS27AgentGeometry.Container
        let left = CGRect(x: 850, y: 1, width: 17, height: 30)
        let right = CGRect(x: 875, y: 1, width: 33, height: 30)
        let swapped = [Container(identifier: "boundary", frame: left), Container(identifier: "ice", frame: right)]
        let identified = MacOS27AgentGeometry.match(identifiers: ["ice", "boundary"], containers: swapped)
        precondition(identified[0] == right && identified[1] == left,
                     "A drag must preserve identities when owner-side order is stale")

        let anonymous = [Container(identifier: nil, frame: right), Container(identifier: nil, frame: left)]
        let fallback = MacOS27AgentGeometry.match(identifiers: ["app-a", "app-b"], containers: anonymous)
        precondition(fallback[0] == left && fallback[1] == right,
                     "Unidentified app items retain left-to-right matching")

        let mixed = MacOS27AgentGeometry.match(identifiers: ["app", "boundary"], containers: [
            Container(identifier: "boundary", frame: left), Container(identifier: nil, frame: right),
        ])
        precondition(mixed[0] == right && mixed[1] == left,
                     "Fallback must never reuse an identified container")
        precondition(MacOS27AgentGeometry.match(identifiers: ["a", "b"], containers: [anonymous[0]]).isEmpty,
                     "A missing container must not shift remaining items onto unrelated frames")
        precondition(MacOS27AgentGeometry.match(identifiers: ["ice"], containers: [
            Container(identifier: "ice", frame: left), Container(identifier: "ice", frame: right),
        ]).isEmpty, "Ambiguous hosted variants cannot be used as drag coordinates")
        precondition(MacOS27AgentGeometry.match(identifiers: ["other"], containers: swapped).isEmpty,
                     "Known containers cannot be assigned to an unrelated identifier")
        let host = CGRect(x: 880.5, y: 4.5, width: 17, height: 24)
        let content = CGRect(x: 887, y: 4.5, width: 3, height: 24)
        precondition(MacOS27AgentGeometry.contentMatchesContainer(content: content, container: host),
                     "A live narrow spacer matches its padded MenuBarAgent slot")
        precondition(!MacOS27AgentGeometry.contentMatchesContainer(content: right, container: host),
                     "An adjacent control cannot masquerade as the narrow spacer")
        precondition(!MacOS27AgentGeometry.contentMatchesContainer(content: content.offsetBy(dx: 5, dy: 0), container: host),
                     "Shifted stale content must not authorize a drag")
        precondition(!MacOS27AgentGeometry.contentMatchesContainer(content: .zero, container: host),
                     "Missing content cannot authorize a drag")
        precondition(!MacOS27AgentGeometry.isDrawn(frame: host, otherFrames: [], overflowFrames: [host]),
                     "A retained frame on the native overflow button must never receive a drag")
        precondition(!MacOS27AgentGeometry.isDrawn(frame: host, otherFrames: [host], overflowFrames: []),
                     "Identical stacked container frames are ambiguous even outside overflow")
        precondition(!MacOS27AgentGeometry.isDrawn(frame: nil, otherFrames: [], overflowFrames: []),
                     "Missing agent geometry cannot fall back to a stale draggable owner frame")
        precondition(MacOS27AgentGeometry.isDrawn(frame: left, otherFrames: [right], overflowFrames: [host.offsetBy(dx: 100, dy: 0)]),
                     "Separated, revealed containers can be dragged")
        print("PASS: 14 macOS 27 hosted geometry regression cases")
    }
}

#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ice-macos27-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

run_test() {
  local name="$1" source="$2"
  xcrun swiftc "$source" "Tests/$name.swift" -o "$TEST_DIR/$name"
  "$TEST_DIR/$name"
}

run_test NativeMenuBarBoundaryTests Ice/MenuBar/MenuBarItems/MacOS27NativeBoundary.swift
run_test NativeDragVisibilityStateTests Ice/MenuBar/MenuBarItems/MacOS27NativeBoundary.swift
run_test MacOS27DynamicItemStateTests Ice/MenuBar/MenuBarItems/MacOS27DynamicItemState.swift
run_test MacOS27LayoutOwnerTests Ice/MenuBar/MenuBarItems/MacOS27DynamicItemState.swift
run_test MacOS27AgentGeometryTests Ice/MenuBar/MenuBarItems/MacOS27AgentGeometry.swift
run_test MacOS27PopupGeometryTests Ice/MenuBar/MenuBarItems/MacOS27PopupGeometry.swift
run_test MenuBarGlyphImageTests Ice/MenuBar/LayoutBar/MenuBarGlyphImage.swift
run_test MenuBarOverlayGeometryTests Ice/MenuBar/Appearance/MenuBarOverlayGeometry.swift
run_test AverageColorTests Ice/Utilities/CGImage+AverageColor.swift

xcrun clang -c Tests/SpaceTypeBridgeFixture.c -o "$TEST_DIR/fixture.o"
xcrun swiftc -parse-as-library Shared/Bridging/Shims.swift \
  Tests/SpaceTypeBridgeTests.swift "$TEST_DIR/fixture.o" -o "$TEST_DIR/SpaceTypeBridgeTests"
"$TEST_DIR/SpaceTypeBridgeTests"
echo 'All 10 test suites passed.'

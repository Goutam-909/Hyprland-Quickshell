import QtQuick

// Drop-in replacement for Caelestia.Blobs' BlobGroup.
//
// The real BlobGroup (Blobs/blobgroup.cpp) is a C++ QObject that a
// BlobShape/BlobRect registers itself with. Its jobs are:
//   1. hold shared color / smoothing / cornerFill state
//   2. coordinate SDF blending + exclusion masks between sibling BlobRects
//   3. drive the shared "physics tick" (markDirty -> ensurePhysicsUpdated)
//      each frame while any member is deforming
//
// None of the actual dashboard usages in this project put more than one
// BlobRect in the same group at once and none use `exclude`,
// `excludeCorners`, or BlobInvertedRect - so job (2) is a no-op here.
// Job (1) is trivial. Job (3) is handled per-BlobRect in BlobRect.qml via
// SpringAnimation instead of a shared tick, so it isn't needed here either.
//
// If you later rely on real multi-rect metaball blending (adjacent BlobRects
// visually melting into one shape), this shim will NOT reproduce that -
// it only reproduces the shared-state + squish look of the individual rects.
QtObject {
    property color color: "transparent"
    property real smoothing: 0
    property bool cornerFill: true
}

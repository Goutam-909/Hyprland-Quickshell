import QtQuick

// Drop-in replacement for Caelestia.Blobs' BlobRect.
//
// The original (Blobs/blobrect.cpp + blobshape.cpp + blob.frag/.vert) is a
// custom QSGGeometryNode drawing an SDF rounded rect, deformed every frame
// by a mass-spring simulation driven by the item's on-screen velocity
// (see BlobRect::updatePhysics: velocity -> target 2x2 shear/scale matrix
// -> spring-integrated m_dm00/m_dm01/m_dm11 -> uploaded to the shader).
//
// This shim reproduces the *visible* effect - a soft jelly-ish squish
// whenever the rect moves or resizes - using an ordinary Rectangle plus
// QtQuick's built-in SpringAnimation, instead of a per-frame physics loop
// and a custom shader. It is a visual approximation, not a port:
//   - stiffness/damping/deformScale are mapped onto the SpringAnimation's
//     spring/damping/epsilon rather than driving the same matrix math
//   - there is no shader-level SDF blending between rects, no
//     `exclude` / `excludeCorners`, and no BlobInvertedRect equivalent
//   - per-corner radii (topLeftRadius etc.) aren't wired up; add them
//     yourself via Qt 6.7+'s native Rectangle corner-radius properties if
//     you need them, none of the current dashboard usages set them
//
// API kept compatible with the existing dashboard QML: color, group,
// radius, deformScale, stiffness, damping, and all normal Item/anchors
// behaviour (fillBlob animates anchors.topMargin directly, for example).
Rectangle {
    id: root

    property QtObject group: null
    property real deformScale: 0.0005
    property real stiffness: 200
    property real damping: 16

    color: group ? group.color : "transparent"
    antialiasing: true

    // --- squish approximation ---------------------------------------
    // Tracks the rect's own-space center; any change to x/y/width/height
    // (including anchor-driven changes) fires an "impulse" sized by how
    // far the center moved. The impulse briefly skews scaleX/scaleY and a
    // SpringAnimation-driven Behavior relaxes it back to 1, giving the
    // same "overshoots then settles" feel as the original's spring
    // integration, without a manual per-frame loop.
    property real _prevCx: x + width / 2
    property real _prevCy: y + height / 2
    property real _squishX: 1
    property real _squishY: 1

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root._squishX
        yScale: root._squishY
    }

    Behavior on _squishX {
        SpringAnimation {
            spring: root.stiffness / 30
            damping: root.damping / 6
            epsilon: 0.001
        }
    }
    Behavior on _squishY {
        SpringAnimation {
            spring: root.stiffness / 30
            damping: root.damping / 6
            epsilon: 0.001
        }
    }

    function _impulse() {
        const cx = x + width / 2;
        const cy = y + height / 2;
        const dx = cx - _prevCx;
        const dy = cy - _prevCy;
        _prevCx = cx;
        _prevCy = cy;

        // deformScale in the original is ~1e-4..1e-3 applied to raw pixel
        // velocity; scale it up here since we're working with a single
        // per-move delta rather than a continuous velocity sample.
        const mag = Math.min(Math.abs(dx) + Math.abs(dy), 400) * deformScale;
        if (mag < 0.001)
            return;

        // Stretch along the dominant axis of motion, squash the other,
        // matching the "leading edge stretches" look of the shader version.
        if (Math.abs(dx) >= Math.abs(dy)) {
            _squishX = 1 + mag;
            _squishY = 1 - mag * 0.6;
        } else {
            _squishY = 1 + mag;
            _squishX = 1 - mag * 0.6;
        }
        settleTimer.restart();
    }

    // Let the overshoot register for one frame, then let the
    // SpringAnimation Behaviors above ease it back to 1.
    Timer {
        id: settleTimer
        interval: 16
        onTriggered: {
            root._squishX = 1;
            root._squishY = 1;
        }
    }

    onXChanged: _impulse()
    onYChanged: _impulse()
    onWidthChanged: _impulse()
    onHeightChanged: _impulse()
}

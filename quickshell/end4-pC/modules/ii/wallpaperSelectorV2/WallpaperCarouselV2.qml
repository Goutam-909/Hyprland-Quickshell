import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell

// Carousel style ported from the source: an infinite horizontal strip,
// selection centered, neighbors shrinking/parallaxing toward the edges.
// Reproduced against `walls`/`currentIndex` (from the existing Wallpapers
// service) instead of the source's own launcher-state singleton. Static
// images only, per request - no shared video-surface machinery.
Item {
    id: root

    property var walls: []
    property int currentIndex: 0
    readonly property int columns: 1

    signal wallpaperPreviewed(string path)
    signal wallpaperActivated(string path)

    readonly property int count: root.walls.length

    function moveSelection(delta) {
        if (root.count === 0) return;
        root.moveCarousel(delta);
    }

    function activateCurrent() {
        const w = root.walls[root.currentIndex];
        if (w) root.wallpaperActivated(w.filePath);
    }

    // ─── Continuous animated position, in "steps" (1 step = 1 wallpaper).
    // carouselStep is the last committed integer index; carouselAnim is
    // where the strip is actually drawn, which a drag can push away from
    // carouselStep before it snaps back or on to the next one.
    property int carouselStep: 0
    property real carouselAnim: 0
    property bool dragging: false

    // Anim.qml, "bloom" (the default style) - exit mirrors entrance here too
    readonly property int animDuration: 400
    readonly property int animOutDuration: 320

    Behavior on carouselAnim {
        enabled: !root.dragging
        NumberAnimation { duration: root.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
    }

    onCurrentIndexChanged: {
        if (!root.dragging) {
            root.carouselStep = root.currentIndex;
            root.carouselAnim = root.currentIndex;
        }
    }
    onWallsChanged: {
        root.carouselStep = root.currentIndex;
        root.carouselAnim = root.currentIndex;
    }

    function moveCarousel(steps) {
        if (root.count === 0) return;
        const target = ((root.currentIndex + steps) % root.count + root.count) % root.count;
        root.currentIndex = target;
        root.carouselStep = target;
        root.carouselAnim = target;
        const w = root.walls[target];
        if (w) root.wallpaperPreviewed(w.filePath);
    }

    function carouselDragTo(dx) {
        root.dragging = true;
        root.carouselAnim = root.carouselStep - dx / root.slotSpacing;
    }

    function carouselDragEnd(dx, vx) {
        root.dragging = false;
        if (root.count === 0) return;
        const velocitySteps = Math.abs(vx) > 400 ? (vx > 0 ? -1 : 1) : 0;
        const rawSteps = -dx / root.slotSpacing;
        const stepDelta = Math.round(rawSteps) + (Math.round(rawSteps) === 0 ? velocitySteps : 0);
        const target = ((root.carouselStep + stepDelta) % root.count + root.count) % root.count;
        root.carouselStep = target;
        root.carouselAnim = target;
        root.currentIndex = target;
        const w = root.walls[target];
        if (w) root.wallpaperPreviewed(w.filePath);
    }

    // ─── Literal source geometry (WallpaperCarousel_other.qml) ───
    readonly property int barWidth: 220
    readonly property int barHeight: 440
    readonly property int slotSpacing: 262
    readonly property int captionGap: 14
    readonly property int visibleSlots: 7 // Settings.wallsVisible
    readonly property int halfVisible: Math.floor((visibleSlots - 1) / 2)
    readonly property int bufferSlots: 2
    readonly property int restSpan: halfVisible + bufferSlots
    readonly property int totalSlots: 2 * restSpan + 1

    readonly property real edgeFloor: 0.7
    readonly property real edgeRate: 0.07
    readonly property real edgeBreak: (1 - edgeFloor) / edgeRate
    readonly property real edgeClampedStep: slotSpacing - barWidth * (1 - edgeFloor)

    // How far the image pans inside its own tile, opposite the scroll
    // direction, so each card reads as a fixed window onto a slowly
    // drifting backdrop rather than a static crop. Bounded by rank
    // (not the raw carouselAnim) so it never slides out of frame.
    readonly property real parallaxPx: 75

    function edgeOffset(m) {
        if (m <= edgeBreak)
            return slotSpacing * m - (barWidth * edgeRate / 2) * m * m;
        const atBreak = slotSpacing * edgeBreak - (barWidth * edgeRate / 2) * edgeBreak * edgeBreak;
        return atBreak + edgeClampedStep * (m - edgeBreak);
    }

    Item {
        id: strip
        anchors.centerIn: parent
        width: root.width
        // Fixed height, not clamped to root.height - clamping it made the
        // cells' vertical-centering offset and the caption's fixed
        // top-offset disagree, so the caption landed a few px inside the
        // image instead of below it.
        height: root.barHeight + root.captionGap + 26

        Repeater {
            id: cells
            model: root.totalSlots

            Item {
                id: cell
                required property int index
                property int absStep: index - root.restSpan
                readonly property real rank: absStep - root.carouselAnim
                readonly property int wallIndex: root.count > 0 ? ((absStep % root.count) + root.count) % root.count : -1
                readonly property var wall: wallIndex >= 0 ? root.walls[wallIndex] : null
                readonly property bool isCenter: wallIndex >= 0 && wallIndex === root.currentIndex && Math.abs(rank) < 0.5
                readonly property real selFade: Math.max(0, 1 - Math.abs(rank) * 2)

                // relabel once a cell drifts a full step past the resting
                // buffer, keeping the fixed-size Repeater an endless ring
                function rebalance() {
                    while (absStep - root.carouselAnim > root.restSpan + 1)
                        absStep -= root.totalSlots;
                    while (absStep - root.carouselAnim < -(root.restSpan + 1))
                        absStep += root.totalSlots;
                }
                Connections {
                    target: root
                    function onCarouselAnimChanged() { cell.rebalance() }
                }

                x: strip.width / 2 - width / 2 + Math.sign(rank) * root.edgeOffset(Math.abs(rank))
                y: 0
                width: root.barWidth
                height: root.barHeight
                z: -Math.abs(rank)
                scale: Math.max(root.edgeFloor, 1 - Math.abs(rank) * root.edgeRate)
                opacity: cell.wall ? Math.max(0, Math.min(1, root.halfVisible + 1 - Math.abs(rank))) : 0
                visible: opacity > 0

                Rectangle {
                    id: thumb
                    anchors.fill: parent
                    radius: 12
                    clip: true
                    color: Qt.alpha(Appearance.colors.colPrimary, 0.11 + 0.11 * cell.selFade)

                    // Oversized and panned by -rank*parallaxPx, clipped by
                    // this Rectangle - the parallax "moving wallpaper
                    // inside the tile" effect from the source. Wide enough
                    // to cover the full fade range (|rank| <= halfVisible+1;
                    // past that the cell is invisible anyway) so panning
                    // never exposes an edge. Full-res source, not a
                    // pre-cropped thumbnail, so there's spare width to pan
                    // through without seams.
                    Image {
                        width: root.barWidth + ((root.halfVisible + 1) * root.parallaxPx + 20) * 2
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        x: (parent.width - width) / 2 - cell.rank * root.parallaxPx
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(0, root.barHeight)
                        source: cell.wall ? `file://${cell.wall.filePath}` : ""
                    }
                }

                Rectangle {
                    anchors.fill: thumb
                    radius: 12
                    color: "transparent"
                   // border.width: 1
                   // border.color: Qt.alpha(Appearance.colors.colPrimary, 0.33 + 0.67 * cell.selFade)
                }

                TapHandler {
                    enabled: cell.wall !== null
                    onTapped: {
                        if (cell.isCenter)
                            root.wallpaperActivated(cell.wall.filePath);
                        else
                            root.moveCarousel(Math.round(cell.rank));
                    }
                }

                DragHandler {
                    target: null
                    yAxis.enabled: false
                    enabled: cell.wall !== null
                    property real grabX: 0
                    onActiveChanged: {
                        if (active) {
                            grabX = centroid.scenePosition.x;
                        } else {
                            root.carouselDragEnd(centroid.scenePosition.x - grabX, centroid.velocity.x);
                        }
                    }
                    onCentroidChanged: {
                        if (active)
                            root.carouselDragTo(centroid.scenePosition.x - grabX);
                    }
                }
            }
        }

        StyledText {
            anchors.top: parent.top
            anchors.topMargin: root.barHeight + root.captionGap
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, strip.width)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            color: Appearance.colors.colOnLayer0
            font.pixelSize: Appearance.font.pixelSize.small
            text: {
                if (root.count === 0) return "";
                const idx = ((Math.round(root.carouselAnim) % root.count) + root.count) % root.count;
                const w = root.walls[idx];
                return w ? w.fileName : "";
            }
        }
    }
}

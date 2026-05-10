import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.config
import qs.modules.widgets.defaultview
import qs.modules.services

// Place at: modules/widgets/media/MediaWindow.qml
// Toggle:   echo "mediawindow" > /tmp/ambxst_ipc.pipe

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: GlobalStates.mediaWindowVisible

    // ── Padding applied uniformly on all four sides ───────────────────────────
    readonly property int pad: 16

    // Card position — default top-center below bar
    property int xPos: (Screen.width - cardWidth) / 2
    property int yPos: 12

    // Card width = view content + left pad + right pad
    readonly property int cardWidth: mediaView.implicitWidth + pad * 2

    // ── Input mask ────────────────────────────────────────────────────────────
    Item { id: fullRegion; anchors.fill: parent; visible: false }
    mask: Region {
        item: dragArea.pressed ? fullRegion : mediaCard
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Item {
        id: mediaCard
        x: root.xPos
        y: root.yPos
        width:  root.cardWidth
        // Height = view content + top pad + bottom pad — never clips
        height: mediaView.implicitHeight + root.pad * 2

        opacity: root.visible ? 1.0 : 0.0
        scale:   root.visible ? 1.0 : 0.94
        transformOrigin: Item.Top

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
        }
        Behavior on scale {
            enabled: Config.animDuration > 0
            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }
        Behavior on width {
            enabled: Config.animDuration > 0
            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }
        Behavior on height {
            enabled: Config.animDuration > 0
            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
        }

        // ── Background — same StyledRect the notch card uses ─────────────────
        StyledRect {
            anchors.fill: parent
            variant: "bg"
            radius: Styling.radius(20)
            enableShadow: true
            enableBorder: true
        }

        // ── Drag — whole card, controls steal focus via z-order ──────────────
        MouseArea {
            id: dragArea
            anchors.fill: parent
            z: 0
            hoverEnabled: true
            cursorShape: containsMouse && !pressed ? Qt.SizeAllCursor : Qt.ArrowCursor

            property point globalStart: Qt.point(0, 0)
            property int   startX: 0
            property int   startY: 0

            onPressed: mouse => {
                globalStart = mapToItem(null, mouse.x, mouse.y);
                startX = root.xPos;
                startY = root.yPos;
            }
            onPositionChanged: mouse => {
                if (!pressed) return;
                var p = mapToItem(null, mouse.x, mouse.y);
                root.xPos = Math.max(0, Math.min(Screen.width  - root.cardWidth,   startX + p.x - globalStart.x));
                root.yPos = Math.max(0, Math.min(Screen.height - mediaCard.height, startY + p.y - globalStart.y));
            }
        }

        // ── MediaPlayerView — uniform padding on all sides ────────────────────
        MediaPlayerView {
            id: mediaView
            anchors {
                top:          parent.top
                left:         parent.left
                right:        parent.right
                topMargin:    root.pad
                bottomMargin: root.pad
                leftMargin:   root.pad
                rightMargin:  root.pad
            }
            z: 1
        }


    }

    // ── Sync GlobalStates ─────────────────────────────────────────────────────
    onVisibleChanged: {
        if (!visible && GlobalStates.mediaWindowVisible)
            GlobalStates.mediaWindowVisible = false;
    }
    Connections {
        target: GlobalStates
        function onMediaWindowVisibleChanged() {
            root.visible = GlobalStates.mediaWindowVisible;
        }
    }
}

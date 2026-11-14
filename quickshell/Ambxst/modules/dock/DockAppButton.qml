pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Button {
    id: root

    required property var appToplevel
    property int lastFocused: -1
    property real iconSize: Config.dock?.iconSize ?? 40
    property real countDotWidth: 10
    property real countDotHeight: 4
    property string dockPosition: "bottom"

    // ── macOS-style behaviour (driven by DockContent) ──
    property bool macStyle: false
    property var dockRoot: null
    property bool launching: false     // bouncing while the app starts
    property real bounceY: 0

    readonly property real slot: iconSize + 8
    readonly property real baseWidth: isSeparator ? 2 : slot

    // Resting centre in scene coords (layout never changes size, so this never moves)
    function sceneRestCenter() {
        if (!parent || !dockRoot)
            return 0;
        // Layout-relative offset from the dock centre; independent of the glass width
        return dockRoot.sceneCenter() + x + width / 2 - parent.width / 2;
    }
    readonly property real magScale: (macStyle && dockRoot && !isSeparator) ? dockRoot.scaleAt(sceneRestCenter()) : 1
    readonly property real magDisp: (macStyle && dockRoot) ? dockRoot.dispAt(sceneRestCenter()) : 0

    // Scale from the dock floor, shift sideways; the hit area follows the visuals
    transform: [
        Scale {
            origin.x: root.width / 2
            origin.y: root.height
            xScale: root.magScale
            yScale: root.magScale
        },
        Translate {
            x: root.magDisp
        }
    ]

    // Position helpers
    readonly property bool isBottom: dockPosition === "bottom"
    readonly property bool isLeft: dockPosition === "left"
    readonly property bool isRight: dockPosition === "right"
    readonly property bool isVertical: isLeft || isRight

    readonly property bool isSeparator: appToplevel?.appId === "SEPARATOR"
    readonly property var desktopEntry: (isSeparator || !appToplevel) ? null : DesktopEntries.heuristicLookup(appToplevel.appId)
    readonly property bool appIsActive: !isSeparator && (appToplevel?.toplevels?.some(t => t.activated === true) ?? false)
    readonly property bool appIsRunning: !isSeparator && (appToplevel?.toplevelCount ?? 0) > 0

    readonly property bool showIndicators: !isSeparator && (Config.dock?.showRunningIndicators ?? true) && appIsRunning
    readonly property int instanceCount: (isSeparator || !appToplevel) ? 0 : appToplevel.toplevelCount

    enabled: !isSeparator
    implicitWidth: isSeparator ? (isVertical ? iconSize * 0.6 : 2) : slot
    implicitHeight: isSeparator ? (isVertical ? 2 : iconSize * 0.6) : slot

    padding: 0
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    background: Item {
        StyledRect {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: Styling.radius(-2)
            variant: "focus"
            visible: !root.isSeparator && !root.macStyle && (root.hovered || root.pressed)
            opacity: root.pressed ? 1 : 0.7

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }
    }

    contentItem: Item {
        // Separator
        Loader {
            active: root.isSeparator
            anchors.centerIn: parent
            sourceComponent: Separator {
                vert: !root.isVertical
                implicitWidth: root.isVertical ? root.iconSize * 0.6 : 2
                implicitHeight: root.isVertical ? 2 : root.iconSize * 0.6
            }
        }

        // App icon and indicators
        Loader {
            active: !root.isSeparator
            anchors.fill: parent
            sourceComponent: Item {
                anchors.fill: parent

                // App icon
                Item {
                    id: appIconContainer
                    anchors.centerIn: root.macStyle ? undefined : parent
                    anchors.horizontalCenter: root.macStyle ? parent.horizontalCenter : undefined
                    anchors.bottom: root.macStyle ? parent.bottom : undefined
                    anchors.bottomMargin: (root.slot - root.iconSize) / 2
                    width: root.iconSize
                    height: root.iconSize
                    transform: Translate { y: root.bounceY }
                    opacity: root.pressed && root.macStyle ? 0.6 : 1

                    readonly property string iconName: AppSearch.getCachedIcon(root.appToplevel?.appId ?? "")

                    Image {
                        id: appIcon
                        anchors.fill: parent
                        source: "image://icon/" + appIconContainer.iconName
                        sourceSize.width: root.iconSize * 2.5
                        sourceSize.height: root.iconSize * 2.5
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        onStatusChanged: {
                            if (status === Image.Error)
                                source = "image://icon/application-x-executable";
                        }
                    }

                    Tinted {
                        sourceItem: appIcon
                        anchors.fill: appIcon
                    }
                }

                // Running indicators - horizontal layout (for bottom dock)
                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -2
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3
                    scale: root.macStyle ? 1 / root.magScale : 1   // keep the dot a constant size
                    visible: root.showIndicators && !root.isVertical

                    Repeater {
                        model: root.macStyle ? 1 : Math.min(root.instanceCount, 3)
                        delegate: Rectangle {
                            required property int index
                            width: (root.macStyle || root.instanceCount > 3) ? root.countDotHeight : root.countDotWidth
                            height: root.countDotHeight
                            radius: height / 2
                            color: root.appIsActive ? Styling.srItem("overprimary") : Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.4)

                            // No Behavior here on purpose: animating this on every focus change
                            // re-renders the whole-screen shadow layer each frame (high GPU use).
                        }
                    }
                }

                // Running indicators - vertical layout (for left/right dock)
                // Left dock: indicators on left edge, Right dock: indicators on right edge
                Column {
                    anchors.left: root.isLeft ? parent.left : undefined
                    anchors.leftMargin: -2
                    anchors.right: root.isRight ? parent.right : undefined
                    anchors.rightMargin: -2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    visible: root.showIndicators && root.isVertical

                    Repeater {
                        model: Math.min(root.instanceCount, 3)
                        delegate: Rectangle {
                            required property int index
                            width: root.countDotHeight
                            height: root.instanceCount <= 3 ? root.countDotWidth : root.countDotHeight
                            radius: width / 2
                            color: root.appIsActive ? Styling.srItem("overprimary") : Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.4)

                            // No Behavior here on purpose: animating this on every focus change
                            // re-renders the whole-screen shadow layer each frame (high GPU use).
                        }
                    }
                }
            }
        }
    }

    // Left click: launch or cycle through windows
    onClicked: {
        if (isSeparator)
            return;

        if (appToplevel.toplevelCount === 0) {
            // Launch the app
            if (desktopEntry) {
                AppSearch.launchApp(desktopEntry);
                if (macStyle)
                    launching = true;
            }
            return;
        }

        // Cycle through running windows
        lastFocused = (lastFocused + 1) % appToplevel.toplevelCount;
        appToplevel.toplevels[lastFocused].activate();
    }

    // Middle click: always launch new instance
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton

        onClicked: mouse => {
            if (root.isSeparator)
                return;

            if (mouse.button === Qt.MiddleButton) {
                // Launch new instance
                if (root.desktopEntry) {
                    AppSearch.launchApp(root.desktopEntry);
                }
            } else if (mouse.button === Qt.RightButton) {
                // Toggle pin
                TaskbarApps.togglePin(root.appToplevel?.appId ?? "");
            }
        }
    }

    // macOS-style launch bounce: hop until the window appears (or 10s timeout)
    onAppIsRunningChanged: if (appIsRunning) launching = false

    Timer {
        interval: 10000
        running: root.launching
        onTriggered: root.launching = false
    }

    SequentialAnimation {
        running: root.launching
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation {
            target: root
            property: "bounceY"
            to: -root.iconSize * 0.5
            duration: 260
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "bounceY"
            to: 0
            duration: 260
            easing.type: Easing.InQuad
        }
        PauseAnimation { duration: 80 }
    }

    // Tooltip
    StyledToolTip {
        show: root.hovered && !root.isSeparator
        tooltipText: root.desktopEntry?.name ?? root.appToplevel?.appId ?? ""
    }
}

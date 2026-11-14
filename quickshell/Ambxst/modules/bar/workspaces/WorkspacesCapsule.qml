import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.globals
import qs.config

// Capsule/dot workspace indicator for the bar — literally the same technique
// as the island's IslandWorkspaces (uniform-spaced dots that individually
// animate into a capsule when active, Row/Column reflows naturally), just
// re-themed to the bar's Styling/Colors/Config system instead of the
// island's fixed Appearance palette, and wrapped in a pill background sized
// to match your other bar widgets.
//
// The pill's implicitWidth/implicitHeight are bound DIRECTLY to the Row's
// (or Column's) own implicitWidth/implicitHeight — never computed from a
// separate parallel formula. That direct binding is what keeps the
// background and the dots perfectly in sync at all times, exactly like the
// island version does with `implicitWidth: wsRow.implicitWidth`.
Item {
    id: root
    required property var bar
    required property string orientation

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)

    property int widgetPadding: 10
    property real radius: Styling.radius(0)
    property real startRadius: radius
    property real endRadius: radius

    property int baseSize: 36
    property real dotSize: 8
    property real capsuleLength: 30
    property real gap: 7
    property real emptyOpacity: 0.5
    readonly property color usedColor: Colors.overBackground
    readonly property color activeColor: Colors.primary// Styling.srItem("primary")

    readonly property int workspaceGroup: Math.floor((monitor?.activeWorkspace?.id - 1 || 0) / Config.workspaces.shown)
    property list<bool> workspaceOccupied: []
    property list<int> dynamicWorkspaceIds: []
    property int effectiveWorkspaceCount: Config.workspaces.dynamic ? dynamicWorkspaceIds.length : Config.workspaces.shown

    readonly property int activeWs: monitor?.activeWorkspace?.id ?? 1

    function updateWorkspaceOccupied() {
        if (Config.workspaces.dynamic) {
            const occupiedIds = Hyprland.workspaces.values.filter(ws => HyprlandData.workspaceOccupationMap[ws.id]).map(ws => ws.id).sort((a, b) => a - b).slice(0, Config.workspaces.shown);

            const activeId = monitor?.activeWorkspace?.id || 1;
            if (!occupiedIds.includes(activeId)) {
                occupiedIds.push(activeId);
                occupiedIds.sort((a, b) => a - b);
                if (occupiedIds.length > Config.workspaces.shown) {
                    occupiedIds.pop();
                }
            }

            dynamicWorkspaceIds = occupiedIds;
            workspaceOccupied = Array.from({
                length: dynamicWorkspaceIds.length
            }, (_, i) => HyprlandData.workspaceOccupationMap[dynamicWorkspaceIds[i]]);
        } else {
            workspaceOccupied = Array.from({
                length: Config.workspaces.shown
            }, (_, i) => {
                const wsId = workspaceGroup * Config.workspaces.shown + i + 1;
                return HyprlandData.workspaceOccupationMap[wsId];
            });
        }
    }

    function getWorkspaceId(index) {
        if (Config.workspaces.dynamic) {
            return dynamicWorkspaceIds[index] || 1;
        }
        return workspaceGroup * Config.workspaces.shown + index + 1;
    }

    Timer {
        id: updateTimer
        interval: 100
        repeat: false
        onTriggered: root.updateWorkspaceOccupied()
    }

    Component.onCompleted: updateTimer.restart()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateTimer.restart();
        }
    }
    Connections {
        target: monitor
        function onActiveWorkspaceChanged() {
            updateTimer.restart();
        }
    }
    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            updateTimer.restart();
        }
    }
    onWorkspaceGroupChanged: updateTimer.restart()

    // Pill size follows the Row/Column exactly — same pattern as the
    // island's `implicitWidth: wsRow.implicitWidth`.
    implicitWidth: orientation === "vertical" ? baseSize : wsRow.implicitWidth + widgetPadding * 2
    implicitHeight: orientation === "vertical" ? wsColumn.implicitHeight + widgetPadding * 2 : baseSize

    readonly property bool effectiveContainBar: Config.bar.containBar && (Config.bar.frameEnabled ?? false)

    StyledRect {
        id: bgRect
        variant: "bg"
        anchors.fill: parent
        enableShadow: Config.showBackground && (!effectiveContainBar || Config.bar.keepBarShadow)

        topLeftRadius: root.startRadius
        topRightRadius: orientation === "vertical" ? root.startRadius : root.endRadius
        bottomLeftRadius: orientation === "vertical" ? root.endRadius : root.startRadius
        bottomRightRadius: root.endRadius
    }

    // Scroll anywhere → switch workspace (matches IslandWorkspaces).
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`);
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: event => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`hl.dsp.workspace.toggle_special()`);
            }
        }
    }

    // ---- Horizontal: uniform-spaced dots, active one grows into a capsule ----
    Row {
        id: wsRow
        visible: orientation === "horizontal"
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            model: root.effectiveWorkspaceCount

            delegate: Item {
                id: delH
                required property int index
                readonly property int wsId: root.getWorkspaceId(index)
                readonly property bool isActive: root.activeWs === wsId
                readonly property bool isOccupied: root.workspaceOccupied[index] ?? false

                width: indicatorH.width
                height: root.dotSize

                Rectangle {
                    id: indicatorH
                    anchors.centerIn: parent
                    width: delH.isActive ? root.capsuleLength : root.dotSize
                    height: root.dotSize
                    radius: height / 2
                    color: delH.isActive ? root.activeColor : root.usedColor
                    opacity: delH.isActive ? 1 : (delH.isOccupied ? 1 : root.emptyOpacity)

                    Behavior on width {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: Hyprland.dispatch(`hl.dsp.focus({workspace = ${delH.wsId}})`)
                }
            }
        }
    }

    // ---- Vertical: same technique, capsule grows in height instead ----
    Column {
        id: wsColumn
        visible: orientation === "vertical"
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            model: root.effectiveWorkspaceCount

            delegate: Item {
                id: delV
                required property int index
                readonly property int wsId: root.getWorkspaceId(index)
                readonly property bool isActive: root.activeWs === wsId
                readonly property bool isOccupied: root.workspaceOccupied[index] ?? false

                width: root.dotSize
                height: indicatorV.height

                Rectangle {
                    id: indicatorV
                    anchors.centerIn: parent
                    width: root.dotSize
                    height: delV.isActive ? root.capsuleLength : root.dotSize
                    radius: width / 2
                    color: delV.isActive ? root.activeColor : root.usedColor
                    opacity: delV.isActive ? 1 : (delV.isOccupied ? 1 : root.emptyOpacity)

                    Behavior on height {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: Hyprland.dispatch(`hl.dsp.focus({workspace = ${delV.wsId}})`)
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

// Minimal-pill workspace indicator: a row (or column) of small dots that
// grow into a pill for the active/hovered workspace. Ported from a
// Niri-only design onto this shell's compositor-agnostic WorkspaceModel/WM
// APIs, so it works the same on both Hyprland and Niri.
//
// Positions are computed and placed manually (instead of GridLayout) with
// a Behavior on x/y, so when a dot grows/shrinks its neighbours glide over
// smoothly in sync instead of snapping to their new spot instantly.
Item {
    id: root

    WorkspaceModel {
        id: wsModel
        screen: root.QsWindow.window?.screen
    }

    property bool vertical: Config.options.bar.vertical
    readonly property real barThickness: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight

    property real dotSize: 10
    property real activeSize: 32
    property real itemSpacing: 8

    property int workspaceIndexInGroup: (wsModel.activeNumber - 1) % wsModel.shownCount
    property int hoveredIndex: -1

    function sizeFor(index) {
        return (index === root.workspaceIndexInGroup) ? root.activeSize : root.dotSize;
    }
    function offsetFor(index) {
        let offset = 0;
        for (let i = 0; i < index; i++)
            offset += sizeFor(i) + root.itemSpacing;
        return offset;
    }
    readonly property real totalSize: {
        let total = 0;
        for (let i = 0; i < wsModel.shownCount; i++)
            total += sizeFor(i);
        return total + Math.max(0, wsModel.shownCount - 1) * root.itemSpacing;
    }

    implicitWidth: vertical ? barThickness : totalSize + 16
    implicitHeight: vertical ? totalSize + 16 : barThickness

    function switchRelative(direction) {
        WM.switchWorkspaceRelative(direction);
    }

    // Scroll anywhere on the widget (including the gaps between dots) to
    // switch workspaces, same as the default design. Sits behind the dots
    // so their own click handling still takes priority when hovered.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y < 0)
                root.switchRelative("next");
            else if (event.angleDelta.y > 0)
                root.switchRelative("prev");
        }
    }

    Item {
        id: layout
        anchors.centerIn: parent
        width: root.vertical ? root.dotSize : root.totalSize
        height: root.vertical ? root.totalSize : root.dotSize

        Repeater {
            model: wsModel.shownCount

            delegate: Item {
                id: delegateRoot
                required property int index
                readonly property int wsId: wsModel.getWorkspaceIdAt(index)
                property bool active: index === root.workspaceIndexInGroup
                property bool hasWindows: wsModel.occupied[index] ?? false
                property bool isHovered: root.hoveredIndex === index

                x: root.vertical ? 0 : root.offsetFor(index)
                y: root.vertical ? root.offsetFor(index) : 0
                implicitWidth: root.vertical ? root.dotSize : root.sizeFor(index)
                implicitHeight: root.vertical ? root.sizeFor(index) : root.dotSize
                width: implicitWidth
                height: implicitHeight

                Behavior on x {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                Behavior on implicitWidth {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                Behavior on implicitHeight {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2

                    color: delegateRoot.active ? Appearance.colors.colPrimary
                         : delegateRoot.hasWindows ? Appearance.colors.colOnSurface
                         : delegateRoot.isHovered ? Appearance.colors.colLayer2Hover
                         : Appearance.colors.colLayer4

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: root.hoveredIndex = delegateRoot.index
                    onExited: if (root.hoveredIndex === delegateRoot.index) root.hoveredIndex = -1
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton)
                            WM.switchWorkspace(delegateRoot.wsId);
                        else if (mouse.button === Qt.RightButton)
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                    onWheel: event => {
                        if (event.angleDelta.y < 0)
                            root.switchRelative("next");
                        else if (event.angleDelta.y > 0)
                            root.switchRelative("prev");
                    }
                }
            }
        }
    }
}

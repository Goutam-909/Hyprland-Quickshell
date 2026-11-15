import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets
import qs.modules.ii.notch.dashboard

Item {
    id: notchContainer
    required property var screen

    readonly property alias notchOpen: root_.notchOpen
    readonly property alias notchHitbox: hitbox

    QtObject {
        id: root_
        readonly property bool notchOpen: GlobalStates.notchOpen
    }

    readonly property bool hasActiveNotifications: Notifications.popupList.length > 0
    readonly property bool isExpanded: stack.depth > 1

    readonly property int animDuration: C.Config.options.notch.animDuration
    readonly property string position: C.Config.options.notch.position

    z: 1000

    // ---- sizing ----------------------------------------------------------
    property int collapsedHeight: 34
    property int collapsedWidth: 140

    implicitWidth: stack.currentItem ? Math.max(stack.currentItem.implicitWidth + 32, collapsedWidth) : collapsedWidth
    implicitHeight: stack.currentItem ? Math.max(stack.currentItem.implicitHeight + 24, collapsedHeight) : collapsedHeight

    width: implicitWidth
    height: implicitHeight

    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

    Behavior on implicitWidth {
        enabled: notchContainer.animDuration > 0
        NumberAnimation {
            duration: notchContainer.animDuration
            easing.type: notchContainer.isExpanded ? Easing.OutBack : Easing.OutQuart
            easing.overshoot: notchContainer.isExpanded ? 1.2 : 1.0
        }
    }

    Behavior on implicitHeight {
        enabled: notchContainer.animDuration > 0
        NumberAnimation {
            duration: notchContainer.animDuration
            easing.type: notchContainer.isExpanded ? Easing.OutBack : Easing.OutQuart
            easing.overshoot: notchContainer.isExpanded ? 1.2 : 1.0
        }
    }

    // ---- hit region used by the PanelWindow's mask (keeps click-through
    //      everywhere except the visible notch pill) -----------------------
    Item {
        id: hitbox
        anchors.top: notchContainer.position === "bottom" ? undefined : parent.top
        anchors.bottom: notchContainer.position === "bottom" ? parent.bottom : undefined
        anchors.horizontalCenter: parent.horizontalCenter
        width: notchBg.width
        height: notchBg.height
    }

    // ---- background pill --------------------------------------------------
    StyledRectangle {
        id: notchBg
        contentLayer: StyledRectangle.ContentLayer.Pane
        visible: C.Config.options.notch.showBackground
        anchors.top: notchContainer.position === "bottom" ? undefined : parent.top
        anchors.bottom: notchContainer.position === "bottom" ? parent.bottom : undefined
        anchors.horizontalCenter: parent.horizontalCenter
        width: notchContainer.implicitWidth
        height: notchContainer.implicitHeight

        readonly property int baseRadius: C.Config.options.notch.roundness
        radius: (notchContainer.notchOpen || notchContainer.hasActiveNotifications) ? baseRadius + 14 : baseRadius

        Behavior on radius {
            enabled: notchContainer.animDuration > 0
            NumberAnimation {
                duration: notchContainer.animDuration
                easing.type: notchContainer.isExpanded ? Easing.OutBack : Easing.OutQuart
                easing.overshoot: notchContainer.isExpanded ? 1.2 : 1.0
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowBlur: 0.6
            shadowVerticalOffset: notchContainer.position === "bottom" ? -4 : 4
        }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: notchContainer.parentHoveredChanged(hovered)
        }

        MouseArea {
            anchors.fill: parent
            enabled: !notchContainer.notchOpen
            onClicked: GlobalStates.notchOpen = true
        }
    }

    signal parentHoveredChanged(bool hovered)

    // ---- content stack ------------------------------------------------
    StackView {
        id: stack
        anchors.centerIn: notchBg
        width: currentItem ? currentItem.implicitWidth : notchContainer.collapsedWidth
        height: currentItem ? currentItem.implicitHeight : notchContainer.collapsedHeight
        clip: true
        initialItem: defaultViewComponent

        pushEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: notchContainer.animDuration } }
        pushExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: notchContainer.animDuration } }
        popEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: notchContainer.animDuration } }
        popExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: notchContainer.animDuration } }
    }

    Component {
        id: defaultViewComponent
        NotchDefaultView {}
    }

    Component {
        id: dashboardViewComponent
        NotchDashboard {}
    }

    Connections {
        target: GlobalStates
        function onNotchOpenChanged() {
            if (GlobalStates.notchOpen) {
                stack.push(dashboardViewComponent);
            } else if (stack.depth > 1) {
                stack.pop();
            }
        }
    }

    // ---- transient notification popup, shown above the pill on top of
    //      whatever else the notch is doing --------------------------------
    NotchNotificationView {
        id: notificationPopup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: notchContainer.position === "bottom" ? undefined : notchBg.bottom
        anchors.bottom: notchContainer.position === "bottom" ? notchBg.top : undefined
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        visible: notchContainer.hasActiveNotifications && !notchContainer.notchOpen
        opacity: visible ? 1 : 0

        Behavior on opacity {
            enabled: notchContainer.animDuration > 0
            NumberAnimation { duration: notchContainer.animDuration; easing.type: Easing.OutQuart }
        }
    }
}

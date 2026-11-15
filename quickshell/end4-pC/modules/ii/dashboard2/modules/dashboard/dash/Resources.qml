import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Controls
import qs.modules.common

Row {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    padding: Appearance.dashboard.padding.large
    spacing: Appearance.dashboard.spacing.normal

    Resource {
        icon: "memory"
        value: SystemUsage.cpuPerc
        colour: Appearance.m3colors.m3error
    }

    Resource {
        icon: "memory_alt"
        value: SystemUsage.memPerc
        colour: Appearance.m3colors.m3primary
    }

    Resource {
        icon: "hard_disk"
        value: SystemUsage.storagePerc
        colour: Appearance.m3colors.m3secondary
    }

    component Resource: Item {
        id: res

        required property string icon
        required property real value
        required property color colour

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.dashboard.padding.large
        implicitWidth: icon.implicitWidth

        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: icon.top
            anchors.bottomMargin: Appearance.dashboard.spacing.small

            implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.resourceProgessThickness

            color: Appearance.m3colors.m3primaryContainer
            radius: Appearance.rounding.full

            StyledRect {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: res.value * parent.height

                color: res.colour
                radius: Appearance.rounding.full
            }
        }

        MaterialIcon {
            id: icon

            anchors.bottom: parent.bottom

            text: res.icon
            color: res.colour
        }

        Behavior on value {
            NumberAnimation {
                duration: Appearance.dashboard.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }
}




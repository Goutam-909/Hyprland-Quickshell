pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.modules.common

StyledRect {
    id: root

    required property string icon
    required property string label
    required property string subLabel
    required property color accent
    required property real usage // 0..1
    required property real temperature // celsius

    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.large

    implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.perfHeroCardWidth
    implicitHeight: Math.max(tempProg.implicitHeight + detailsCol.implicitHeight + Appearance.dashboard.spacing.large, usageShape.implicitHeight + usageLabel.implicitHeight) + Appearance.dashboard.padding.large * 2

    CircularProgress {
        id: tempProg

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Appearance.dashboard.padding.large

        fgColour: root.accent
        spacing: Appearance.dashboard.spacing.small
        strokeWidth: Config.options.caelestiaDashboard.dashboard.sizes.perfRingThickness
        implicitSize: Math.max(icon.implicitWidth, icon.implicitHeight) + Appearance.dashboard.padding.normal * 2
        value: root.usage

        MaterialIcon {
            id: icon
            anchors.centerIn: parent
            text: root.icon
            color: root.accent
            font.pointSize: Appearance.dashboard.fontSize.larger
        }
    }

    ColumnLayout {
        anchors.left: tempProg.right
        anchors.right: usageShape.left
        anchors.verticalCenter: tempProg.verticalCenter
        anchors.margins: Appearance.dashboard.spacing.large
        spacing: Appearance.dashboard.spacing.small

        StyledText {
            text: root.label
            color: root.accent
            font.pointSize: Appearance.dashboard.fontSize.normal
        }

        StyledText {
            Layout.fillWidth: true
            text: root.subLabel
            color: Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.small
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        id: detailsCol

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.dashboard.padding.large
        spacing: Appearance.dashboard.spacing.small

        RowLayout {
            Layout.leftMargin: -Appearance.dashboard.padding.small
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: root.temperature > 90 ? "thermometer_alert" : "thermometer"
                color: root.temperature > 90 ? "#e05252" : root.accent
                fill: 1
                font.pointSize: Appearance.dashboard.fontSize.small
            }

            StyledText {
                text: isNaN(root.temperature) ? qsTr("—") : Config.options.caelestiaDashboard.dashboard.useFahrenheitPerformance ? `${Math.ceil(root.temperature * 1.8 + 32)}°F` : `${Math.ceil(root.temperature)}°C`
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.small
            }
        }

        StyledProgressBar {
            value: root.temperature / 100
            implicitHeight: Appearance.dashboard.padding.small
            fgColour: root.accent
            indeterminate: isNaN(root.usage) || isNaN(root.temperature)
        }
    }

    MaterialShape {
        id: usageShape

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.dashboard.padding.normal

        implicitSize: Config.options.caelestiaDashboard.dashboard.sizes.perfUsageShapeSize
        color: Appearance.m3colors.m3primaryContainer
        shape: {
            if (root.usage >= 0.8)
                return MaterialShape.SoftBurst;
            if (root.usage >= 0.4)
                return MaterialShape.Sunny;
            return MaterialShape.Cookie4Sided;
        }

        Behavior on color {
            ColorAnimation {
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }

        Behavior on shape {
            NumberAnimation {
                duration: Appearance.dashboard.durations.normal
            }
        }

        StyledText {
            id: usageLabel

            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            text: qsTr("Usage")
            color: Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.small
        }

        StyledText {
            anchors.centerIn: parent
            text: isNaN(root.usage) ? "…%" : Math.round(root.usage * 100) + "%"
            color: root.accent
            font.pointSize: Appearance.dashboard.fontSize.large
        }
    }
}




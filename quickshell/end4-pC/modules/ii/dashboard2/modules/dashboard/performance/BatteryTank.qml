pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets.blobs
import qs.modules.common

StyledClippingRect {
    id: root

    property real animPerc: UPower.displayDevice?.percentage ?? 0
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice?.state)

    color: Appearance.m3colors.m3primaryContainer
    radius: Appearance.rounding.large

    implicitWidth: (Config.options.caelestiaDashboard.dashboard.performance.showCpu || Config.options.caelestiaDashboard.dashboard.performance.showGpu || Config.options.caelestiaDashboard.dashboard.performance.showStorage || Config.options.caelestiaDashboard.dashboard.performance.showMemory) ? Config.options.caelestiaDashboard.dashboard.sizes.perfBattWidth : Config.options.caelestiaDashboard.dashboard.sizes.perfBattWidthSingle
    implicitHeight: Config.options.caelestiaDashboard.dashboard.sizes.perfBattHeight

    Behavior on animPerc {
        NumberAnimation {
            duration: Appearance.dashboard.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Contents {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.dashboard.padding.normal

        accentColour: Appearance.m3colors.m3primary
        textColour: Appearance.m3colors.m3secondary
    }

    // Liquid fill, bottom-anchored, with a soft wobbling blob edge
    // standing in for a wave.
    Item {
        id: liquid

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: parent.height * root.animPerc

        clip: true

        BlobGroup {
            id: blobGroup
            color: Appearance.m3colors.m3primary
            smoothing: Appearance.rounding.large
            cornerFill: true

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.dashboard.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }
        }

        BlobRect {
            id: fillBlob

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.topMargin: -Appearance.dashboard.padding.large

            group: blobGroup
            radius: Appearance.rounding.large
            deformScale: 0.0002

            SequentialAnimation {
                running: root.visible
                loops: Animation.Infinite

                NumberAnimation {
                    target: fillBlob
                    property: "anchors.topMargin"
                    to: -Appearance.dashboard.padding.large - Appearance.dashboard.spacing.small
                    duration: 2200
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: fillBlob
                    property: "anchors.topMargin"
                    to: -Appearance.dashboard.padding.large
                    duration: 2200
                    easing.type: Easing.InOutSine
                }
            }
        }

        Contents {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: layout.anchors.margins
            height: layout.height

            accentColour: Appearance.m3colors.m3primaryContainer
            textColour: Appearance.m3colors.m3surface
        }
    }

    component Contents: ColumnLayout {
        id: contents

        required property color accentColour
        required property color textColour

        spacing: 0

        MaterialIcon {
            Layout.leftMargin: -Appearance.dashboard.padding.small
            text: "battery_full"
            color: contents.accentColour
            font.pointSize: Appearance.dashboard.fontSize.large
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Battery")
            color: contents.textColour
            font.pointSize: Appearance.dashboard.fontSize.smaller
        }

        Item {
            Layout.fillHeight: true
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            animate: true
            color: contents.textColour
            font.pointSize: Appearance.dashboard.fontSize.small
            text: {
                if (UPower.displayDevice?.state === UPowerDeviceState.FullyCharged)
                    return qsTr("Full");
                if (root.charging)
                    return qsTr("Charging");

                const s = UPower.displayDevice?.timeToEmpty;
                if (!s)
                    return qsTr("…");

                const hr = Math.floor(s / 3600);
                const min = Math.floor((s % 3600) / 60);
                return hr > 0 ? `${hr}h ${min}m` : `${min}m`;
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: "bolt"
                color: contents.accentColour
                fill: 1
                font.pointSize: Appearance.dashboard.fontSize.large
                opacity: root.charging ? 1 : 0
                scale: root.charging ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.small
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.small
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }
            }

            StyledText {
                text: `${Math.round((UPower.displayDevice?.percentage ?? 0) * 100)}%`
                color: contents.accentColour
                font.pointSize: Appearance.dashboard.fontSize.large
            }
        }
    }
}

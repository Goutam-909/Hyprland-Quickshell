pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets.blobs
import qs.modules.common
import qs.services

Item {
    id: root

    property bool open
    readonly property real padding: Appearance.dashboard.padding.large

    implicitWidth: btn.implicitWidth * 0.9
    implicitHeight: btn.implicitHeight * 0.9

    BlobGroup {
        id: blobGroup

        color: Appearance.m3colors.m3primaryContainer
        smoothing: Appearance.rounding.normal
        cornerFill: false

        Behavior on color {
            ColorAnimation {
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    // Subtle hover/press feedback on the closed button, on the same
    // blob group as the popover below - so they visually "connect".
    BlobRect {
        id: btnRect

        anchors.fill: parent
        anchors.margins: !btn.pressed && btn.containsMouse ? -Appearance.dashboard.padding.small : 0
        group: blobGroup
        radius: Appearance.rounding.normal

        Behavior on anchors.margins {
            NumberAnimation {
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    BlobRect {
        id: rect

        anchors.right: parent.right
        anchors.top: parent.top

        implicitWidth: parent.width
        implicitHeight: parent.height

        group: blobGroup
        radius: Appearance.rounding.normal
        deformScale: 0.00001

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                rect.anchors.rightMargin: root.width - Appearance.dashboard.spacing.small
                rect.anchors.topMargin: -Appearance.dashboard.padding.normal
                rect.implicitWidth: Math.max(layout.implicitWidth, placeholder.implicitWidth) + root.padding * 2
                rect.implicitHeight: Math.max(layout.implicitHeight, placeholder.implicitHeight) + root.padding * 2
                content.opacity: 1
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "rightMargin,topMargin,implicitWidth,implicitHeight,opacity"
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasized
            }
        }

        Item {
            id: content

            anchors.fill: parent
            clip: true
            opacity: 0
            state: (LyricsService.status === "loading") || !(LyricsService.status === "ok") ? "" : "hasLyrics"

            states: State {
                name: "hasLyrics"

                PropertyChanges {
                    layout.opacity: 1
                    placeholder.opacity: 0
                }
            }

            transitions: Transition {
                NumberAnimation {
                    properties: "opacity"
                    duration: Appearance.dashboard.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }

            ColumnLayout {
                id: layout

                anchors.centerIn: parent
                spacing: Appearance.dashboard.spacing.small
                opacity: 0

                StyledText {
                    text: (LyricsService.status !== "no_info") ? qsTr("Lyrics API: configured") : qsTr("Lyrics API: disabled")
                    color: Appearance.m3colors.m3secondary
                    animate: true
                }

                StyledText {
                    Layout.maximumWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaTabWidth / 3
                    text: qsTr("Now showing: %1 — %2").arg((MprisController.activePlayer?.trackArtist ?? "")).arg((MprisController.activePlayer?.trackTitle ?? ""))
                    color: Appearance.m3colors.m3secondary
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    animate: true
                }

                StyledText {
                    text: (LyricsService.status === "ok") ? qsTr("Synced (time-aligned)") : qsTr("Plain text (not time-aligned)")
                    color: Appearance.m3colors.m3secondary
                    animate: true
                }
            }

            Item {
                id: placeholder

                anchors.centerIn: parent
                implicitWidth: placeholderText.implicitWidth
                implicitHeight: placeholderText.implicitHeight

                StyledText {
                    id: placeholderText
                    text: (LyricsService.status === "loading") ? qsTr("Loading...") : qsTr("No lyrics found")
                    color: Appearance.m3colors.m3secondary
                    font.pointSize: Appearance.dashboard.fontSize.normal
                    animate: true
                }
            }
        }
    }

    MouseArea {
        id: btn

        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Appearance.dashboard.padding.small * 2
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.open = !root.open

        MaterialIcon {
            id: icon
            anchors.centerIn: parent
            text: "more_vert"
            color: Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.normal
        }
    }
}




pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.common.widgets.blobs
import qs.modules.common
import qs.services

Item {
    id: root

    implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaSectionWidth

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.dashboard.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: "lyrics"
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.larger
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Lyrics")
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            LyricsInfo {}
        }

        Item {
            id: listWrapper

            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property real fadeAmount: 0.12

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSpreadAtMin: 1
                maskThresholdMin: 0.5
                maskSource: fadeMask

                Rectangle {
                    id: fadeMask
                    width: listWrapper.width
                    height: listWrapper.height
                    layer.enabled: true
                    visible: false

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            color: Qt.alpha("black", 0)
                            position: 0
                        }
                        GradientStop {
                            color: Qt.alpha("black", 1)
                            position: listWrapper.fadeAmount
                        }
                        GradientStop {
                            color: Qt.alpha("black", 1)
                            position: 1 - listWrapper.fadeAmount
                        }
                        GradientStop {
                            color: Qt.alpha("black", 0)
                            position: 1
                        }
                    }
                }
            }

            Loader {
                anchors.centerIn: parent
                asynchronous: true
                active: (LyricsService.status === "loading")
                opacity: active ? 1 : 0

                sourceComponent: ColumnLayout {
                    spacing: Appearance.dashboard.spacing.normal

                    MaterialIcon {
                        id: spinner
                        Layout.alignment: Qt.AlignHCenter
                        text: "progress_activity"
                        color: Appearance.m3colors.m3primary
                        font.pointSize: Appearance.dashboard.fontSize.extraLarge

                        NumberAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: true
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Loading lyrics…")
                        color: Appearance.m3colors.m3secondary
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }
            }

            Loader {
                anchors.centerIn: parent
                asynchronous: true
                active: !(LyricsService.status === "loading") && !(LyricsService.status === "ok")
                opacity: active ? 1 : 0

                sourceComponent: ColumnLayout {
                    spacing: Appearance.dashboard.spacing.small

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "sentiment_dissatisfied"
                        color: Appearance.m3colors.m3tertiary
                        font.pointSize: Appearance.dashboard.fontSize.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: MprisController.activePlayer ? qsTr("No lyrics found") : qsTr("Nothing playing")
                        color: Appearance.m3colors.m3tertiary
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }
            }

            ListView {
                id: lyricsList

                anchors.fill: parent
                anchors.topMargin: parent.height * listWrapper.fadeAmount / 2
                anchors.bottomMargin: parent.height * listWrapper.fadeAmount / 2

                displayMarginBeginning: anchors.topMargin
                displayMarginEnd: anchors.bottomMargin

                clip: false
                spacing: Appearance.dashboard.spacing.small
                opacity: (LyricsService.status === "ok") ? 1 : 0
                visible: opacity > 0

                model: LyricsService.lyricsLines.map(l => l.text)

                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: Appearance.dashboard.durations.large
                highlightMoveVelocity: -1
                preferredHighlightBegin: (height - (currentItem?.implicitHeight ?? 0)) / 2
                preferredHighlightEnd: (height + (currentItem?.implicitHeight ?? 0)) / 2

                Component.onCompleted: {
                    currentIndex = Qt.binding(() => {
                        model;
                        return LyricsService.status === "ok" ? LyricsService.activeIndex : -1;
                    });
                    positionViewAtIndex(Math.max(0, currentIndex), ListView.Center);
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }

                delegate: StyledText {
                    id: lyricDelegate

                    required property string modelData
                    required property int index

                    anchors.left: parent ? parent.left : undefined
                    anchors.right: parent ? parent.right : undefined

                    text: modelData || "···"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter

                    color: ListView.isCurrentItem ? Appearance.m3colors.m3primary : mouseArea.containsMouse ? Appearance.m3colors.m3secondary : Appearance.m3colors.m3tertiary
                    font.pointSize: ListView.isCurrentItem ? Appearance.dashboard.fontSize.normal : Appearance.dashboard.fontSize.smaller

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (LyricsService.status === "ok") ? Qt.PointingHandCursor : undefined
                        onClicked: {
                            const p = MprisController.activePlayer;
                            if (p && (LyricsService.status === "ok"))
                                p.position = (LyricsService.lyricsLines[lyricDelegate.index]?.time ?? 0);
                        }
                    }
                }
            }
        }
    }

    // Small "more info" affordance rendered with Caelestia.Blobs -
    // expands into a soft blob showing where the lyrics came from.
    component LyricsInfo: Item {
        id: info

        property bool open

        implicitWidth: btn.implicitWidth
        implicitHeight: btn.implicitHeight

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
                when: info.open

                PropertyChanges {
                    rect.anchors.rightMargin: info.width - Appearance.dashboard.spacing.small
                    rect.anchors.topMargin: -Appearance.dashboard.padding.normal
                    rect.implicitWidth: content.implicitWidth + Appearance.dashboard.padding.large * 2
                    rect.implicitHeight: content.implicitHeight + Appearance.dashboard.padding.large * 2
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

            ColumnLayout {
                id: content

                anchors.centerIn: parent
                spacing: Appearance.dashboard.spacing.small
                opacity: 0

                StyledText {
                    text: (LyricsService.status !== "no_info") ? qsTr("Lyrics API: configured") : qsTr("Lyrics API: disabled")
                    color: Appearance.m3colors.m3secondary
                    animate: true
                }

                StyledText {
                    Layout.maximumWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaSectionWidth * 0.9
                    text: MprisController.activePlayer ? qsTr("Now looking up: %1 – %2").arg(MprisController.activePlayer.trackArtist).arg(MprisController.activePlayer.trackTitle) : qsTr("Nothing playing")
                    color: Appearance.m3colors.m3secondary
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    animate: true
                }

                StyledText {
                    text: (LyricsService.status === "ok") ? ((LyricsService.status === "ok") ? qsTr("Synced lyrics loaded") : qsTr("Plain lyrics loaded (unsynced)")) : qsTr("No lyrics loaded")
                    color: Appearance.m3colors.m3secondary
                    animate: true
                }
            }
        }

        MouseArea {
            id: btn

            anchors.centerIn: parent
            implicitWidth: icon.implicitHeight + Appearance.dashboard.padding.small * 2
            implicitHeight: implicitWidth

            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: info.open = !info.open

            MaterialIcon {
                id: icon
                anchors.centerIn: parent
                text: "more_vert"
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }
        }
    }
}




pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.common
import qs.services

Item {
    id: root

    readonly property real fadeAmount: 0.1
    property bool flag
    property list<string> lyricList: LyricsService.lyricsLines.map(l => l.text)

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSpreadAtMin: 1
        maskThresholdMin: 0.5
        maskSource: mask

        Rectangle {
            id: mask

            layer.enabled: true
            visible: false
            implicitWidth: root.width
            implicitHeight: root.height

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 0
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: 1 - root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 1
                }
            }
        }
    }

    state: {
        flag; // Force a re-evaluate; hasLyricsChanged doesn't always propagate to `state` on its own
        if ((LyricsService.status === "ok"))
            return "hasLyrics";
        if ((LyricsService.status === "loading"))
            return "loading";
        return "noLyrics";
    }

    states: [
        State {
            name: "loading"
            PropertyChanges {
                loadingIndicator.opacity: 1
                lyrics.opacity: 0
                noLyrics.opacity: 0
            }
        },
        State {
            name: "hasLyrics"
            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: 1
                noLyrics.opacity: 0
            }
        },
        State {
            name: "noLyrics"
            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: 0
                noLyrics.opacity: 1
            }
        }
    ]

    transitions: Transition {
        NumberAnimation {
            properties: "opacity"
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Connections {
        target: LyricsService
        function onStatusChanged() {
            root.flag = !root.flag;
        }
    }

    Loader {
        id: loadingIndicator

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Appearance.dashboard.spacing.large

            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: spinner.implicitSize + Appearance.dashboard.padding.normal * 2
                implicitHeight: implicitWidth
                color: Appearance.m3colors.m3primaryContainer
                radius: Appearance.rounding.full

                LoadingIndicator {
                    id: spinner

                    anchors.centerIn: parent
                    implicitSize: Math.round(Config.options.caelestiaDashboard.dashboard.sizes.mediaSectionWidth / 5)
                    containsIcon: true // Removes the pentagon, which isn't centered
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Loading lyrics...")
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.normal
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
        id: noLyrics

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "sentiment_sad"
                color: Appearance.m3colors.m3tertiary
                font.pointSize: Appearance.dashboard.fontSize.extraLarge
            }

            StyledText {
                text: qsTr("No lyrics found")
                color: Appearance.m3colors.m3tertiary
                font.pointSize: Appearance.dashboard.fontSize.normal
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
        id: lyrics

        anchors.fill: parent
        anchors.topMargin: parent.height * root.fadeAmount / 2
        anchors.bottomMargin: parent.height * root.fadeAmount / 2

        displayMarginBeginning: anchors.topMargin
        displayMarginEnd: anchors.bottomMargin

        model: root.lyricList
        Component.onCompleted: {
            currentIndex = Qt.binding(() => {
                model; // Force update when lyrics change
                return LyricsService.status === "ok" ? LyricsService.activeIndex : -1;
            });
            positionViewAtIndex(Math.max(0, currentIndex), ListView.Center);
        }
        onModelChanged: Qt.callLater(() => positionViewAtIndex(Math.max(0, currentIndex), ListView.Center))

        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: Appearance.dashboard.durations.large
        highlightMoveVelocity: -1
        preferredHighlightBegin: (height - (currentItem?.implicitHeight ?? 0)) / 2
        preferredHighlightEnd: (height + (currentItem?.implicitHeight ?? 0)) / 2

        spacing: Appearance.dashboard.spacing.small
        opacity: 0

        delegate: StyledText {
            id: lyric

            required property string modelData
            required property int index
            property real effectScale: ListView.isCurrentItem ? 1 : 0

            anchors.left: lyrics.contentItem.left
            anchors.right: lyrics.contentItem.right

            text: modelData || ". . ."
            horizontalAlignment: Text.AlignHCenter
            color: ListView.isCurrentItem ? Appearance.m3colors.m3primary : mouse.containsMouse ? Appearance.m3colors.m3secondary : Appearance.m3colors.m3tertiary
            font.pointSize: ListView.isCurrentItem ? Appearance.dashboard.fontSize.normal : Appearance.dashboard.fontSize.smaller
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            layer.enabled: effectScale > 0
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Appearance.m3colors.m3primary
                shadowOpacity: 0.5 * lyric.effectScale
                shadowBlur: 0.6 * lyric.effectScale
                blur: 0.4 * lyric.effectScale
            }

            Behavior on effectScale {
                NumberAnimation {
                    duration: Appearance.dashboard.durations.large
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                cursorShape: (LyricsService.status === "ok") ? Qt.PointingHandCursor : undefined
                hoverEnabled: true
                onClicked: {
                    const p = MprisController.activePlayer;
                    if (p && (LyricsService.status === "ok"))
                        p.position = (LyricsService.lyricsLines[lyric.index]?.time ?? 0);
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.dashboard.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    Behavior on lyricList {
        SequentialAnimation {
            NumberAnimation {
                target: lyrics
                property: "opacity"
                to: 0
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
            PropertyAction {}
            NumberAnimation {
                target: lyrics
                property: "opacity"
                to: 1
                duration: Appearance.dashboard.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }
}




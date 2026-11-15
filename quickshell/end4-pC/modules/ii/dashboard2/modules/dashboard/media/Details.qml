pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import qs.modules.common.widgets as CommonWidgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.modules.common
import qs.services

ColumnLayout {
    id: root

    property real playerProgress: {
        const active = MprisController.activePlayer;
        return active?.length ? active.position / active.length : 0;
    }

    readonly property bool hasUnknownLength: (MprisController.activePlayer?.length ?? 0) > 2147483647

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    spacing: Appearance.dashboard.spacing.small

    Behavior on playerProgress {
        NumberAnimation {
            duration: Appearance.dashboard.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Timer {
        running: MprisController.activePlayer?.isPlaying ?? false
        interval: Config.options.caelestiaDashboard.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: MprisController.activePlayer?.positionChanged()
    }

    StyledText {
        Layout.fillWidth: true

        animate: true
        text: MprisController.activePlayer?.trackTitle || qsTr("No media")
        color: Appearance.m3colors.m3primary
        font.pointSize: Appearance.dashboard.fontSize.large
        elide: Text.ElideRight
    }

    StyledText {
        Layout.fillWidth: true

        animate: true
        text: MprisController.activePlayer?.trackArtist || qsTr("Unknown artist")
        color: Appearance.m3colors.m3secondary
        font.pointSize: Appearance.dashboard.fontSize.normal
        elide: Text.ElideRight
    }

    StyledText {
        Layout.fillWidth: true

        animate: true
        text: MprisController.activePlayer?.trackAlbum || qsTr("Unknown album")
        color: Appearance.m3colors.m3tertiary
        font.pointSize: Appearance.dashboard.fontSize.smaller
        elide: Text.ElideRight
    }

    RowLayout {
        Layout.topMargin: Appearance.dashboard.spacing.large
        Layout.fillWidth: true
        spacing: Appearance.dashboard.spacing.small

        // Both time labels reserve the same, worst-case width (all digits
        // zeroed out) so the slider next to them doesn't jitter as the
        // position ticks over from e.g. 0:09 to 0:10.
        TextMetrics {
            id: timeMetrics

            text: MprisController.activePlayer ? root.lengthStr(Math.max(MprisController.activePlayer.position, root.hasUnknownLength ? 0 : MprisController.activePlayer.length)).replace(/[1-9]/g, "0") : "0:00"
            font.family: Appearance.font.family.main
            font.pointSize: Appearance.dashboard.fontSize.small
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: root.lengthStr(MprisController.activePlayer?.position ?? -1)
            color: Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.small
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

            readonly property bool canSeek: (MprisController.activePlayer?.canSeek ?? false) && !root.hasUnknownLength

            Loader {
                id: sliderLoader
                anchors.fill: parent
                active: parent.canSeek
                sourceComponent: CommonWidgets.StyledSlider {
                    configuration: CommonWidgets.StyledSlider.Configuration.Wavy
                    highlightColor: Appearance.m3colors.m3primary
                    trackColor: Appearance.m3colors.m3primaryContainer
                    handleColor: Appearance.m3colors.m3primary
                    value: root.playerProgress

                    onMoved: {
                        const active = MprisController.activePlayer;
                        if (active?.canSeek && active?.positionSupported)
                            active.position = value * active.length;
                    }
                }
            }

            Loader {
                id: progressBarLoader
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                }
                active: !parent.canSeek
                sourceComponent: CommonWidgets.StyledProgressBar {
                    wavy: MprisController.activePlayer?.isPlaying ?? false
                    highlightColor: Appearance.m3colors.m3primary
                    trackColor: Appearance.m3colors.m3primaryContainer
                    value: root.playerProgress
                }
            }
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: root.hasUnknownLength ? "--:--" : root.lengthStr(MprisController.activePlayer?.length ?? -1)
            color: Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.small
            horizontalAlignment: Text.AlignHCenter
        }
    }

    RowLayout {
        id: controls

        Layout.topMargin: Appearance.dashboard.spacing.large
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.dashboard.spacing.small

        Control {
            icon: "shuffle"
            canUse: MprisController.activePlayer?.shuffleSupported ?? false
            toggled: MprisController.activePlayer?.shuffle ?? false
            fontSize: Appearance.dashboard.fontSize.larger

            function onClicked(): void {
                MprisController.activePlayer.shuffle = !MprisController.activePlayer?.shuffle;
            }
        }

        Control {
            icon: "skip_previous"
            canUse: MprisController.activePlayer?.canGoPrevious ?? false

            function onClicked(): void {
                MprisController.activePlayer?.previous();
            }
        }

        Control {
            icon: MprisController.activePlayer?.isPlaying ? "pause" : "play_arrow"
            canUse: MprisController.activePlayer?.canTogglePlaying ?? false
            primary: true
            fontSize: Appearance.dashboard.fontSize.extraLarge

            function onClicked(): void {
                MprisController.activePlayer?.togglePlaying();
            }
        }

        Control {
            icon: "skip_next"
            canUse: MprisController.activePlayer?.canGoNext ?? false

            function onClicked(): void {
                MprisController.activePlayer?.next();
            }
        }

        Control {
            icon: MprisController.activePlayer?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            canUse: MprisController.activePlayer?.loopSupported ?? false
            toggled: MprisController.activePlayer?.loopState === MprisLoopState.Track || MprisController.activePlayer?.loopState === MprisLoopState.Playlist
            fontSize: Appearance.dashboard.fontSize.larger

            function onClicked(): void {
                const state = MprisController.activePlayer.loopState;
                if (state === MprisLoopState.None)
                    MprisController.activePlayer.loopState = MprisLoopState.Track;
                else if (state === MprisLoopState.Track)
                    MprisController.activePlayer.loopState = MprisLoopState.Playlist;
                else
                    MprisController.activePlayer.loopState = MprisLoopState.None;
            }
        }
    }

    // Transport button, drawn on a small morphing Material shape
    // instead of a plain circle - swaps between two "squircle" shapes
    // depending on pressed state for a bit of squash-and-stretch.
    component Control: Item {
        id: control

        required property string icon
        required property bool canUse
        property bool toggled
        property bool primary
        property int fontSize: Appearance.dashboard.fontSize.large
        function onClicked(): void {
        }

        readonly property real baseSize: primary ? 1.3 : 1

        implicitWidth: 56 * baseSize
        implicitHeight: implicitWidth

        // Everything visual lives inside `squash` and gets scaled as a
        // whole on press. bg's own implicitSize stays fixed so its path
        // geometry is only ever computed once instead of every animation
        // frame - animating implicitSize directly made MaterialShape
        // regenerate (and subtly re-tessellate) its curve each frame,
        // which is what caused the jitter on the bigger primary button.
        Item {
            id: squash

            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            scale: mouse.pressed ? 0.88 : 1
            transformOrigin: Item.Center

            Behavior on scale {
                animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
            }

            MaterialShape {
                id: bg

                anchors.fill: parent
                shape: control.primary || control.toggled ? MaterialShape.Cookie4Sided : MaterialShape.Circle
                color: (control.primary || control.toggled) && control.canUse ? Appearance.m3colors.m3primary : Appearance.m3colors.m3primaryContainer
                opacity: control.canUse ? 1 : 0.4

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
            }

            StyledRect {
                anchors.fill: bg
                radius: Appearance.rounding.full
                color: Appearance.m3colors.m3secondary
                opacity: !control.canUse ? 0 : mouse.pressed ? 0.1 : mouse.hovered ? 0.08 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.small
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }
            }

            MaterialIcon {
                anchors.centerIn: bg

                animate: true
                fill: control.primary || control.toggled ? 1 : 0
                text: control.icon
                color: control.canUse ? (control.primary || control.toggled) ? Appearance.m3colors.m3surface : Appearance.m3colors.m3secondary : Appearance.m3colors.m3tertiary
                font.pointSize: control.fontSize
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: control.canUse ? Qt.PointingHandCursor : undefined
            hoverEnabled: true
            onClicked: control.canUse && control.onClicked()
        }
    }
}

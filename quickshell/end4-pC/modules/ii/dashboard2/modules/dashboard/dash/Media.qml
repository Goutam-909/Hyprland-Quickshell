pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes
import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import qs.modules.common
import qs.services

Item {
    id: root

    property real playerProgress: {
        const active = MprisController.activePlayer;
        return active?.length ? active.position / active.length : 0;
    }

    anchors.bottom: parent.bottom
    anchors.top: parent.top
    anchors.topMargin: Appearance.dashboard.padding.large * 3
    implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaWidth

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

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Appearance.m3colors.m3primary
            strokeWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaProgressThickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + Config.options.caelestiaDashboard.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.dashboard.spacing.small
                radiusY: (cover.height + Config.options.caelestiaDashboard.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.dashboard.spacing.small
                startAngle: -90 - Config.options.caelestiaDashboard.dashboard.sizes.mediaProgressSweep / 2
                sweepAngle: Config.options.caelestiaDashboard.dashboard.sizes.mediaProgressSweep * root.playerProgress
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.dashboard.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.dashboard.padding.large + Config.options.caelestiaDashboard.dashboard.sizes.mediaProgressThickness + Appearance.dashboard.spacing.small

        implicitHeight: width
        color: Appearance.m3colors.m3primaryContainer
        radius: Appearance.rounding.full

        MaterialIcon {
            anchors.centerIn: parent

            text: "art_track"
            color: Appearance.m3colors.m3secondary
            font.pointSize: (parent.width * 0.4) || 1
        }

        Image {
            anchors.fill: parent

            source: MprisController.activePlayer?.trackArtUrl ?? ""
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    StyledText {
        id: title

        anchors.top: cover.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.dashboard.spacing.normal

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (MprisController.activePlayer?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
        color: Appearance.m3colors.m3primary
        font.pointSize: Appearance.dashboard.fontSize.normal

        width: root.implicitWidth - Appearance.dashboard.padding.large * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: album

        anchors.top: title.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.dashboard.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (MprisController.activePlayer?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
        color: Appearance.m3colors.m3tertiary
        font.pointSize: Appearance.dashboard.fontSize.small

        width: root.implicitWidth - Appearance.dashboard.padding.large * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: artist

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.dashboard.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (MprisController.activePlayer?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
        color: Appearance.m3colors.m3secondary

        width: root.implicitWidth - Appearance.dashboard.padding.large * 2
        elide: Text.ElideRight
    }

    Row {
        id: controls

        anchors.top: artist.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.dashboard.spacing.smaller

        spacing: Appearance.dashboard.spacing.small

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
    }

    component Control: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        function onClicked(): void {
        }

        implicitWidth: Math.max(icon.implicitHeight, icon.implicitHeight) + Appearance.dashboard.padding.small
        implicitHeight: implicitWidth

        StateLayer {
            disabled: !control.canUse
            radius: Appearance.rounding.full

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: font.pointSize * 0.05

            animate: true
            text: control.icon
            color: control.canUse ? Appearance.m3colors.m3secondary : Appearance.m3colors.m3tertiary
            font.pointSize: Appearance.dashboard.fontSize.large
        }
    }
}

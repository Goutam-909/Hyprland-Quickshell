pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.ii.dashboard2.widgets
import qs.modules.common
import qs.modules.common.widgets as CommonWidgets

Item {
    id: root

    required property string modelData
    required property int index
    required property Item carousel

    readonly property string path: root.modelData
    readonly property string fileName: root.path.split("/").pop()
    readonly property bool isCurrentWallpaper: root.path === Config.options.background.wallpaperPath

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Component.onCompleted: {
        // 0.8, matching Caelestia exactly (was 0.82)
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Appearance.dashboard.padding.normal * 2
    implicitHeight: image.height + label.implicitHeight + Appearance.dashboard.spacing.small + Appearance.dashboard.padding.large + Appearance.dashboard.padding.normal

    StateLayer {
        radius: Appearance.rounding.large

        function onClicked(): void {
            root.carousel.applyPath(root.path);
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Appearance.dashboard.padding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.large

        implicitWidth: root.carousel.thumbWidth
        implicitHeight: root.carousel.thumbHeight

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Appearance.m3colors.m3outline
            font.pointSize: Appearance.dashboard.fontSize.extraLarge
        }

        Image {
            anchors.fill: parent
            source: root.path.length > 0 ? `file://${root.path}` : ""
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: root.carousel.thumbWidth
            sourceSize.height: root.carousel.thumbHeight
            // Skip bilinear filtering while the carousel is actively being
            // dragged - matches Caelestia, crisper/cheaper during motion,
            // smooths back in the instant it settles.
            smooth: !root.PathView.view.moving
        }

        StyledRect {
            anchors.fill: parent
            radius: Appearance.rounding.large
            color: "transparent"
            border.width: 2
            border.color: Appearance.m3colors.m3primary
            opacity: root.isCurrentWallpaper ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.dashboard.durations.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }
        }
    }

    // Qualified via CommonWidgets. so it doesn't drag common/widgets'
    // StyledText/StateLayer/etc. into this file's scope and shadow the
    // dashboard2 versions used everywhere else here - that collision was
    // the actual source of the pixelSize/pointSize warnings.
    CommonWidgets.StyledRectangularShadow {
        target: image
        z: -1
        opacity: root.PathView.isCurrentItem ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.dashboard.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Appearance.dashboard.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Appearance.dashboard.padding.normal * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.fileName
        color: Appearance.m3colors.m3onSurface
        font.pointSize: Appearance.dashboard.fontSize.small
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
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

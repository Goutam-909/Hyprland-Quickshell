pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.ii.dashboard2.widgets
import qs.modules.common

// Delegate for WallpaperCarousel.qml. Styled after caelestia's launcher
// WallpaperItem.qml - scale/fade based on PathView.isCurrentItem/onPath,
// a thumbnail with a filename label underneath. Loads the image directly
// (see the Image block below) rather than through this project's
// CachingImage/Thumbnailer pipeline, which batch-generates thumbnails in
// the background on its own schedule - too unpredictable for something
// that needs to show up the instant you open the carousel.
Item {
    id: root

    // Declared as modelData/index (not e.g. "path") on purpose: with
    // `pragma ComponentBehavior: Bound`, PathView auto-populates required
    // properties on the delegate's root object that match the model's
    // role names. Our model (WallpaperCarousel.entries) is a plain JS
    // array of path strings, so its roles are just "modelData" (the
    // string itself) and "index" (position) - matching these names here
    // lets PathView wire them in directly with no indirection needed in
    // WallpaperCarousel.qml's delegate.
    required property string modelData
    required property int index
    // Back-reference to WallpaperCarousel.qml, passed down by its
    // delegate binding - gives us applyPath()/thumbWidth/thumbHeight
    // without needing a signal that bubbles all the way up through
    // Content.qml.
    required property Item carousel

    readonly property string path: root.modelData
    readonly property string fileName: root.path.split("/").pop()
    readonly property bool isCurrentWallpaper: root.path === Config.options.background.wallpaperPath

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.82 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Appearance.dashboard.padding.normal * 2
    implicitHeight: image.height + label.implicitHeight + Appearance.dashboard.spacing.small + Appearance.dashboard.padding.large + Appearance.dashboard.padding.normal

    StateLayer {
        radius: Appearance.rounding.large

        // StateLayer declares onClicked as a plain function (see
        // StateLayer.qml), not a signal - so it's overridden by
        // redefining the function here, not with onClicked: ... syntax.
        // Clicking any visible thumbnail (not just the centred one) jumps
        // straight to it and applies it immediately - same as caelestia.
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

        // Loaded directly rather than through CachingImage/Thumbnailer:
        // that pipeline batch-generates thumbnails in the background and
        // this delegate's actual size isn't resolved yet at the moment a
        // CachingImage would ask for one (anchors.fill resolves after
        // this binding runs), which was producing bogus "0x0" thumbnail
        // requests and images that never appeared. sourceSize below asks
        // Qt to decode-and-downscale directly instead, so there's no
        // external cache/generation step to depend on.
        Image {
            anchors.fill: parent
            source: root.path.length > 0 ? `file://${root.path}` : ""
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: root.carousel.thumbWidth
            sourceSize.height: root.carousel.thumbHeight
        }

        // Thin ring around whatever's currently actually applied, so it's
        // still identifiable even when it's not the centred item.
        StyledRect {
            anchors.fill: parent
            // NOT parent.radius: under `pragma ComponentBehavior: Bound`,
            // `parent`'s static type is the generic Item (no radius
            // property), so that binding silently evaluates to undefined
            // at runtime instead of erroring at compile time. Reference
            // the same token `image` was given directly instead.
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

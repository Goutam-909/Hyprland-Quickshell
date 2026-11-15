pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import Quickshell
import QtQuick
import qs.modules.common
import qs.services

// Split out of ../launcher/Content.qml's old wallpaperMode branch so the
// carousel's sizing/animation/keyboard-handling is fully self-contained
// and doesn't have to be threaded through the launcher's
// clipboardMode/wallpaperMode plumbing anymore.
//
// The search field is a real filename filter (bound to
// WallpaperCarousel.filterText) as well as a key-handling surface: type
// to narrow the carousel down by filename, Enter to apply, Esc to close.
// ← → browse the carousel only while the box is empty; once you've typed
// something, ← → fall through to normal text-cursor movement instead.
Item {
    id: root

    required property PersistentProperties visibilities

    readonly property int padding: Appearance.dashboard.padding.large

    implicitWidth: carousel.panelWidth + padding * 2
    implicitHeight: search.implicitHeight + carousel.height + padding * 2 + search.anchors.bottomMargin

    Item {
        id: listWrapper

        clip: true
        implicitWidth: carousel.panelWidth
        implicitHeight: carousel.height

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        WallpaperCarousel {
            id: carousel

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            visibilities: root.visibilities
            filterText: search.text
        }

        // Empty state overlaid on top of the carousel area, same as the
        // launcher's - not inside the carousel itself so it isn't at the
        // mercy of PathView's delegate lifecycle when there are 0 items.
        Column {
            visible: opacity > 0
            opacity: carousel.count === 0 ? 1 : 0
            scale: carousel.count === 0 ? 1 : 0.5

            spacing: Appearance.dashboard.spacing.small
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wallpaper"
                color: Appearance.m3colors.m3onSurfaceVariant
                font.pointSize: Appearance.dashboard.fontSize.extraLarge
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: search.text.length > 0 ? qsTr("No wallpapers match \"%1\"").arg(search.text) : qsTr("No wallpapers found")
                color: Appearance.m3colors.m3onSurfaceVariant
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: search.text.length > 0 ? qsTr("Try a different name") : qsTr("Add images to ~/Pictures/Wallpapers")
                color: Appearance.m3colors.m3onSurfaceVariant
                font.pointSize: Appearance.dashboard.fontSize.small
            }

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
    }

    StyledTextField {
        id: search

        objectName: "wallpaperSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding

        topPadding: Appearance.dashboard.padding.larger
        bottomPadding: Appearance.dashboard.padding.larger
        leftPadding: Appearance.dashboard.padding.large
        rightPadding: Appearance.dashboard.padding.large

        font.pointSize: Appearance.dashboard.fontSize.larger

        placeholderText: qsTr("Search by name, ← → to browse, Enter to set")

        background: StyledRect {
            radius: Appearance.rounding.large
            color: Appearance.m3colors.m3surfaceContainerHigh
        }

        onAccepted: carousel.applyCurrent()

        // Only steal ← → for carousel browsing while the box is empty -
        // once there's text in it, arrows fall through (event.accepted =
        // false) so they move the cursor between letters like a normal
        // text field instead.
        Keys.onLeftPressed: event => {
            if (search.text.length === 0) {
                carousel.decrementCurrentIndex();
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }
        Keys.onRightPressed: event => {
            if (search.text.length === 0) {
                carousel.incrementCurrentIndex();
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }

        Keys.onEscapePressed: root.visibilities.wallpaper = false

        Component.onCompleted: forceActiveFocus()

        // Clear any leftover filter text + refocus every time this panel
        // is opened, so it never opens up still filtered from last time.
        Connections {
            function onWallpaperChanged(): void {
                if (root.visibilities.wallpaper) {
                    search.text = "";
                    search.forceActiveFocus();
                }
            }

            target: root.visibilities
        }
    }
}

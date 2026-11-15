pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import Quickshell
import QtQuick
import qs.modules.common
import qs.services

// Layout mirrors caelestia's launcher Content.qml: the search field is
// anchored to the bottom and the result list sits directly above it. The
// panel itself is bottom-docked (see Wrapper.qml), so visually this reads
// as "search bar stays put, results area sits above it" - same as
// caelestia.
//
// Two lists live side by side (AppList / ClipboardList), only one visible
// at a time depending on clipboardMode. currentList is a thin alias that
// points at whichever one is active, so the rest of this file (search
// field, empty state, keyboard nav) doesn't need to care which mode it's
// in.
//
// The wallpaper carousel used to be a third mode here (wallpaperMode) but
// now lives in its own independent panel - see ../wallpaper/Content.qml
// and ../wallpaper/Wrapper.qml - so this file, and Wrapper.qml alongside
// it, no longer know anything about visibilities.wallpaper.
Item {
    id: root

    required property PersistentProperties visibilities

    // '>' switches into action mode. AppList.actions holds what's
    // listed there ("Clipboard" and "Wallpaper").
    readonly property string actionPrefix: ">"

    // Live/requested mode - flips the instant visibilities.clipboard
    // changes.
    readonly property bool requestedClipboardMode: root.visibilities.clipboard

    // Displayed/frozen mode - only re-synced while the drawer is
    // actually open (launcher or clipboard visible). When everything
    // closes at once, this deliberately does NOT flip back to appList
    // mid-close, so currentList keeps pointing at whatever it was
    // already showing while the outer Wrapper's height animates down -
    // no mid-shrink list swap, no squish.
    property bool clipboardMode: requestedClipboardMode

    function syncMode(): void {
        if (root.visibilities.launcher || root.visibilities.clipboard) {
            root.clipboardMode = root.requestedClipboardMode;
        }
    }

    readonly property int padding: Appearance.dashboard.padding.large // ← outer padding, tune here

    readonly property Item currentList: clipboardMode ? clipList : appList

    implicitWidth: currentList.panelWidth + padding * 2
    implicitHeight: search.implicitHeight + currentList.height + padding * 2 + search.anchors.bottomMargin

    Connections {
        function onLauncherChanged(): void {
            root.syncMode();
        }

        function onClipboardChanged(): void {
            root.syncMode();
        }

        target: root.visibilities
    }

    Item {
        id: listWrapper

        clip: true
        implicitWidth: root.currentList.panelWidth
        implicitHeight: root.currentList.height

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        AppList {
            id: appList

            visible: !root.clipboardMode
            enabled: visible

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            visibilities: root.visibilities
            search: search
            actionPrefix: root.actionPrefix
        }

        ClipboardList {
            id: clipList

            visible: root.clipboardMode
            enabled: visible

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            visibilities: root.visibilities
            search: search
        }

        // Empty state overlaid on top of the list area (not inside any of
        // the lists themselves, so it isn't at the mercy of Flickable's
        // contentItem reparenting/centering when there are 0 delegates).
        Column {
            visible: opacity > 0
            opacity: root.currentList.count === 0 ? 1 : 0
            scale: root.currentList.count === 0 ? 1 : 0.5

            spacing: Appearance.dashboard.spacing.small
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.clipboardMode ? "content_paste_off" : (appList.actionMode ? "bolt" : "manage_search")
                color: Appearance.m3colors.m3onSurfaceVariant
                font.pointSize: Appearance.dashboard.fontSize.extraLarge
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.clipboardMode ? qsTr("No clipboard history") : (appList.actionMode ? qsTr("No actions yet") : qsTr("No results"))
                color: Appearance.m3colors.m3onSurfaceVariant
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.clipboardMode ? qsTr("Copy something to see it here") : (appList.actionMode ? qsTr("Action modules are coming soon") : qsTr("Try searching for something else"))
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

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding

        topPadding: Appearance.dashboard.padding.larger
        bottomPadding: Appearance.dashboard.padding.larger
        leftPadding: Appearance.dashboard.padding.large
        rightPadding: Appearance.dashboard.padding.large

        font.pointSize: Appearance.dashboard.fontSize.larger // ← search text size, tune here

        placeholderText: root.clipboardMode ? qsTr("Search clipboard history") : qsTr("Search apps, or type \"%1\" for actions").arg(root.actionPrefix)

        background: StyledRect {
            radius: Appearance.rounding.large
            color: Appearance.m3colors.m3surfaceContainerHigh
        }

        onAccepted: {
            const currentItem = root.currentList.currentItem;
            if (root.clipboardMode) {
                if (currentItem?.modelData) {
                    Cliphist.paste(currentItem.modelData);
                    root.visibilities.clipboard = false;
                }
            } else if (currentItem?.modelData) {
                currentItem.modelData.execute();
                root.visibilities.launcher = false;
            }
        }

        Keys.onUpPressed: root.currentList.decrementCurrentIndex()
        Keys.onDownPressed: root.currentList.incrementCurrentIndex()

        Keys.onEscapePressed: {
            root.visibilities.launcher = false;
            root.visibilities.clipboard = false;
        }

        Component.onCompleted: forceActiveFocus()

        // Clear + refocus the search box whenever any mode is *entered*
        // (not just when both close), so switching straight from
        // launcher -> clipboard (e.g. via the ">" action) never leaves
        // stale search text (like ">") behind in the other mode.
        Connections {
            function onLauncherChanged(): void {
                if (root.visibilities.launcher) {
                    search.text = "";
                    search.forceActiveFocus();
                } else if (!root.visibilities.clipboard) {
                    search.text = "";
                }
            }

            function onClipboardChanged(): void {
                if (root.visibilities.clipboard) {
                    search.text = "";
                    search.forceActiveFocus();
                } else if (!root.visibilities.launcher) {
                    search.text = "";
                }
            }

            target: root.visibilities
        }
    }
}

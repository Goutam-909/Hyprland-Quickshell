pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.modules.launcher.items
import Quickshell
import QtQuick
import QtQuick.Controls
import qs.modules.common
// Cliphist is the root-level clipboard-history singleton (services/Cliphist.qml).
import qs.services

ListView {
    id: root

    required property PersistentProperties visibilities
    required property StyledTextField search

    // ── Tune size here ──────────────────────────────────────────────
    // Width of the launcher panel (list + search bar match this). Keep
    // in sync with AppList.panelWidth so the panel doesn't jump width
    // when switching modes.
    readonly property int panelWidth: 560
    // How many rows are visible before the list scrolls.
    readonly property int maxShown: 8
    // Rows reserved for the "no results" empty state.
    readonly property int emptyRows: 3
    // Height of a single text-clip row.
    readonly property int itemHeight: Appearance.dashboard.fontSize.large * 3.4
    // Height of a single image-clip row - taller so thumbnails are
    // actually visible instead of squashed to text-row size.
    readonly property int imageItemHeight: itemHeight * 3
    // ─────────────────────────────────────────────────────────────────

    readonly property bool searching: search.text.length > 0

    readonly property int visibleRows: !searching ? maxShown : (count > 0 ? Math.min(count, maxShown) : emptyRows)

    // Same fixed formula as AppList - the panel always allocates exactly
    // the same height as the app drawer for the same row count,
    // regardless of whether the visible rows happen to be images. If an
    // image row ends up taller than its allotted slot, the list just
    // scrolls internally (cacheBuffer/clip below) instead of the whole
    // panel growing to fit it.
    readonly property int targetHeight: visibleRows * (itemHeight + spacing) - spacing

    function resultsForText(text: string): var {
        return Cliphist.fuzzyQuery(text);
    }

    function refresh(): void {
        resultModel.values = resultsForText(search.text);
        currentIndex = count > 0 ? 0 : -1;
    }

    model: ScriptModel {
        id: resultModel
    }

    Connections {
        function onTextChanged(): void {
            root.refresh();
        }

        target: root.search
    }

    // Keep the list in sync whenever the underlying clipboard history
    // changes (new copy, delete, wipe, etc.) while the panel is open.
    Connections {
        function onEntriesChanged(): void {
            root.refresh();
        }

        target: Cliphist
    }

    // Force a fresh read from cliphist every time the panel is opened,
    // in case something changed the clipboard while it was closed.
    Connections {
        function onClipboardChanged(): void {
            if (root.visibilities.clipboard) {
                Cliphist.refresh();
                root.positionViewAtBeginning();
                root.refresh();
            }
        }

        target: root.visibilities
    }

    Component.onCompleted: refresh()

    clip: true
    spacing: Appearance.dashboard.spacing.small
    implicitWidth: panelWidth
    height: targetHeight
    cacheBuffer: itemHeight * 4
    boundsBehavior: Flickable.StopAtBounds

    Behavior on height {
        NumberAnimation {
            duration: Appearance.dashboard.durations.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange
    highlightFollowsCurrentItem: false

    highlight: StyledRect {
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            NumberAnimation {
                duration: Appearance.dashboard.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    delegate: ClipItem {
        visibilities: root.visibilities
        rowWidth: root.width
        itemHeight: root.itemHeight
        imageItemHeight: root.imageItemHeight
    }

    add: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.dashboard.durations.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standardDecel
        }
    }

    remove: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Appearance.dashboard.durations.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standardAccel
        }
    }

    move: Transition {
        NumberAnimation {
            property: "y"
            duration: Appearance.dashboard.durations.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    ScrollBar.vertical: StyledScrollBar {}
}

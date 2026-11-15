pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.modules.launcher.items
import Quickshell
import QtQuick
import QtQuick.Controls
import qs.modules.common
// AppSearch is the root-level app-search singleton (services/AppSearch.qml).
import qs.services

ListView {
    id: root

    required property PersistentProperties visibilities
    required property StyledTextField search
    required property string actionPrefix

    readonly property bool actionMode: search.text.startsWith(actionPrefix)

    // ── Actions ──────────────────────────────────────────────────────
    // Shown when the search box starts with actionPrefix (">"). Each
    // entry needs id/name/description/icon (a Material Symbol name) and
    // an execute() that does whatever the action should do. Add more
    // actions here as you build them out.
    readonly property var actions: [
        {
            id: "clipboard",
            name: qsTr("Clipboard"),
            description: qsTr("View and paste from clipboard history"),
            icon: "content_paste",
            execute: () => {
                root.visibilities.clipboard = true;
                root.visibilities.wallpaper = false;
                root.visibilities.launcher = false;
            }
        },
        {
            id: "wallpaper",
            name: qsTr("Wallpaper"),
            description: qsTr("Browse and apply wallpapers"),
            icon: "wallpaper",
            execute: () => {
                root.visibilities.wallpaper = true;
                root.visibilities.clipboard = false;
                root.visibilities.launcher = false;
            }
        }
    ]
    // ─────────────────────────────────────────────────────────────────

    // ── Tune size here ──────────────────────────────────────────────
    // Width of the launcher panel (list + search bar match this).
    readonly property int panelWidth: 560
    // How many rows are visible before the list scrolls.
    readonly property int maxShown: 8
    // Rows reserved for the "no results" empty state, so the icon/text
    // don't get cramped when there are 0 matches.
    readonly property int emptyRows: 3
    // Height of a single row (shared by app rows and action rows).
    readonly property int itemHeight: Appearance.dashboard.fontSize.large * 3.4
    // ─────────────────────────────────────────────────────────────────

    // Only react to the result count once the user has actually typed
    // something. With an empty search, height stays at the fixed
    // maxShown-rows size, exactly like the old behavior - which is what
    // keeps app-discovery loading right after the shell starts from ever
    // touching the panel's height, since that only happens while search
    // is empty. Once you type (or enter action mode with ">"), AppSearch
    // has long since finished loading, so there's nothing left to jitter.
    readonly property bool searching: search.text.length > 0

    readonly property int visibleRows: !searching ? maxShown : (count > 0 ? Math.min(count, maxShown) : emptyRows)

    readonly property int targetHeight: visibleRows * (itemHeight + spacing) - spacing

    function resultsForText(text: string): var {
        if (actionMode) {
            const query = text.slice(root.actionPrefix.length).trim().toLowerCase();
            if (query === "")
                return root.actions;
            return root.actions.filter(a => a.name.toLowerCase().includes(query) || (a.description ?? "").toLowerCase().includes(query));
        }
        return AppSearch.fuzzyQuery(text);
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

    Connections {
        function onLauncherChanged(): void {
            if (root.visibilities.launcher) {
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

    // Swaps delegate type based on mode - AppItem expects a DesktopEntry
    // shape (icon/name/comment/execute()), ActionItem expects the plain
    // action-object shape above (icon/name/description/execute()).
    // Reassigning `delegate` when actionMode flips causes the ListView
    // to rebuild its delegates from the new Component, which is cheap
    // given how few rows are ever visible here.
    delegate: root.actionMode ? actionDelegate : appDelegate

    Component {
        id: appDelegate

        AppItem {
            visibilities: root.visibilities
            rowWidth: root.width
        }
    }

    Component {
        id: actionDelegate

        ActionItem {
            visibilities: root.visibilities
            rowWidth: root.width
        }
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

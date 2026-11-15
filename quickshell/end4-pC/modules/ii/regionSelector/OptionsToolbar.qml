pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Options toolbar
Toolbar {
    id: root

    // Use a synchronizer on these
    property var action
    property var selectionMode
    // Signals
    signal dismiss()

    ToolbarTabBar {
        id: tabBar
        tabButtonList: [
            {"icon": "activity_zone", "name": Translation.tr("Rect")},
            {"icon": "gesture", "name": Translation.tr("Circle")}
        ]

        // One-directional sync: currentIndex is never given a live binding
        // to root.selectionMode, so there is no cycle for QML's binding
        // loop detector to trip on. Instead we set it imperatively on init
        // and whenever root.selectionMode changes from the outside.
        function indexForMode(mode) {
            return mode === RegionSelection.SelectionMode.RectCorners ? 0 : 1;
        }

        Component.onCompleted: currentIndex = tabBar.indexForMode(root.selectionMode)

        Connections {
            target: root
            function onSelectionModeChanged() {
                const idx = tabBar.indexForMode(root.selectionMode);
                if (tabBar.currentIndex !== idx)
                    tabBar.currentIndex = idx;
            }
        }

        // User clicks flow back out imperatively too, so neither side is a
        // declarative binding that the other side writes into.
        onCurrentIndexChanged: {
            const newMode = currentIndex === 0 ? RegionSelection.SelectionMode.RectCorners : RegionSelection.SelectionMode.Circle;
            if (root.selectionMode !== newMode)
                root.selectionMode = newMode;
        }
    }
}

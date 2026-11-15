import qs.modules.ii.dashboard2.services
//import qs.modules.ii.dashboard2.modules.osd as Osd
import Quickshell
import QtQuick
import qs.modules.common

MouseArea {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property Panels panels

    property bool osdHovered
    property point dragStart

    // Widened well beyond the visual panel's own width - it was only
    // `rounding` (a few px) either side before, giving a narrow strip
    // centered under the panel instead of a wide hover zone.
    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const margin = Config.options.caelestiaDashboard.border.hoverWidthMargin ?? 300;
        return x >= panel.x - margin && x <= panel.x + panel.width + margin;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        const panelY = Config.options.caelestiaDashboard.border.thickness + panel.y;
        return x < panel.width + Config.options.caelestiaDashboard.border.thickness
        && y >= panelY - Config.options.caelestiaDashboard.border.rounding
        && y <= panelY + panel.height + Config.options.caelestiaDashboard.border.rounding;
    }

    function inBottomPanel(panel: Item, x: real, y: real): bool {
        const revealed = Math.max(Config.options.caelestiaDashboard.border.minThickness ?? 4, panel.height);
        return y > root.height - Config.options.caelestiaDashboard.border.thickness - revealed
        && withinPanelWidth(panel, x, y);
    }

    anchors.fill: parent
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onContainsMouseChanged: {
        if (!containsMouse) {
            //visibilities.osd = false;
            osdHovered = false;
            visibilities.dashboard = false;
        }
    }

    onPositionChanged: ({x, y}) => {
        //const showOsd = inLeftPanel(panels.osd, x, y);
        //visibilities.osd = showOsd;
        //osdHovered = showOsd;

        visibilities.dashboard = inBottomPanel(panels.dashboard, x, y);
    }

    /*Osd.Interactions {
     *       screen: root.screen
     *       visibilities: root.visibilities
     *       hovered: root.osdHovered
}*/
}

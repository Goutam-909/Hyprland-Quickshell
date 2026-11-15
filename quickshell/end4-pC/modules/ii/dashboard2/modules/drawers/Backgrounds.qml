import qs.modules.ii.dashboard2.services
//import qs.modules.ii.dashboard2.modules.osd as Osd
import qs.modules.ii.dashboard2.modules.session as Session
import qs.modules.ii.dashboard2.modules.dashboard as Dashboard
import qs.modules.ii.dashboard2.modules.launcher as Launcher
import qs.modules.ii.dashboard2.modules.wallpaper as Wallpaper
import QtQuick
import QtQuick.Shapes
import qs.modules.common

Shape {
    id: root

    required property Panels panels

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

/*    Osd.Background {
        wrapper: panels.osd

        startX: 0
        startY: (root.height - wrapper.height) / 2 - rounding
    }*/

    // Mirror of Osd.Background: docked to the right edge instead of the
    // left, same vertical-center math.
    Session.Background {
        wrapper: panels.session

        startX: root.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Dashboard.Background {
        wrapper: panels.dashboard

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height
    }

    Launcher.Background {
        wrapper: panels.launcher

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height
    }

    Wallpaper.Background {
        wrapper: panels.wallpaper

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height
    }
}

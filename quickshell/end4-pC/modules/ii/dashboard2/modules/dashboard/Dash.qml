import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import "dash"
import QtQuick.Layouts
import qs.modules.common

GridLayout {
    id: root

    // Kept only because User.qml still takes it - not toggled by anything
    // anymore. Existence of this whole pane (controlled by Content.qml's
    // Repeater) is the only lifecycle switch now. Remove this line and the
    // one below once you confirm User.qml doesn't require it.
    property bool shouldUpdate: true

    rowSpacing: Appearance.dashboard.spacing.normal
    columnSpacing: Appearance.dashboard.spacing.normal

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: user.implicitWidth
        Layout.preferredHeight: user.implicitHeight

        User {
            id: user
            shouldUpdate: root.shouldUpdate
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Config.options.caelestiaDashboard.dashboard.sizes.weatherWidth
        Layout.fillHeight: true

        Weather {}
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight

        Calendar {
            id: calendar
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        Media {
            id: media
        }
    }

    component Rect: StyledRect {
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainer
    }
}

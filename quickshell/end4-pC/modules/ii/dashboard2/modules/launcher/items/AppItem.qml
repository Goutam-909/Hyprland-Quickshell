import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.ii.dashboard2.widgets
import qs.modules.common
// AppSearch is the root-level app-search singleton (services/AppSearch.qml).
import qs.services

Item {
    id: root

    required property DesktopEntry modelData
    required property PersistentProperties visibilities
    // Passed down explicitly by AppList's delegate binding (`rowWidth:
    // root.width`) - a plain compile-time-bound property, not derived from
    // `parent` or the `ListView.view` attached property. Both of those
    // read something set by the view's internal delegate-placement timing,
    // which could end up bound before the delegate was actually fully
    // placed and then never re-evaluate - the actual cause of rows being
    // invisible until a manual scroll forced a relayout.
    required property real rowWidth

    implicitHeight: Appearance.dashboard.fontSize.large * 3.4
    width: rowWidth

    StateLayer {
        radius: Appearance.rounding.large

        function onClicked(): void {
            root.modelData?.execute();
            root.visibilities.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.dashboard.padding.normal
        anchors.rightMargin: Appearance.dashboard.padding.normal
        anchors.topMargin: Appearance.dashboard.padding.small
        anchors.bottomMargin: Appearance.dashboard.padding.small

        IconImage {
            id: icon

            asynchronous: true
            source: Quickshell.iconPath(AppSearch.guessIcon(root.modelData?.icon ?? root.modelData?.id ?? ""), "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Appearance.dashboard.spacing.normal
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - Appearance.dashboard.spacing.normal
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                color: Appearance.m3colors.m3onSurface
                font.pointSize: Appearance.dashboard.fontSize.normal
                elide: Text.ElideRight
                width: parent.width
            }

            StyledText {
                id: desc

                text: (root.modelData?.comment || root.modelData?.genericName || "") ?? ""
                color: Appearance.m3colors.m3outline
                font.pointSize: Appearance.dashboard.fontSize.small
                elide: Text.ElideRight
                width: parent.width

                anchors.top: name.bottom
            }
        }
    }
}

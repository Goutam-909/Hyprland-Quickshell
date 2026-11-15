import QtQuick
import qs.modules.ii.dashboard2.widgets
import qs.modules.common
import Quickshell
// Delegate for entries in AppList.actions (action mode, triggered by
// typing ">" in the launcher search box). Deliberately separate from
// AppItem.qml - actions don't have a DesktopEntry to pull an icon file
// from, just a Material Symbol name, so this draws the icon in a small
// rounded chip instead of using IconImage.
Item {
    id: root

    required property var modelData
    required property PersistentProperties visibilities
    // See AppItem.qml for why this is a plain compile-time-bound
    // property instead of something derived from `parent`/`ListView.view`.
    required property real rowWidth

    implicitHeight: Appearance.dashboard.fontSize.large * 3.4
    width: rowWidth

    StateLayer {
        radius: Appearance.rounding.large

        function onClicked(): void {
            root.modelData?.execute?.();
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.dashboard.padding.normal
        anchors.rightMargin: Appearance.dashboard.padding.normal
        anchors.topMargin: Appearance.dashboard.padding.small
        anchors.bottomMargin: Appearance.dashboard.padding.small

        StyledClippingRect {
            id: iconBg

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: parent.height * 0.8
            implicitHeight: implicitWidth

            radius: Appearance.rounding.large
            color: Appearance.m3colors.m3primaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: root.modelData?.icon ?? "bolt"
                fill: 1
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.large
            }
        }

        Item {
            anchors.left: iconBg.right
            anchors.leftMargin: Appearance.dashboard.spacing.normal
            anchors.verticalCenter: iconBg.verticalCenter

            implicitWidth: parent.width - iconBg.width - Appearance.dashboard.spacing.normal
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

                text: root.modelData?.description ?? ""
                color: Appearance.m3colors.m3outline
                font.pointSize: Appearance.dashboard.fontSize.small
                elide: Text.ElideRight
                width: parent.width

                anchors.top: name.bottom
            }
        }
    }
}

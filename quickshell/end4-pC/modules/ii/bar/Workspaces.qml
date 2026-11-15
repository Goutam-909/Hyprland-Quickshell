pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import QtQuick.Layouts

// Entry point loaded by BarContent (name "workspaces" -> "./Workspaces.qml").
// Delegates to whichever workspace design is picked in
// Settings > Bar > Workspaces > Style (Config.options.bar.workspaces.style).
Item {
    id: root

    property bool vertical: Config.options.bar.vertical

    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    implicitWidth: loader.item?.implicitWidth ?? 0
    implicitHeight: loader.item?.implicitHeight ?? 0

    Loader {
        id: loader
        anchors.centerIn: parent
        sourceComponent: Config.options.bar.workspaces.style === "pill" ? pillComponent : defaultComponent
    }

    Component {
        id: defaultComponent
        WorkspacesDefault {}
    }

    Component {
        id: pillComponent
        WorkspacesPill {}
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets
import qs.modules.ii.notch.dashboard.widgets

Item {
    id: root
    implicitWidth: 460
    implicitHeight: tabColumn.implicitHeight

    readonly property var tabModel: [
        { icon: "widgets", label: "Widgets" },
        { icon: "wallpaper", label: "Wallpapers" },
        { icon: "monitoring", label: "Metrics" },
        { icon: "smart_toy", label: "Assistant" }
    ]

    ColumnLayout {
        id: tabColumn
        width: root.implicitWidth
        spacing: 10

        // ---- tab strip -----------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Repeater {
                model: root.tabModel
                delegate: RippleButtonWithIcon {
                    required property var modelData
                    required property int index
                    materialIcon: modelData.icon
                    implicitWidth: 36
                    implicitHeight: 36
                    toggled: GlobalStates.notchCurrentTab === index
                    onClicked: GlobalStates.notchCurrentTab = index
                }
            }
        }

        // ---- tab content -----------------------------------------------
        Item {
            id: tabContainer
            Layout.fillWidth: true
            implicitHeight: currentLoader.item ? currentLoader.item.implicitHeight : 200

            Behavior on implicitHeight {
                enabled: C.Config.options.notch.animDuration > 0
                NumberAnimation { duration: C.Config.options.notch.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }

            Loader {
                id: currentLoader
                anchors.left: parent.left
                anchors.right: parent.right
                sourceComponent: {
                    switch (GlobalStates.notchCurrentTab) {
                        case 0: return widgetsTabComponent;
                        default: return fillerTabComponent;
                    }
                }
            }
        }
    }

    Component {
        id: widgetsTabComponent
        WidgetsTab {}
    }

    // Tabs 1-3 (Wallpapers / Metrics / Assistant) intentionally stubbed
    // per your request - swap this Loader's component for the real tab
    // whenever you want to wire one in.
    Component {
        id: fillerTabComponent
        Item {
            implicitHeight: 160
            StyledText {
                anchors.centerIn: parent
                text: "Coming soon"
                color: C.Appearance.colors.colSubtext
            }
        }
    }
}

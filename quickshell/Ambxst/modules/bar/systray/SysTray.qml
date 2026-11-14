import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.modules.theme
import qs.modules.components
import qs.config
import qs.modules.services

StyledRect {
    variant: "bg"
    id: root

    visible: hasItems

    topLeftRadius: root.vertical ? root.startRadius : root.startRadius
    topRightRadius: root.vertical ? root.startRadius : root.endRadius
    bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
    bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

    required property var bar

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    property bool vertical: bar.orientation === "vertical"

    property bool trayOverflowOpen: false
    property var activeMenu: null

    // When no pins are configured, show ALL items directly (no overflow arrow)
    // When pins exist, pinned = visible directly, unpinned = behind overflow arrow
    readonly property bool hasPins: TrayService.pinnedItems.length > 0

    property list<var> visibleItems: hasPins
        ? TrayService.pinnedItems
        : SystemTray.items.values

    property list<var> overflowItems: hasPins
        ? TrayService.unpinnedItems
        : []

    onOverflowItemsChanged: {
        if (overflowItems.length === 0)
            root.closeOverflowMenu();
    }

    readonly property bool hasItems: SystemTray.items.values.length > 0

    height: vertical ? implicitHeight : parent.height
    Layout.preferredWidth: hasItems ? (gridLayout.implicitWidth + 16) : 0
    implicitWidth: hasItems ? (gridLayout.implicitWidth + 16) : 0
    implicitHeight: hasItems ? (gridLayout.implicitHeight + 16) : 0

    function grabFocus() {
        focusGrab.active = true;
    }

    function setExtraWindowAndGrabFocus(window) {
        if (root.activeMenu && root.activeMenu !== window) {
            if (typeof root.activeMenu.close === "function")
                root.activeMenu.close();
            root.activeMenu = null;
        }
        root.activeMenu = window;
        root.grabFocus();
    }

    function releaseFocus() {
        focusGrab.active = false;
    }

    function closeOverflowMenu() {
        root.trayOverflowOpen = false;
        focusGrab.active = false;
    }

    onTrayOverflowOpenChanged: {
        if (root.trayOverflowOpen)
            root.grabFocus();
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: false
        windows: root.activeMenu ? [root.activeMenu] : []
        onCleared: {
            root.trayOverflowOpen = false;
            if (root.activeMenu) {
                root.activeMenu.close();
                root.activeMenu = null;
            }
        }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors.fill: parent
        anchors.margins: 8
        rowSpacing: 8
        columnSpacing: 8

        // Overflow button — only visible when pins are configured and some items overflow
        Item {
            id: trayOverflowButton
            visible: root.overflowItems.length > 0

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            implicitWidth: 24
            implicitHeight: 24

            property bool hovered: overflowMouse.containsMouse

            Rectangle {
                anchors.fill: parent
                radius: Styling.radius(0)
                color: Styling.srItem("overprimary")
                opacity: root.trayOverflowOpen ? 0.2 : (trayOverflowButton.hovered ? 0.12 : 0)
                Behavior on opacity {
                    enabled: (Config.animDuration ?? 0) > 0
                    NumberAnimation { duration: (Config.animDuration ?? 0) / 2 }
                }
            }

            MouseArea {
                id: overflowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.trayOverflowOpen = !root.trayOverflowOpen
            }

            Text {
                anchors.centerIn: parent
                text: root.vertical ? Icons.caretRight : Icons.caretDown
                font.family: Icons.font
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.trayOverflowOpen
                    ? Styling.srItem("overprimary")
                    : Colors.overBackground
                rotation: root.trayOverflowOpen ? 180 : 0
                Behavior on rotation {
                    enabled: (Config.animDuration ?? 0) > 0
                    NumberAnimation { duration: (Config.animDuration ?? 0) / 2 }
                }
                Behavior on color {
                    enabled: (Config.animDuration ?? 0) > 0
                    ColorAnimation { duration: (Config.animDuration ?? 0) / 2 }
                }
            }

            BarPopup {
                id: overflowPopup
                anchorItem: trayOverflowButton
                bar: root.bar
                visible: root.trayOverflowOpen && root.overflowItems.length > 0

                contentWidth: overflowGrid.implicitWidth + 16
                contentHeight: overflowGrid.implicitHeight + 16
                popupPadding: 8
                visualMargin: 16

                GridLayout {
                    anchors.centerIn: parent

                    GridLayout {
                        id: overflowGrid
                        columns: Math.ceil(Math.sqrt(root.overflowItems.length))
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: root.overflowItems

                            delegate: SysTrayItem {
                                required property SystemTrayItem modelData
                                item: modelData
                                bar: root.bar
                                onMenuClosed: root.releaseFocus()
                                onMenuOpened: (qsWindow) => root.setExtraWindowAndGrabFocus(qsWindow)
                            }
                        }
                    }
                }
            }
        }

        // All items shown directly (or just pinned ones if pins are configured)
        Repeater {
            model: ScriptModel {
                values: root.visibleItems
            }

            delegate: SysTrayItem {
                required property SystemTrayItem modelData
                item: modelData
                bar: root.bar
                Layout.fillHeight: !root.vertical
                Layout.fillWidth: root.vertical
                onMenuClosed: root.releaseFocus()
                onMenuOpened: (qsWindow) => root.setExtraWindowAndGrabFocus(qsWindow)
            }
        }
    }
}

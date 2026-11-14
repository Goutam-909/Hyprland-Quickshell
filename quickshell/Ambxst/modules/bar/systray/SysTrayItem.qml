pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.modules.services
import qs.modules.theme
import qs.modules.components
import qs.config

MouseArea {
    id: root

    required property var bar
    required property SystemTrayItem item

    signal menuOpened(qsWindow: var)
    signal menuClosed()

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: 20
    implicitHeight: 20

    Layout.fillHeight: bar.orientation === "horizontal"
    Layout.fillWidth: bar.orientation === "vertical"

    onPressed: (event) => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu) {
                systrayPopup.toggle();
            }
            break;
        }
        event.accepted = true;
    }

    BarPopup {
        id: systrayPopup
        anchorItem: root
        bar: root.bar

        contentWidth: 250
        contentHeight: Math.min(menuStack.implicitHeight + 16, 400)
        popupPadding: 8
        visualMargin: 16

        // Back navigation on right-click or back button while in a submenu
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.BackButton | Qt.RightButton
            propagateComposedEvents: true
            onPressed: event => {
                if (menuStack.depth > 1) {
                    menuStack.pop();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }
        }

        StackView {
            id: menuStack
            anchors.fill: parent
            clip: true

            implicitHeight: currentItem ? currentItem.implicitHeight : 0
            implicitWidth: currentItem ? currentItem.implicitWidth : 0

            pushEnter: Transition { NumberAnimation { duration: 0 } }
            pushExit:  Transition { NumberAnimation { duration: 0 } }
            popEnter:  Transition { NumberAnimation { duration: 0 } }
            popExit:   Transition { NumberAnimation { duration: 0 } }

            initialItem: subMenuComponent.createObject(menuStack, {
                menuHandle: root.item.menu,
                isSubMenu: false
            })
        }

        Component {
            id: subMenuComponent

            Item {
                id: subMenuRoot
                property var menuHandle: null
                property bool isSubMenu: false

                implicitWidth: subColumn.implicitWidth
                implicitHeight: subColumn.implicitHeight

                StackView.onRemoved: destroy()

                QsMenuOpener {
                    id: subMenuOpener
                    menu: subMenuRoot.menuHandle
                }

                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: subColumn
                        width: 220
                        spacing: 2

                        // Back button — shown only in submenus
                        Button {
                            id: backButton
                            visible: subMenuRoot.isSubMenu
                            Layout.fillWidth: true
                            implicitHeight: 36
                            padding: 0

                            onClicked: menuStack.pop()

                            background: Rectangle {
                                color: backButton.hovered ? Styling.srItem("overprimary") : "transparent"
                                radius: Styling.radius(0)
                                Behavior on color {
                                    enabled: (Config.animDuration ?? 0) > 0
                                    ColorAnimation { duration: (Config.animDuration ?? 0) / 2 }
                                }
                            }

                            contentItem: RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                spacing: 8
                                Text {
                                    text: Icons.caretLeft
                                    font.family: Icons.font
                                    font.pixelSize: 14
                                    color: backButton.hovered ? Colors.overPrimary : Colors.overBackground
                                    verticalAlignment: Text.AlignVCenter
                                    Behavior on color {
                                        enabled: (Config.animDuration ?? 0) > 0
                                        ColorAnimation { duration: (Config.animDuration ?? 0) / 2 }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Back"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: backButton.hovered ? Colors.overPrimary : Colors.overBackground
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    Behavior on color {
                                        enabled: (Config.animDuration ?? 0) > 0
                                        ColorAnimation { duration: (Config.animDuration ?? 0) / 2 }
                                    }
                                }
                            }
                        }

                        // Divider under back button
                        Rectangle {
                            visible: subMenuRoot.isSubMenu
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Colors.surfaceBright
                            Layout.topMargin: 2
                            Layout.bottomMargin: 2
                        }

                        Repeater {
                            id: entriesRepeater
                            model: subMenuOpener.children

                            property bool iconColumnNeeded: {
                                for (let i = 0; i < subMenuOpener.children.values.length; i++) {
                                    if (subMenuOpener.children.values[i].icon.length > 0)
                                        return true;
                                }
                                return false;
                            }
                            property bool specialInteractionColumnNeeded: {
                                for (let i = 0; i < subMenuOpener.children.values.length; i++) {
                                    if (subMenuOpener.children.values[i].buttonType !== QsMenuButtonType.None)
                                        return true;
                                }
                                return false;
                            }

                            delegate: SysTrayMenuEntry {
                                required property QsMenuEntry modelData
                                Layout.fillWidth: true
                                menuEntry: modelData
                                forceIconColumn: entriesRepeater.iconColumnNeeded
                                forceSpecialInteractionColumn: entriesRepeater.specialInteractionColumnNeeded
                                onDismiss: systrayPopup.close()
                                onOpenSubmenu: handle => {
                                    menuStack.push(subMenuComponent.createObject(menuStack, {
                                        menuHandle: handle,
                                        isSubMenu: true
                                    }))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Color icon
    IconImage {
        id: trayIcon
        visible: !(Config.bar?.tray?.monochromeIcons ?? false)
        source: {
            const iconPath = root.item.icon.toString();
            if (iconPath.includes("spotify"))
                return Quickshell.iconPath("spotify-client");
            return root.item.icon;
        }
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        smooth: true
    }

    Tinted {
        sourceItem: trayIcon
        anchors.fill: trayIcon
    }

    StyledToolTip {
        show: root.containsMouse
        tooltipText: TrayService.getTooltipForItem(root.item)
    }
}

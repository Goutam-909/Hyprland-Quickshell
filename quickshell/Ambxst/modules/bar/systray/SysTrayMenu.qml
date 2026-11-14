pragma ComponentBehavior: Bound

import qs.modules.theme
import qs.modules.components
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root
    required property QsMenuHandle trayItemMenuHandle
    property string barPosition: "bottom"
    property real popupBackgroundMargin: 0

    signal menuClosed
    signal menuOpened(qsWindow: var)

    color: "transparent"
    property real padding: 8

    implicitHeight: {
        let result = 0;
        for (let child of stackView.children) {
            result = Math.max(child.implicitHeight, result);
        }
        return result + popupBackground.padding * 2 + root.padding * 2;
    }
    implicitWidth: {
        let result = 0;
        for (let child of stackView.children) {
            result = Math.max(child.implicitWidth, result);
        }
        return result + popupBackground.padding * 2 + root.padding * 2;
    }

    function open() {
        root.visible = true;
        root.menuOpened(root);
    }

    function close() {
        root.visible = false;
        while (stackView.depth > 1)
            stackView.pop();
        root.menuClosed();
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.RightButton
        onPressed: event => {
            if ((event.button === Qt.BackButton || event.button === Qt.RightButton) && stackView.depth > 1)
                stackView.pop();
        }

        Rectangle {
            id: popupBackground
            readonly property real padding: 4
            anchors {
                left: parent.left
                right: parent.right
                margins: root.padding
            }

            color: Colors.background
            radius: Styling.radius(8)
            border.width: 1
            border.color: Colors.surfaceBright
            clip: true

            opacity: 0
            Component.onCompleted: opacity = 1
            implicitWidth: stackView.implicitWidth + popupBackground.padding * 2
            implicitHeight: stackView.implicitHeight + popupBackground.padding * 2

            Behavior on opacity {
                enabled: (Config.animDuration ?? 0) > 0
                NumberAnimation { duration: Config.animDuration ?? 0 }
            }
            Behavior on implicitHeight {
                enabled: (Config.animDuration ?? 0) > 0
                NumberAnimation { duration: (Config.animDuration ?? 0) / 2; easing.type: Easing.OutCubic }
            }
            Behavior on implicitWidth {
                enabled: (Config.animDuration ?? 0) > 0
                NumberAnimation { duration: (Config.animDuration ?? 0) / 2; easing.type: Easing.OutCubic }
            }

            StackView {
                id: stackView
                anchors {
                    fill: parent
                    margins: popupBackground.padding
                }
                pushEnter: NoAnim {}
                pushExit: NoAnim {}
                popEnter: NoAnim {}
                popExit: NoAnim {}

                implicitWidth: currentItem ? currentItem.implicitWidth : 0
                implicitHeight: currentItem ? currentItem.implicitHeight : 0

                initialItem: SubMenu {
                    handle: root.trayItemMenuHandle
                }
            }
        }
    }

    component NoAnim: Transition {
        NumberAnimation { duration: 0 }
    }

    component SubMenu: ColumnLayout {
        id: submenu
        required property QsMenuHandle handle
        property bool isSubMenu: false
        property bool shown: false
        opacity: shown ? 1 : 0

        Behavior on opacity {
            enabled: (Config.animDuration ?? 0) > 0
            NumberAnimation { duration: Config.animDuration ?? 0 }
        }

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        QsMenuOpener {
            id: menuOpener
            menu: submenu.handle
        }

        spacing: 0

        // Back button (shown in submenus)
        Loader {
            Layout.fillWidth: true
            visible: submenu.isSubMenu
            active: visible
            sourceComponent: Button {
                id: backButton
                implicitWidth: 200
                implicitHeight: 36
                padding: 0

                onClicked: stackView.pop()

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
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8
                    Text {
                        text: Icons.caretLeft
                        font.family: Icons.font
                        font.pixelSize: 16
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
        }

        // Menu entries
        Repeater {
            id: menuEntriesRepeater
            property bool iconColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].icon.length > 0)
                        return true;
                }
                return false;
            }
            property bool specialInteractionColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].buttonType !== QsMenuButtonType.None)
                        return true;
                }
                return false;
            }
            model: menuOpener.children
            delegate: SysTrayMenuEntry {
                required property QsMenuEntry modelData
                forceIconColumn: menuEntriesRepeater.iconColumnNeeded
                forceSpecialInteractionColumn: menuEntriesRepeater.specialInteractionColumnNeeded
                menuEntry: modelData
                onDismiss: root.close()
                onOpenSubmenu: handle => {
                    stackView.push(subMenuComponent.createObject(null, {
                        handle: handle,
                        isSubMenu: true
                    }));
                }
            }
        }
    }

    Component {
        id: subMenuComponent
        SubMenu {}
    }
}

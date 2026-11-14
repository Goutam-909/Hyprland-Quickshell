pragma ComponentBehavior: Bound

import qs.modules.theme
import qs.modules.components
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.services

Button {
    id: root
    required property QsMenuEntry menuEntry
    property bool forceIconColumn: false
    property bool forceSpecialInteractionColumn: false

    readonly property bool hasIcon: menuEntry?.icon.length > 0 ?? false
    readonly property bool hasSpecialInteraction: menuEntry?.buttonType !== QsMenuButtonType.None ?? false
    readonly property bool isSeparator: menuEntry?.isSeparator ?? false

    signal dismiss()
    signal openSubmenu(handle: QsMenuHandle)

    enabled: !root.isSeparator
    opacity: 1
    padding: 0

    implicitWidth: 200
    implicitHeight: root.isSeparator ? 10 : 36
    Layout.topMargin: root.isSeparator ? 4 : 0
    Layout.bottomMargin: root.isSeparator ? 4 : 0
    Layout.fillWidth: true

    onClicked: {
        if (!menuEntry) return;
        if (menuEntry.hasChildren) {
            root.openSubmenu(root.menuEntry);
            return;
        }
        menuEntry.triggered();
        root.dismiss();
    }

    background: Rectangle {
        color: root.isSeparator
            ? "transparent"
            : (root.hovered ? Styling.srItem("overprimary") : "transparent")
        radius: Styling.radius(0)

        // Separator line - inset like old design
        Rectangle {
            visible: root.isSeparator
            height: 1
            color: Colors.surfaceBright
            anchors.centerIn: parent
            width: parent.width - 16
        }

        Behavior on color {
            enabled: (Config.animDuration ?? 0) > 0
            ColorAnimation { duration: (Config.animDuration ?? 0) / 2 }
        }
    }

    contentItem: RowLayout {
        id: contentItem
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 8
        visible: !root.isSeparator

        // Checkbox / radio interaction column
        Item {
            visible: root.hasSpecialInteraction || root.forceSpecialInteractionColumn
            implicitWidth: 20
            implicitHeight: 20

            // Radio button
            Loader {
                anchors.centerIn: parent
                active: (menuEntry?.buttonType ?? QsMenuButtonType.None) === QsMenuButtonType.RadioButton
                sourceComponent: Text {
                    text: (menuEntry?.checkState ?? Qt.Unchecked) === Qt.Checked ? Icons.circle : Icons.range
                    font.family: Icons.font
                    font.pixelSize: 14
                    color: (menuEntry?.checkState ?? Qt.Unchecked) === Qt.Checked
                        ? Styling.srItem("overprimary")
                        : Colors.overBackground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Checkbox
            Loader {
                anchors.centerIn: parent
                active: (menuEntry?.buttonType ?? QsMenuButtonType.None) === QsMenuButtonType.CheckBox
                    && (menuEntry?.checkState ?? Qt.Unchecked) !== Qt.Unchecked
                sourceComponent: Text {
                    text: (menuEntry?.checkState ?? Qt.Unchecked) === Qt.PartiallyChecked
                        ? Icons.minus
                        : Icons.accept
                    font.family: Icons.font
                    font.pixelSize: 14
                    color: Styling.srItem("overprimary")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Icon column
        Item {
            visible: root.hasIcon || root.forceIconColumn
            implicitWidth: 16
            implicitHeight: 16

            Loader {
                anchors.centerIn: parent
                active: (menuEntry?.icon.length ?? 0) > 0
                sourceComponent: IconImage {
                    asynchronous: true
                    source: menuEntry?.icon ?? ""
                    implicitSize: 16
                    mipmap: true
                }
            }
        }

        // Label
        Text {
            id: label
            text: menuEntry?.text ?? ""
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: root.hovered ? Colors.overPrimary : Colors.overBackground
            Layout.fillWidth: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter

            Behavior on color {
                enabled: (Config.animDuration ?? 0) > 0
                ColorAnimation { duration: (Config.animDuration ?? 0) / 2 }
            }
        }

        // Submenu chevron
        Loader {
            active: menuEntry?.hasChildren ?? false
            sourceComponent: Text {
                text: Icons.caretRight
                font.family: Icons.font
                font.pixelSize: 14
                color: root.hovered ? Colors.overPrimary : Colors.overBackground
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.theme

// Capsule search field with a magnifier — same signals SearchInput exposed to
// the settings sidebar (searchTextChanged / accepted / up / down / escape).
Item {
    id: root

    property alias text: input.text
    property string placeholderText: "Search"
    property bool clearOnEscape: true

    signal searchTextChanged(string text)
    signal accepted
    signal escapePressed
    signal downPressed
    signal upPressed

    function focusInput() {
        input.forceActiveFocus();
    }
    function clear() {
        input.text = "";
    }

    implicitHeight: 38
    implicitWidth: 200

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: height / 2
        color: "transparent"
        border.width: 3
        border.color: MacStyle.focusRing
        opacity: input.activeFocus ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: MacStyle.fast
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: MacStyle.searchField
    }

    // magnifier drawn from primitives (no icon glyph needed)
    Item {
        id: mag
        x: 13
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        Rectangle {
            width: 12.5
            height: 12.5
            radius: width / 2
            color: "transparent"
            border.width: 1.6
            border.color: MacStyle.labelSecondary
        }
        Rectangle {
            x: 9.6
            y: 12
            width: 6.5
            height: 1.7
            radius: 1
            rotation: 45
            transformOrigin: Item.Left
            color: MacStyle.labelSecondary
        }
    }

    TextInput {
        id: input
        anchors.left: mag.right
        anchors.leftMargin: 9
        anchors.right: clearBtn.visible ? clearBtn.left : parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        selectByMouse: true
        font.family: MacStyle.fontFamily
        font.pixelSize: MacStyle.fsBody
        color: MacStyle.label
        selectionColor: MacStyle.accent
        selectedTextColor: "#FFFFFF"

        onTextChanged: root.searchTextChanged(text)
        onAccepted: root.accepted()

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.clearOnEscape)
                    root.clear();
                root.escapePressed();
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.downPressed();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.upPressed();
                event.accepted = true;
            }
        }

        Text {
            visible: input.text === "" && !input.preeditText
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholderText
            font: input.font
            color: MacStyle.placeholder
        }
    }

    Item {
        id: clearBtn
        visible: input.text !== ""
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: 20
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: MacStyle.labelTertiary
        }
        Text {
            anchors.centerIn: parent
            text: Icons.cancel
            font.family: Icons.font
            font.pixelSize: 10
            color: MacStyle.window
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.clear();
                input.forceActiveFocus();
            }
        }
    }
}

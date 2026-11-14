import QtQuick
import qs.modules.theme

// The red / yellow / green window buttons.
Row {
    id: root

    property bool minimizeEnabled: false
    property bool zoomEnabled: true
    property bool active: true

    signal closeClicked
    signal minimizeClicked
    signal zoomClicked

    spacing: 8

    component Light: Item {
        id: light
        required property color base
        required property color edge
        required property string symbol
        property bool lightEnabled: true
        signal clicked

        width: 13
        height: 13

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: light.lightEnabled && root.active ? light.base : (MacStyle.dark ? "#4B4B4D" : "#CFCFCF")
            border.width: 0.5
            border.color: light.lightEnabled && root.active ? light.edge : (MacStyle.dark ? "#5A5A5C" : "#BDBDBD")
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -0.5
            visible: light.lightEnabled && row.hovered
            text: light.symbol
            font.family: Icons.font
            font.pixelSize: 8
            color: Qt.rgba(0, 0, 0, 0.55)
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -2
            enabled: light.lightEnabled
            onClicked: light.clicked()
        }
    }

    HoverHandler {
        id: row
    }

    Light {
        base: "#FF5F57"
        edge: "#E0443E"
        symbol: Icons.cancel
        onClicked: root.closeClicked()
    }
    Light {
        base: "#FEBC2E"
        edge: "#DEA123"
        symbol: Icons.minus
        lightEnabled: root.minimizeEnabled
        onClicked: root.minimizeClicked()
    }
    Light {
        base: "#28C840"
        edge: "#1AAB29"
        symbol: Icons.arrowsOut
        lightEnabled: root.zoomEnabled
        onClicked: root.zoomClicked()
    }
}

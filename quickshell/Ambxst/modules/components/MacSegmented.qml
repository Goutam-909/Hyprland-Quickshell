import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// macOS segmented control. options: [{ label, value, icon (optional glyph) }]
Item {
    id: root

    property var options: []
    property string value: ""
    property bool stretch: false        // fill the available width
    signal valueSelected(string newValue)

    readonly property int currentIndex: {
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === value)
                return i;
        }
        return -1;
    }

    implicitHeight: 30
    implicitWidth: row.implicitWidth + 4
    Layout.fillWidth: stretch
    opacity: enabled ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        radius: MacStyle.controlRadius + 1
        color: MacStyle.segmentTrack
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0

        Repeater {
            id: rep
            model: root.options

            delegate: Item {
                id: seg
                required property var modelData
                required property int index
                readonly property bool selected: index === root.currentIndex

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: segRow.implicitWidth + 26
                Layout.preferredWidth: root.stretch ? 1 : segRow.implicitWidth + 26

                // selection highlight lives in the segment itself (no lookup, no glitch)
                Rectangle {
                    anchors.fill: parent
                    radius: MacStyle.controlRadius - 1
                    color: Qt.rgba(MacStyle.accent.r, MacStyle.accent.g, MacStyle.accent.b, 0.22)   // soft tint (0.15 quieter / 0.30 stronger)
                    opacity: seg.selected ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: MacStyle.fast
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    id: segRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        visible: (seg.modelData.icon ?? "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: seg.modelData.icon ?? ""
                        font.family: Icons.font
                        font.pixelSize: 15
                        color: seg.selected ? MacStyle.accent : MacStyle.label
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: seg.modelData.label
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsBody
                        font.weight: seg.selected ? Font.DemiBold : Font.Normal
                        color: seg.selected ? MacStyle.accent : MacStyle.label
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.valueSelected(seg.modelData.value)
                }
            }
        }
    }
}

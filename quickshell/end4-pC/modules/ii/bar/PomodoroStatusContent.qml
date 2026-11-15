import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Compact "pomodoro running" indicator shown in the visualizer slot.
// Content-only component - sizing/positioning is owned by the parent (Visualizer.qml).
Item {
    id: root
    property bool vertical: false

    readonly property int secondsLeft: Math.max(0, TimerService.pomodoroSecondsLeft)
    readonly property string timeText: {
        const m = Math.floor(secondsLeft / 60).toString().padStart(2, '0')
        const s = Math.floor(secondsLeft % 60).toString().padStart(2, '0')
        return `${m}:${s}`
    }
    readonly property real progress: TimerService.pomodoroLapDuration > 0
        ? 1 - (secondsLeft / TimerService.pomodoroLapDuration)
        : 0
    readonly property color statusColor: TimerService.pomodoroBreak
        ? Appearance.colors.colTertiary
        : Appearance.colors.colPrimary

    // Horizontal layout (normal bar)
    RowLayout {
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 8
            implicitHeight: 8
            radius: 4
            color: root.statusColor
            opacity: TimerService.pomodoroRunning ? 1 : 0.4

            SequentialAnimation on opacity {
                running: TimerService.pomodoroRunning
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.small
            font.features: { "tnum": 1 }
            color: Appearance.colors.colOnLayer0
            text: root.timeText
        }
    }

    // Vertical layout (vertical bar) - rotate the readout so it reads along the bar
    ColumnLayout {
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 4

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 8
            implicitHeight: 8
            radius: 4
            color: root.statusColor
            opacity: TimerService.pomodoroRunning ? 1 : 0.4

            SequentialAnimation on opacity {
                running: TimerService.pomodoroRunning
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.features: { "tnum": 1 }
            color: Appearance.colors.colOnLayer0
            text: root.timeText
            rotation: -90
        }
    }
}

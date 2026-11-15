import QtQuick
import qs
import qs.services
import qs.modules.common

// Status-indicator visualizer for the bar.
// Default state: shows the cava-style audio visualizer.
// When a status becomes active (e.g. pomodoro running), it slides up from the
// bottom and pushes the cava visualizer down out of view. When no status is
// active anymore, cava slides back up into view.
//
// To add a new status later: add an entry to `statusStack` below with an
// `active` bool and a `component`. First active entry (top to bottom) wins.
Item {
    id: root
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property bool mirrored: false

    // Geometry constants - kept here so both the container and the cava
    // content agree on sizing.
    readonly property int barCount: 20
    readonly property real dotSize: 3
    readonly property real dotSpacing: 3

    // ==== Status stack ====
    // Add more statuses here later (stopwatch, recording, etc.). The first
    // entry whose `active` is true wins and slides in.
    readonly property var statusStack: [
        { name: "pomodoro", active: TimerService.pomodoroRunning, component: pomodoroStatusComponent }
    ]
    readonly property var activeStatus: {
        for (const s of statusStack) {
            if (s.active) return s;
        }
        return null;
    }
    readonly property bool hasActiveStatus: activeStatus !== null

    implicitWidth: vertical
    ? Appearance.sizes.verticalBarWidth
    : (barCount * (dotSize + dotSpacing)) + (isMaterial ? 16 : 0)
    implicitHeight: vertical
    ? (barCount * (dotSize + dotSpacing)) + (isMaterial ? 16 : 0)
    : Appearance.sizes.barHeight

    clip: true

    // Default cava visualizer - sits in place normally, slides out (down/right)
    // when a status becomes active.
    Loader {
        id: cavaLoader
        width: root.width
        height: root.height
        sourceComponent: cavaComponent
        y: root.hasActiveStatus ? root.height : 0
        Behavior on y {
            NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
        }
    }

    // Status layer - slides in (up) from below when active, slides back out when not.
    Loader {
        id: statusLoader
        width: root.width
        height: root.height
        active: root.hasActiveStatus
        sourceComponent: root.hasActiveStatus ? root.activeStatus.component : null
        y: root.hasActiveStatus ? 0 : -root.height
        Behavior on y {
            NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
        }
    }

    Component {
        id: cavaComponent
        CavaVisualizerContent {
            vertical: root.vertical
            mirrored: root.mirrored
            barCount: root.barCount
            dotSize: root.dotSize
            dotSpacing: root.dotSpacing
        }
    }

    Component {
        id: pomodoroStatusComponent
        PomodoroStatusContent {
            vertical: root.vertical
        }
    }
}

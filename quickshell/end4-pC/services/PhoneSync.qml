pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common

import Quickshell
import QtQuick
import QtWebSockets

// ── PhoneSync ────────────────────────────────────────────────────────────
// Pushes TimerService's pomodoro/stopwatch state, plus a live snapshot of
// today's StudySchedule, to phone_sync_server.py (running locally on this
// same machine) over a WebSocket, which then relays it to any connected
// phone browser. Read-only, one-way: this never receives commands back
// from the phone.
//
// Requires the `qt6-websockets` package for the QtWebSockets QML import.
//
// Like StudyScheduler, this is a `pragma Singleton` — call `PhoneSync.load()`
// once from shell.qml's Component.onCompleted so it actually connects at
// startup instead of only when something else happens to touch it.
// ────────────────────────────────────────────────────────────────────────
Singleton {
    id: root

    // Must match STUDY_SYNC_TOKEN on the server. Change both together.
    readonly property string token: "ccdd255224e2d359cd664c5017ecc68a"
    readonly property string serverHost: "127.0.0.1" // server runs on this same laptop
    readonly property int serverPort: 8420

    readonly property bool connected: socket.status === WebSocket.Open

    function load() {} // no-op; just forces instantiation at startup

    WebSocket {
        id: socket
        url: "ws://" + root.serverHost + ":" + root.serverPort + "/ws?token=" + root.token + "&role=producer"
        active: true

        onStatusChanged: (status) => {
            if (status === WebSocket.Error) {
                console.warn("PhoneSync: connection error —", socket.errorString);
            }
        }
    }

    function _send(obj) {
        if (socket.status === WebSocket.Open) {
            socket.sendTextMessage(JSON.stringify(obj));
        }
    }

    // Builds today's schedule snapshot: every block relevant to "now"
    // (today's own blocks + the tail of anything carried over from
    // yesterday, via StudySchedule.activeEntriesForDate()), each tagged
    // with its live status, for the phone to render as a timeline.
    //
    //   done      — StudyLog already has this occurrence logged complete
    //   current   — enabled, not yet logged, and `now` falls in its window
    //   upcoming  — enabled, not yet logged, starts later today
    //   skipped   — disabled for today (toggled off / template disabled)
    //   missed    — window already passed, enabled, but never got logged
    //               (shouldn't normally happen given StudyScheduler always
    //               logs on stop, but guards against edge cases/edits)
    function _scheduleSnapshot() {
        const now = new Date();
        const mins = now.getHours() * 60 + now.getMinutes();
        const entries = StudySchedule.activeEntriesForDate(now);

        const blocks = entries.map(e => {
            let status;
            if (!e.enabled) {
                status = "skipped";
            } else if (StudyLog.hasCompleted(e.id, e.ownerDateKey)) {
                status = "done";
            } else if (mins >= e.relativeStart && mins < e.relativeEnd) {
                status = "current";
            } else if (mins < e.relativeStart) {
                status = "upcoming";
            } else {
                status = "missed";
            }
            return {
                id: e.id,
                label: e.label,
                start: StudySchedule.formatMinute(e.startMinute),
                                   end: StudySchedule.formatMinute(e.endMinute),
                                   noBreak: !!e.noBreak,
                                   longSession: !!e.longSession,
                                   carriedFromPrevDay: !!e.carriedFromPrevDay,
                                   status: status
            };
        });

        return {
            todayTotal: StudyLog.formatDuration(StudyLog.minutesToday()),
            blocks: blocks
        };
    }

    function pushState() {
        _send({
            type: "state",
            ts: Date.now(),
              pomodoro: {
                  running: TimerService.pomodoroRunning,
                  isBreak: TimerService.pomodoroBreak,
                  isLongBreak: TimerService.pomodoroLongBreak,
                  secondsLeft: Math.max(0, TimerService.pomodoroSecondsLeft),
              lapDuration: TimerService.pomodoroLapDuration,
              cycle: TimerService.pomodoroCycle,
              cyclesBeforeLongBreak: TimerService.cyclesBeforeLongBreak,
              scheduleActive: TimerService.scheduleActive,
              scheduleLabel: TimerService.scheduleActive ? Persistent.states.timer.pomodoro.scheduleLabel : ""
              },
              stopwatch: {
                  running: TimerService.stopwatchRunning,
                  time10ms: TimerService.stopwatchTime
              },
              schedule: root._scheduleSnapshot()
        });
    }

    // Push immediately on meaningful state changes (start/pause/break switch)...
    Connections {
        target: TimerService
        function onPomodoroRunningChanged() { root.pushState(); }
        function onPomodoroBreakChanged() { root.pushState(); }
        function onStopwatchRunningChanged() { root.pushState(); }
    }

    // ...and once a second regardless, so the countdown on the phone stays
    // live and the schedule snapshot naturally rolls "upcoming" -> "current"
    // -> "done" as the poll from StudyScheduler logs each block.
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: root.pushState()
    }

    Component.onCompleted: pushState()
}

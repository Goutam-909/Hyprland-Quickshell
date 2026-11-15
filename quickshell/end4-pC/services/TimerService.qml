pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Simple Pomodoro time manager.
 */
Singleton {
    id: root

    // True while a scheduled study block (services/StudySchedule.qml) is
    // driving this pomodoro. Backed entirely by Persistent.states (not a
    // separate in-memory property) so a shell restart mid-session doesn't
    // lose track of it — see StudyScheduler.check() for the reconciliation
    // that uses this to detect and clean up an orphaned session after a
    // restart, or when the driving block gets disabled/edited/deleted.
    property bool scheduleActive: Persistent.states.timer.pomodoro.scheduleEntryId !== ""
    property bool scheduleNoBreak: scheduleActive && Persistent.states.timer.pomodoro.scheduleNoBreak

    property int focusTime: scheduleActive ? Persistent.states.timer.pomodoro.scheduleFocusSeconds : Config.options.time.pomodoro.focus
    property int breakTime: scheduleActive ? Persistent.states.timer.pomodoro.scheduleBreakSeconds : Config.options.time.pomodoro.breakTime
    property int longBreakTime: Config.options.time.pomodoro.longBreak
    property int cyclesBeforeLongBreak: Config.options.time.pomodoro.cyclesBeforeLongBreak

    property bool pomodoroRunning: Persistent.states.timer.pomodoro.running
    property bool pomodoroBreak: Persistent.states.timer.pomodoro.isBreak
    property bool pomodoroLongBreak: Persistent.states.timer.pomodoro.isBreak && (pomodoroCycle + 1 == cyclesBeforeLongBreak);
    property int pomodoroLapDuration: pomodoroLongBreak ? longBreakTime : pomodoroBreak ? breakTime : focusTime // This is a binding that's to be kept
    property int pomodoroSecondsLeft: pomodoroLapDuration // Reasonable init value, to be changed
    property int pomodoroCycle: Persistent.states.timer.pomodoro.cycle

    property bool stopwatchRunning: Persistent.states.timer.stopwatch.running
    property int stopwatchTime: 0
    property int stopwatchStart: Persistent.states.timer.stopwatch.start
    property var stopwatchLaps: Persistent.states.timer.stopwatch.laps

    // General
    Component.onCompleted: {
        if (!stopwatchRunning)
            stopwatchReset();
    }

    function getCurrentTimeInSeconds() {  // Pomodoro uses Seconds
        return Math.floor(Date.now() / 1000);
    }

    function getCurrentTimeIn10ms() {  // Stopwatch uses 10ms
        return Math.floor(Date.now() / 10);
    }

    // Pomodoro
    function refreshPomodoro() {
        // Work <-> break ?
        if (getCurrentTimeInSeconds() >= Persistent.states.timer.pomodoro.start + pomodoroLapDuration) {
            if (root.scheduleNoBreak) {
                // One continuous focus lap for a "no break" scheduled
                // block — just stop, don't flip to a break phase.
                //
                // Deliberately NOT calling _clearScheduleState() here.
                // This function runs on TimerService's own fast 200ms
                // timer, completely independent of StudyScheduler's
                // 2-second poll — clearing scheduleEntryId here used to
                // wipe the "this session is/was driving the timer" marker
                // out from under StudyScheduler before it ever got a
                // chance to notice the block ended, so it never reached
                // the code that logs to StudyLog. Any block short enough
                // (or explicitly marked) to run as a single no-break lap
                // was silently logging zero minutes, every time.
                // Leaving scheduleEntryId set just means: stopped, but
                // still recognizably "this was driving it" — the next
                // StudyScheduler.check() (well within a couple seconds)
                // sees the window has closed, logs the real elapsed time,
                // and calls endScheduledSession() itself, which clears
                // this state the same way every other completion path
                // already does.
                Persistent.states.timer.pomodoro.running = false;
                pomodoroSecondsLeft = 0;
                Quickshell.execDetached(["notify-send", "Pomodoro", Translation.tr("✅ Study session complete"), "-a", "Shell"]);
                if (Config.options.sounds.pomodoro) {
                    Audio.playSystemSound("alarm-clock-elapsed")
                }
                return;
            }

            // Reset counts
            Persistent.states.timer.pomodoro.isBreak = !Persistent.states.timer.pomodoro.isBreak;
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds();

            // Send notification
            let notificationMessage;
            if (Persistent.states.timer.pomodoro.isBreak && (pomodoroCycle + 1 == cyclesBeforeLongBreak)) {
                notificationMessage = Translation.tr(`🌿 Long break: %1 minutes`).arg(Math.floor(longBreakTime / 60));
            } else if (Persistent.states.timer.pomodoro.isBreak) {
                notificationMessage = Translation.tr(`☕ Break: %1 minutes`).arg(Math.floor(breakTime / 60));
            } else {
                notificationMessage = Translation.tr(`🔴 Focus: %1 minutes`).arg(Math.floor(focusTime / 60));
            }

            Quickshell.execDetached(["notify-send", "Pomodoro", notificationMessage, "-a", "Shell"]);
            if (Config.options.sounds.pomodoro) {
                Audio.playSystemSound("alarm-clock-elapsed")
            }

            if (!pomodoroBreak) {
                Persistent.states.timer.pomodoro.cycle = (Persistent.states.timer.pomodoro.cycle + 1) % root.cyclesBeforeLongBreak;
            }
        }

        pomodoroSecondsLeft = pomodoroLapDuration - (getCurrentTimeInSeconds() - Persistent.states.timer.pomodoro.start);
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: root.pomodoroRunning
        repeat: true
        onTriggered: refreshPomodoro()
    }

    function togglePomodoro() {
        Persistent.states.timer.pomodoro.running = !pomodoroRunning;
        if (Persistent.states.timer.pomodoro.running) {
            // Start/Resume
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds() + pomodoroSecondsLeft - pomodoroLapDuration;
        }
    }

    function resetPomodoro() {
        Persistent.states.timer.pomodoro.running = false;
        Persistent.states.timer.pomodoro.isBreak = false;
        Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds();
        Persistent.states.timer.pomodoro.cycle = 0;
        refreshPomodoro();
    }

    // ── Scheduled study-block driving ──────────────────────────────────
    // Clears all persisted schedule-driving state, restoring normal
    // Config-driven focus/break behaviour for manual pomodoro use.
    function _clearScheduleState() {
        Persistent.states.timer.pomodoro.scheduleEntryId = "";
        Persistent.states.timer.pomodoro.scheduleDateKey = "";
        Persistent.states.timer.pomodoro.scheduleStartMinute = 0;
        Persistent.states.timer.pomodoro.scheduleEndMinute = 0;
        Persistent.states.timer.pomodoro.scheduleFocusSeconds = 0;
        Persistent.states.timer.pomodoro.scheduleBreakSeconds = 0;
        Persistent.states.timer.pomodoro.scheduleNoBreak = false;
        Persistent.states.timer.pomodoro.scheduleLongSession = false;
        Persistent.states.timer.pomodoro.scheduleLabel = "";
        Persistent.states.timer.pomodoro.scheduleDay = 0;
    }

    // Called by StudyScheduler when a block starts. focusSeconds/
    // breakSeconds override the user's normal pomodoro config for the
    // duration of the block; noBreak collapses it to a single continuous
    // focus lap with no break cycling. `meta` identifies which schedule
    // entry/date this session belongs to — see startScheduledSessionAt().
    // Starts a fresh lap right now; for resuming a block that already
    // started before this launch, use startScheduledSessionAt() instead.
    function startScheduledSession(focusSeconds, breakSeconds, noBreak, meta) {
        startScheduledSessionAt(focusSeconds, breakSeconds, noBreak, getCurrentTimeInSeconds(), meta);
    }

    // Same as startScheduledSession(), but resyncs to real elapsed time:
    // blockStartEpochSeconds is when the scheduled block actually began
    // (its start-of-day time, not "now"). If the shell launches partway
    // through a block — e.g. the block started at 3:40pm and the shell
    // comes up at 3:47pm — this works out which phase (focus or break,
    // possibly several cycles in) that 7 minutes lands in and starts the
    // timer already there, with 7 minutes already elapsed, instead of
    // restarting a fresh full-length lap.
    //
    // `meta` = { entryId, dateKey, startMinute, endMinute, label, day,
    // longSession }, all persisted to Persistent.states.timer.pomodoro so
    // StudyScheduler can identify and reconcile this session — including
    // across a shell restart, when it detects a persisted schedule*
    // marker that no longer matches what should currently be running
    // (see StudyScheduler.check()).
    //
    // Note: the resync math treats every break in the catch-up window as
    // a plain `breakSeconds` break — it doesn't account for the user's
    // normal long-break-every-N-cycles setting (Config.options.time.
    // pomodoro.longBreak/cyclesBeforeLongBreak), which scheduled blocks
    // don't use anyway. That only matters if a block ran long enough
    // uninterrupted to have hit several breaks before the shell launched
    // — a late-by-a-few-minutes restart (the common case) is unaffected.
    function startScheduledSessionAt(focusSeconds, breakSeconds, noBreak, blockStartEpochSeconds, meta) {
        Persistent.states.timer.pomodoro.scheduleEntryId = meta.entryId;
        Persistent.states.timer.pomodoro.scheduleDateKey = meta.dateKey;
        Persistent.states.timer.pomodoro.scheduleStartMinute = meta.startMinute;
        Persistent.states.timer.pomodoro.scheduleEndMinute = meta.endMinute;
        Persistent.states.timer.pomodoro.scheduleFocusSeconds = focusSeconds;
        Persistent.states.timer.pomodoro.scheduleBreakSeconds = noBreak ? 0 : breakSeconds;
        Persistent.states.timer.pomodoro.scheduleNoBreak = !!noBreak;
        Persistent.states.timer.pomodoro.scheduleLongSession = !!meta.longSession;
        Persistent.states.timer.pomodoro.scheduleLabel = meta.label;
        Persistent.states.timer.pomodoro.scheduleDay = meta.day;

        const now = getCurrentTimeInSeconds();
        const elapsed = Math.max(0, now - blockStartEpochSeconds);

        Persistent.states.timer.pomodoro.cycle = 0;

        if (noBreak) {
            // One continuous lap — elapsed maps directly onto it.
            Persistent.states.timer.pomodoro.isBreak = false;
            Persistent.states.timer.pomodoro.start = blockStartEpochSeconds;
        } else {
            const cycleLength = focusSeconds + breakSeconds;
            const elapsedInCycle = cycleLength > 0 ? (elapsed % cycleLength) : 0;
            if (elapsedInCycle < focusSeconds) {
                Persistent.states.timer.pomodoro.isBreak = false;
                Persistent.states.timer.pomodoro.start = now - elapsedInCycle;
            } else {
                Persistent.states.timer.pomodoro.isBreak = true;
                Persistent.states.timer.pomodoro.start = now - (elapsedInCycle - focusSeconds);
            }
        }

        // Set running + start directly rather than going through
        // togglePomodoro() — its "resume" branch recomputes start from
        // the *previous*, stale pomodoroSecondsLeft, which would clobber
        // the resynced start set just above.
        Persistent.states.timer.pomodoro.running = true;
        refreshPomodoro();
    }

    // Called by StudyScheduler when a block ends (or by refreshPomodoro
    // itself for a no-break lap that already finished on its own).
    // Stops the pomodoro if still running and restores normal
    // Config-driven focus/break behaviour for manual use.
    function endScheduledSession() {
        if (pomodoroRunning) {
            togglePomodoro();
        }
        root._clearScheduleState();
    }

    // Stopwatch
    function refreshStopwatch() {  // Stopwatch stores time in 10ms
        stopwatchTime = getCurrentTimeIn10ms() - stopwatchStart;
    }

    Timer {
        id: stopwatchTimer
        interval: 10
        running: root.stopwatchRunning
        repeat: true
        onTriggered: refreshStopwatch()
    }

    function toggleStopwatch() {
        if (root.stopwatchRunning)
            stopwatchPause();
        else
            stopwatchResume();
    }

    function stopwatchPause() {
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchResume() {
        if (stopwatchTime === 0) Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = true;
        Persistent.states.timer.stopwatch.start = getCurrentTimeIn10ms() - stopwatchTime;
    }

    function stopwatchReset() {
        stopwatchTime = 0;
        Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchRecordLap() {
        Persistent.states.timer.stopwatch.laps.push(stopwatchTime);
    }
}

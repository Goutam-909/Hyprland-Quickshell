pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick

// ── StudyScheduler ───────────────────────────────────────────────────────────
// Watches StudySchedule against real time, all the time (once instantiated —
// see the `load()` note below), regardless of whether any widget is open.
// It always reads StudySchedule.effectiveEntriesForDate(today) — the
// recurring weekly templates with that specific date's overrides
// (modified/skipped/one-off blocks) already applied — so edits made "just
// for this date" in the widget are respected without any extra handling
// here.
//
//   - notifyLeadMinutes before a block starts -> "starting soon" notification
//   - at block start                          -> starts TimerService's pomodoro
//                                                 using that block's own
//                                                 focus/break lengths (25/5,
//                                                 45/5 if longSession, or a
//                                                 single continuous lap if
//                                                 noBreak) via
//                                                 startScheduledSessionAt().
//                                                 If the block already
//                                                 started before this launch
//                                                 (e.g. shell comes up 7 min
//                                                 into a block), it resyncs
//                                                 to the correct phase and
//                                                 elapsed offset instead of
//                                                 restarting a fresh lap.
//   - at block end                            -> stops the pomodoro via
//                                                 endScheduledSession() and
//                                                 records the block in
//                                                 StudyLog for daily totals
//
// ── Reconciliation ──────────────────────────────────────────────────────────
// Every poll, `check()` works out `shouldBe`: the one enabled, in-window,
// not-yet-completed block that OUGHT to be driving the pomodoro right now
// (or null). It compares that against what's ACTUALLY driving it —
// Persistent.states.timer.pomodoro.scheduleEntryId/scheduleDateKey, which
// TimerService.startScheduledSessionAt() persists and survives a shell
// restart. Three cases fall out of that comparison:
//
//   1. Something's driving it but shouldn't be anymore -> stop it
//      (TimerService.endScheduledSession()). This is what fixes: toggling
//      a block off mid-session (it drops out of `shouldBe` immediately,
//      since disabled blocks are skipped), deleting/skipping it mid-
//      session, its window ending naturally, AND a stale session left
//      running from before a shell restart whose block no longer matches
//      (e.g. you disabled it, or the shell was closed for so long the
//      block's window has since passed). Logs the real elapsed time in
//      StudyLog either way, capped at the block's own scheduled length —
//      a manual disable/delete/edit mid-session still gets credited for
//      however long you actually studied, it's just tagged
//      "stopped-early" instead of "completed".
//   2. The right block is driving it, but its own settings changed
//      (time/cadence edited mid-session) -> resync: restart the pomodoro
//      with the new focus/break lengths, still anchored to the block's
//      real start time so elapsed time stays correct. This is what fixes
//      "editing mid-session doesn't take effect".
//   3. Nothing's driving it but something should be -> start it.
//
// Because all of this reads Persistent state rather than an in-memory
// cache, it's naturally restart-safe too: on the very first poll after a
// relaunch, whatever `scheduleEntryId` was left over from before the
// restart gets compared against `shouldBe` same as any other poll, and
// stopped/resynced/logged exactly as if the shell had never restarted at
// all — that's what fixes a toggled-off session still ticking away after
// a relaunch.
//
// IMPORTANT: like Wallpapers.qml / Updates.qml / LyricsService.qml in this
// project, this is a `pragma Singleton` and QML only instantiates singletons
// lazily, on first access. Call `StudyScheduler.load()` once from
// shell.qml's Component.onCompleted (next to the other `.load()` calls) so
// the poll timer below actually starts at shell startup instead of only
// when someone opens the schedule editor.
// ─────────────────────────────────────────────────────────────────────────────
Singleton {
    id: root

    property int notifyLeadMinutes: 5
    property int pollIntervalMs: 2000

    // Purely in-memory, fine to lose on restart — worst case a "starting
    // soon" notification fires once more than strictly necessary.
    property var _notifiedToday: ({})
    property int _lastDate: new Date().getDate()

    // No-op — its only job is to be a stable thing to call from
    // shell.qml so this singleton gets instantiated at startup.
    function load() {}

    function _minutesNow(d) {
        return d.getHours() * 60 + d.getMinutes()
    }

    function _resetDedupeIfNewDay(d) {
        if (d.getDate() !== root._lastDate) {
            root._lastDate = d.getDate()
            root._notifiedToday = {}
        }
    }

    function _epochForDateKeyMinute(dateKeyStr, minute) {
        const parts = dateKeyStr.split("-").map(Number)
        const midnight = new Date(parts[0], parts[1] - 1, parts[2], 0, 0, 0, 0)
        return Math.floor(midnight.getTime() / 1000) + minute * 60
    }

    function _metaFor(entry) {
        return {
            "entryId": entry.id, "dateKey": entry.ownerDateKey,
            "startMinute": entry.startMinute, "endMinute": entry.endMinute,
            "label": entry.label, "day": entry.day, "longSession": !!entry.longSession
        }
    }

    function check() {
        // Wait until StudyLog has loaded what's already on disk at least
        // once — otherwise the very first poll right after launch would
        // see an empty `entries` and could re-log something that actually
        // finished before this launch.
        if (!StudyLog.loaded) return

            const now = new Date()
            root._resetDedupeIfNewDay(now)

            const mins = root._minutesNow(now)
            // Today's own blocks, plus the tail of anything that started
            // yesterday and crosses into today. Each entry carries
            // ownerDateKey (the date it actually belongs to / is logged
            // under) and relativeStart/relativeEnd (shifted onto today's
            // 0-1439 clock, negative if it began yesterday) — see
            // StudySchedule.activeEntriesForDate().
            const todays = StudySchedule.activeEntriesForDate(now)

            // ── lead-time warnings ──
            for (const e of todays) {
                if (!e.enabled) continue
                    if (StudyLog.hasCompleted(e.id, e.ownerDateKey)) continue
                        const key = e.id + "-" + e.ownerDateKey
                        if (!root._notifiedToday[key]
                            && mins >= e.relativeStart - root.notifyLeadMinutes
                            && mins < e.relativeStart) {
                            root._notifiedToday[key] = true
                            Quickshell.execDetached([
                                "notify-send", "Study session soon",
                                `"${e.label}" starts in ${e.relativeStart - mins} min`,
                                "-a", "Shell"
                            ])
                            }
            }

            // What SHOULD be driving the pomodoro right now: enabled,
            // in-window (a block that started yesterday and hasn't hit its
            // real end time yet still counts), not already logged complete
            // under the date it actually belongs to.
            let shouldBe = null
            for (const e of todays) {
                if (!e.enabled) continue
                    if (StudyLog.hasCompleted(e.id, e.ownerDateKey)) continue
                        if (mins >= e.relativeStart && mins < e.relativeEnd) { shouldBe = e; break }
            }

            const p = Persistent.states.timer.pomodoro
            const isActivelyDriven = p.scheduleEntryId !== ""
            // Session identity is tracked by the block's OWNER date, not
            // "today" — that's what keeps a session matching itself across
            // a midnight rollover instead of looking like a stale leftover.
            const stillMatches = isActivelyDriven && shouldBe
            && p.scheduleEntryId === shouldBe.id && p.scheduleDateKey === shouldBe.ownerDateKey

            // ── 1. stop a session that's driving but shouldn't be anymore ──
            if (isActivelyDriven && !stillMatches) {
                const was = {
                    "id": p.scheduleEntryId, "dateKey": p.scheduleDateKey,
                    "day": p.scheduleDay, "label": p.scheduleLabel,
                    "startMinute": p.scheduleStartMinute, "endMinute": p.scheduleEndMinute,
                    "longSession": p.scheduleLongSession, "noBreak": p.scheduleNoBreak
                }
                TimerService.endScheduledSession()

                // Log real elapsed time from when the block actually
                // started, not just when it happens to have reached its
                // own scheduled end. Previously this only logged if
                // `nowEpoch >= blockEndEpoch` — so deleting, disabling, or
                // editing the entry even a minute before its scheduled end
                // silently dropped the ENTIRE session with zero minutes
                // credited, no matter how long you'd actually been
                // studying. Now every stopped session gets logged for
                // however long it really ran, capped at the block's own
                // scheduled length so a delayed poll can't overcredit it.
                // Still purely additive and still deduped by id+date, so
                // a session is only ever logged once, and later editing or
                // deleting the schedule entry can't touch or remove what
                // already got appended here.
                const blockStartEpoch = root._epochForDateKeyMinute(was.dateKey, was.startMinute)
                const nowEpoch = Math.floor(now.getTime() / 1000)
                const scheduledMinutes = was.endMinute - was.startMinute
                const elapsedMinutes = Math.max(0, Math.round((nowEpoch - blockStartEpoch) / 60))
                const minutesToLog = Math.min(elapsedMinutes, scheduledMinutes)
                const ranFullLength = minutesToLog >= scheduledMinutes

                if (minutesToLog > 0 && !StudyLog.hasCompleted(was.id, was.dateKey)) {
                    StudyLog.record(was, minutesToLog, was.dateKey, ranFullLength ? "completed" : "stopped-early")
                    Quickshell.execDetached([
                        "notify-send", "Study block done",
                        ranFullLength
                        ? `"${was.label}" has ended · ${StudyLog.formatDuration(minutesToLog)} logged`
                        : `"${was.label}" stopped early · ${StudyLog.formatDuration(minutesToLog)} logged`,
                                            "-a", "Shell"
                    ])
                }
            }

            // ── 2. resync a still-matching session whose own settings changed ──
            if (stillMatches) {
                const focusMinutes = StudySchedule.focusMinutesFor(shouldBe)
                const breakMinutes = StudySchedule.breakMinutes
                const focusSeconds = focusMinutes * 60
                const expectedNoBreak = StudySchedule.expectedNoBreakFor(shouldBe)
                const breakSeconds = expectedNoBreak ? 0 : breakMinutes * 60
                const changed = p.scheduleFocusSeconds !== focusSeconds
                || p.scheduleBreakSeconds !== breakSeconds
                || p.scheduleNoBreak !== expectedNoBreak
                || p.scheduleStartMinute !== shouldBe.startMinute
                || p.scheduleEndMinute !== shouldBe.endMinute

                if (changed) {
                    const blockStartEpochSeconds = root._epochForDateKeyMinute(shouldBe.ownerDateKey, shouldBe.startMinute)
                    TimerService.startScheduledSessionAt(focusSeconds, breakMinutes * 60, expectedNoBreak,
                                                         blockStartEpochSeconds, root._metaFor(shouldBe))
                    Quickshell.execDetached([
                        "notify-send", "Study block updated",
                        `"${shouldBe.label}" resynced to your edits`,
                        "-a", "Shell"
                    ])
                }
            }

            // ── 3. start a session that should be driving but isn't ──
            if (shouldBe && Persistent.states.timer.pomodoro.scheduleEntryId === "") {
                if (!TimerService.pomodoroRunning) {
                    const focusMinutes = StudySchedule.focusMinutesFor(shouldBe)
                    const breakMinutes = StudySchedule.breakMinutes
                    const expectedNoBreak = StudySchedule.expectedNoBreakFor(shouldBe)
                    const blockStartEpochSeconds = root._epochForDateKeyMinute(shouldBe.ownerDateKey, shouldBe.startMinute)
                    TimerService.startScheduledSessionAt(focusMinutes * 60, breakMinutes * 60, expectedNoBreak,
                                                         blockStartEpochSeconds, root._metaFor(shouldBe))
                    Quickshell.execDetached([
                        "notify-send", "Study time",
                        `Starting: ${shouldBe.label}`,
                        "-a", "Shell"
                    ])
                }
                // else: something else (a manual, non-scheduled pomodoro) is
                // already running — deliberately don't interrupt it. We'll
                // pick this block up as soon as that manual session ends.
            }
    }

    Timer {
        interval: root.pollIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
}

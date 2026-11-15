pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Append-only log of completed study blocks — one JSON object per line
 * (JSON Lines) in `studylog.jsonl`, so it stays easy to tail/grep or parse
 * from an external script too, and never needs a full rewrite-the-whole-
 * file save. This file is the single source of truth for "has this
 * specific occurrence of this block already been completed" — that's
 * what makes it safe to restart the shell without re-logging or
 * re-notifying for sessions that already finished.
 *
 * Each line looks like:
 *   {"id":"m4x2f9a1b","date":"2026-08-07","day":4,"label":"Physics",
 *    "startMinute":540,"endMinute":600,"scheduledStart":"9:00 AM",
 *    "scheduledEnd":"10:00 AM","minutes":60,"longSession":false,
 *    "noBreak":false,"status":"completed","completedAt":1754562000}
 *
 * `minutes` is the block's full scheduled duration — this counts break
 * time as part of a dedicated study block rather than trying to track
 * focus-only seconds, which keeps the log meaningful even if you
 * paused/resumed mid-block.
 *
 * A second, derived file — `studydaily.jsonl` — is rewritten (not
 * appended) every time a new session lands, and holds one clean,
 * human-friendly rollup line per calendar date: total minutes studied
 * that day, session count, and the list of blocks. That's the file to
 * read if you just want "how much did I study today / this week", the
 * per-session file above is the append-only raw record.
 */
Singleton {
    id: root
    property string filePath: Directories.studyLogPath
    property string dailyFilePath: Directories.studyDailyPath
    property var entries: []
    // Guards StudyScheduler against acting before the log has loaded at
    // least once after a shell (re)start — without this, the very first
    // poll after launch could run before `entries` reflects what's
    // already on disk and re-log/re-notify something that finished
    // before this launch.
    property bool loaded: false

    function _dateKey(d) {
        d = d || new Date()
        const mm = (d.getMonth() + 1).toString().padStart(2, "0")
        const dd = d.getDate().toString().padStart(2, "0")
        return d.getFullYear() + "-" + mm + "-" + dd
    }

    function todayKey() {
        return root._dateKey(new Date())
    }

    // Has this exact occurrence (schedule entry id, on this date) already
    // been logged as completed? This is the persisted check StudyScheduler
    // uses instead of its in-memory-only dedupe, so a shell relaunch after
    // a block already ended does NOT re-log or re-notify it.
    function hasCompleted(id, dateKey) {
        return root.entries.some(e => e.id === id && e.date === dateKey)
    }

    function record(entry, minutesStudied, dateKey, status) {
        dateKey = dateKey || root.todayKey()
        const line = JSON.stringify({
            "id": entry.id,
            "date": dateKey,
            "day": entry.day,
            "label": entry.label,
            "startMinute": entry.startMinute,
            "endMinute": entry.endMinute,
            "scheduledStart": StudySchedule.formatMinute(entry.startMinute),
            "scheduledEnd": StudySchedule.formatMinute(entry.endMinute),
            "minutes": minutesStudied,
            "longSession": !!entry.longSession,
            "noBreak": !!entry.noBreak,
            "status": status || "completed",
            "completedAt": Math.floor(Date.now() / 1000)
        })
        const dir = root.filePath.substring(0, root.filePath.lastIndexOf("/"))
        const escaped = line.replace(/'/g, "'\\''")
        appendProc.command = ["bash", "-c",
            "mkdir -p '" + dir + "' && printf '%s\\n' '" + escaped + "' >> '" + root.filePath + "'"
        ]
        appendProc.running = true
    }

    // Total minutes studied on a given Date (defaults to today).
    function minutesOn(d) {
        const key = root._dateKey(d)
        return root.entries.filter(e => e.date === key).reduce((sum, e) => sum + e.minutes, 0)
    }

    function minutesToday() {
        return root.minutesOn(new Date())
    }

    function formatDuration(mins) {
        const h = Math.floor(mins / 60)
        const m = Math.round(mins % 60)
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    // Rebuilds the organized daily rollup from `entries` and writes it
    // out. Cheap (this log is a handful of entries a day) and simplest
    // to just regenerate in full rather than patch in place.
    function _rebuildDailyRollup() {
        const byDate = {}
        for (const e of root.entries) {
            if (!byDate[e.date]) {
                byDate[e.date] = { "totalMinutes": 0, "totalFormatted": "", "sessions": 0, "blocks": [] }
            }
            byDate[e.date].totalMinutes += e.minutes
            byDate[e.date].sessions += 1
            byDate[e.date].blocks.push({
                "label": e.label,
                "start": e.scheduledStart ?? StudySchedule.formatMinute(e.startMinute),
                "end": e.scheduledEnd ?? StudySchedule.formatMinute(e.endMinute),
                "minutes": e.minutes,
                "status": e.status ?? "completed"
            })
        }
        for (const key of Object.keys(byDate)) {
            byDate[key].totalFormatted = root.formatDuration(byDate[key].totalMinutes)
        }
        dailyRollupView.setText(JSON.stringify(byDate, null, 2))
    }

    function refresh() {
        logFileView.reload()
    }

    Component.onCompleted: refresh()

    Process {
        id: appendProc
        running: false
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim() !== "")
                    console.warn("[StudyLog] failed to append:", line)
            }
        }
        // The append happens out-of-band via bash, so pull the file back
        // in once it's done to keep `entries` (and minutesToday(),
        // hasCompleted()) fresh, and regenerate the daily rollup.
        onExited: root.refresh()
    }

    FileView {
        id: logFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: logFileView.reload()
        onLoaded: {
            const text = logFileView.text()
            const lines = text.split("\n").filter(l => l.trim().length > 0)
            const parsed = []
            for (const l of lines) {
                try { parsed.push(JSON.parse(l)) } catch (e) { /* skip bad line */ }
            }
            root.entries = parsed
            root.loaded = true
            root._rebuildDailyRollup()
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                root.entries = []
                root.loaded = true
            } else {
                console.log("[StudyLog] Error loading file: " + error)
            }
        }
    }

    // Write-only view for the derived daily rollup — source of truth is
    // always `entries` (from logFileView above), this is regenerated
    // wholesale on every change rather than read back in.
    FileView {
        id: dailyRollupView
        path: Qt.resolvedUrl(root.dailyFilePath)
    }
}

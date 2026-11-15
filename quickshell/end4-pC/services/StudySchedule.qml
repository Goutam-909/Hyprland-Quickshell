pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Weekly study/time-table schedule — hybrid model.
 *
 * `list` holds recurring TEMPLATES, one per weekday pattern:
 *   {
 *     id:            string, generated
 *     day:           int, 0 = Sunday .. 6 = Saturday (matches JS Date.getDay())
 *     label:         string
 *     startMinute:   int, minutes since midnight (0-1439)
 *     endMinute:     int, minutes since midnight, must be > startMinute
 *     enabled:       bool
 *     longSession:   bool, 45 min focus / 5 min break instead of 25 / 5
 *                    (ignored when noBreak is true)
 *     noBreak:       bool, one continuous focus lap for the whole block,
 *                    no break cycling — duration can be any length
 *   }
 * A template recurs on that weekday every week, forever, until deleted.
 *
 * `overrides` holds per-date EXCEPTIONS, each tied to a specific calendar
 * date ("YYYY-MM-DD"), so editing/skipping one occurrence never touches
 * other weeks:
 *   {
 *     id:          string, generated ("ov-" prefixed)
 *     templateId:  string | null   — null means this override is a
 *                  standalone one-off block that exists only on `date`
 *                  and isn't tied to any recurring template
 *     date:        "YYYY-MM-DD"
 *     type:        "modify" | "skip" | "add"
 *       "modify" — replaces a template occurrence's fields on this date
 *                  only (label/startMinute/endMinute/longSession/
 *                  noBreak/enabled all present)
 *       "skip"   — removes a template occurrence on this date only
 *       "add"    — a standalone one-off block on this date (templateId
 *                  is null; label/startMinute/... all present)
 *   }
 *
 * effectiveEntriesForDate(date) merges templates + that date's overrides
 * into what should actually happen on that specific calendar day — that's
 * what StudyScheduler, and the widget's day view, should always read from.
 *
 * Persisted as plain JSON: { "templates": [...], "overrides": [...] }.
 * (Older files that were just a bare array of templates still load fine —
 * they're treated as templates with no overrides.)
 */
Singleton {
    id: root
    property var filePath: Directories.studySchedulePath
    property var list: []       // recurring templates
    property var overrides: []  // per-date exceptions

    // Display order is Monday-first (Mon→Sun). Note this is purely a
    // display-order array: the `day` field on templates/overrides still
    // follows JS Date.getDay() (0 = Sunday .. 6 = Saturday) everywhere
    // else in this file — anything indexing into these two arrays with a
    // raw .getDay() value needs (.getDay() + 6) % 7 instead.
    readonly property var dayNames: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    readonly property var dayShort: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    readonly property int minFocusMinutes: 25
    readonly property int breakMinutes: 5
    readonly property int longFocusMinutes: 45

    // Any positive duration is valid now — no more forced 25-min minimum
    // or multiple-of-5 requirement. What actually happens at runtime:
    //  - duration <= the cadence unit (25 min, or 45 with longSession):
    //    runs as one continuous focus lap for the whole block, same as
    //    an explicit "No break" block — there's no point starting the
    //    break-cycling machinery for something that'll never reach a
    //    break before the block ends anyway.
    //  - duration > the unit: cycles focus(unit)/break(5)/focus(unit)/...
    //    same as before, but the block's own end time is always what
    //    cuts the LAST leg short rather than requiring the total to
    //    divide evenly — e.g. a 47-min block runs 25 focus, 5 break,
    //    then a 17-min focus leg that just ends when the block does.
    //  - noBreak blocks: same as always, one continuous lap for the
    //    exact block length, any duration.
    // See expectedNoBreakFor()/focusMinutesFor() below — StudyScheduler
    // uses those, not this duration, to decide how to actually drive it.
    function isValidDuration(startMinute, endMinute, noBreak) {
        // Equal start/end is the only real invalid case (zero length).
        // endMinute < startMinute is NOT invalid — it means the block
        // runs past midnight into the next day. Storage always keeps
        // endMinute > startMinute by adding 1440 for a crossing block
        // (see SidebarStudySchedule.save()); this just validates the
        // clock values the person actually typed, before that shift.
        return endMinute !== startMinute
    }

    // Whether this entry should run as one continuous focus lap at
    // runtime — either because "No break" was explicitly toggled, or
    // because the block's own duration is short enough that a single
    // cadence unit (25/45 min) would never even reach a break before the
    // block ends anyway.
    function expectedNoBreakFor(entry) {
        if (entry.noBreak) return true
            const unit = entry.longSession ? root.longFocusMinutes : root.minFocusMinutes
            const duration = entry.endMinute - entry.startMinute
            return duration <= unit
    }

    function focusMinutesFor(entry) {
        if (root.expectedNoBreakFor(entry)) return entry.endMinute - entry.startMinute
            return entry.longSession ? root.longFocusMinutes : root.minFocusMinutes
    }

    function dateKeyFor(d) {
        if (!d) d = new Date()
            const mm = (d.getMonth() + 1).toString().padStart(2, "0")
            const dd = d.getDate().toString().padStart(2, "0")
            return d.getFullYear() + "-" + mm + "-" + dd
    }

    function _save() {
        // Reassign to trigger change notification for anything bound to
        // root.list / root.overrides.
        root.list = list.slice(0)
        root.overrides = overrides.slice(0)
        scheduleFileView.setText(JSON.stringify({ "templates": root.list, "overrides": root.overrides }))
    }

    function _genId() {
        return Date.now().toString(36) + Math.random().toString(36).slice(2, 7)
    }

    function _genOverrideId() {
        return "ov-" + Date.now().toString(36) + Math.random().toString(36).slice(2, 7)
    }

    // ── Templates (recurring, every week) ──────────────────────────────
    function addEntry(day, label, startMinute, endMinute, longSession, noBreak) {
        list.push({
            "id": root._genId(),
                  "day": day,
                  "label": label,
                  "startMinute": startMinute,
                  "endMinute": endMinute,
                  "enabled": true,
                  "longSession": !!longSession,
                  "noBreak": !!noBreak
        })
        root._save()
    }

    // Edits the template itself — affects every week, past overrides for
    // other dates are untouched.
    function updateEntry(id, patch) {
        const idx = list.findIndex(e => e.id === id)
        if (idx === -1) return
            list[idx] = Object.assign({}, list[idx], patch)
            root._save()
    }

    function toggleEnabled(id) {
        const idx = list.findIndex(e => e.id === id)
        if (idx === -1) return
            list[idx].enabled = !list[idx].enabled
            root._save()
    }

    // Like toggleEnabled(), but for an entry object returned from
    // effectiveEntriesForDate() rather than a raw template id. A plain
    // recurring entry toggles the template (every week); a standalone
    // one-off or a "just this date" modification toggles that override
    // instead, so it doesn't silently no-op trying to find a template
    // that doesn't exist (standalone) or affect every other week when
    // you only meant to disable one date (modified).
    function toggleEnabledForEffectiveEntry(entry) {
        if (entry.isOverride) {
            root.updateOverride(entry.overrideId, { "enabled": !entry.enabled })
        } else {
            root.toggleEnabled(entry.id)
        }
    }

    // Deletes a recurring template entirely (every week, going forward)
    // and cleans up any per-date overrides that referenced it.
    function deleteTemplate(id) {
        const idx = list.findIndex(e => e.id === id)
        if (idx !== -1) list.splice(idx, 1)
            root.overrides = root.overrides.filter(o => o.templateId !== id)
            root._save()
    }

    function entriesForDay(day) {
        return list.filter(e => e.day === day).sort((a, b) => a.startMinute - b.startMinute)
    }

    // ── Per-date overrides ───────────────────────────────────────────────
    // Modify a single occurrence of a recurring template, only for one date.
    function overrideModify(templateId, date, patch) {
        const dateKey = root.dateKeyFor(date)
        root.overrides = root.overrides.filter(o => !(o.templateId === templateId && o.date === dateKey))
        root.overrides.push(Object.assign({
            "id": root._genOverrideId(),
                                          "templateId": templateId,
                                          "date": dateKey,
                                          "type": "modify"
        }, patch))
        root._save()
    }

    // Skip a single occurrence of a recurring template for one date —
    // supersedes any existing modify override for that template+date.
    function overrideSkip(templateId, date) {
        const dateKey = root.dateKeyFor(date)
        root.overrides = root.overrides.filter(o => !(o.templateId === templateId && o.date === dateKey))
        root.overrides.push({
            "id": root._genOverrideId(),
                            "templateId": templateId,
                            "date": dateKey,
                            "type": "skip"
        })
        root._save()
    }

    // A one-off block that exists only on this date, not tied to any
    // recurring template.
    function addOneOff(date, label, startMinute, endMinute, longSession, noBreak) {
        const dateKey = root.dateKeyFor(date)
        root.overrides.push({
            "id": root._genOverrideId(),
                            "templateId": null,
                            "date": dateKey,
                            "type": "add",
                            "label": label,
                            "startMinute": startMinute,
                            "endMinute": endMinute,
                            "enabled": true,
                            "longSession": !!longSession,
                            "noBreak": !!noBreak
        })
        root._save()
    }

    // Edits an existing override in place — used for a standalone one-off,
    // or to re-edit a "just this date" modification.
    function updateOverride(overrideId, patch) {
        const idx = overrides.findIndex(o => o.id === overrideId)
        if (idx === -1) return
            overrides[idx] = Object.assign({}, overrides[idx], patch)
            root._save()
    }

    // Removes an override: a "modify" reverts that date back to the plain
    // template; an "add" just deletes the one-off block. ("skip" overrides
    // are normally replaced via overrideSkip/overrideModify rather than
    // removed, but this works for that too if ever needed.)
    function removeOverride(overrideId) {
        root.overrides = root.overrides.filter(o => o.id !== overrideId)
        root._save()
    }

    // What should actually happen on this specific calendar date: that
    // weekday's templates, with the date's overrides applied (modified /
    // skipped / added). This is what StudyScheduler and the widget's day
    // view should always read from — never entriesForDay() directly, or
    // per-date overrides get silently ignored.
    function effectiveEntriesForDate(date) {
        if (!date) date = new Date()
            const dateKey = root.dateKeyFor(date)
            const weekday = date.getDay()
            const templates = root.entriesForDay(weekday)
            const overridesForDate = root.overrides.filter(o => o.date === dateKey)

            const skipSet = {}
            overridesForDate.filter(o => o.type === "skip").forEach(o => { skipSet[o.templateId] = true })
            const modifyMap = {}
            overridesForDate.filter(o => o.type === "modify").forEach(o => { modifyMap[o.templateId] = o })

            const result = []
            for (const t of templates) {
                if (skipSet[t.id]) continue
                    const o = modifyMap[t.id]
                    if (o) {
                        result.push(Object.assign({}, t, {
                            "label": o.label, "startMinute": o.startMinute, "endMinute": o.endMinute,
                            "longSession": o.longSession, "noBreak": o.noBreak, "enabled": o.enabled,
                            "isOverride": true, "overrideId": o.id, "templateId": t.id, "standalone": false
                        }))
                    } else {
                        result.push(Object.assign({}, t, { "isOverride": false, "templateId": t.id, "standalone": false }))
                    }
            }
            overridesForDate.filter(o => o.type === "add").forEach(o => {
                result.push({
                    "id": o.id, "templateId": null, "day": weekday,
                    "label": o.label, "startMinute": o.startMinute, "endMinute": o.endMinute,
                    "enabled": o.enabled, "longSession": o.longSession, "noBreak": o.noBreak,
                    "isOverride": true, "overrideId": o.id, "standalone": true
                })
            })
            return result.sort((a, b) => a.startMinute - b.startMinute)
    }

    // Entries that started on the PREVIOUS calendar date and run past
    // midnight into `date` (stored endMinute >= 1440). Kept with their
    // ORIGINAL startMinute/endMinute (so formatMinute() keeps showing
    // their real clock time, e.g. "11:00 PM – 1:00 AM"), plus:
    //   ownerDateKey   — the date this block actually belongs to / is
    //                    logged under (yesterday, not today)
    //   relativeStart / relativeEnd — start/end shifted onto TODAY's
    //                    0-1439 clock (relativeStart negative), for
    //                    sorting and for comparing against "now"
    //   carriedFromPrevDay — true, so callers can label it distinctly
    //                    from a block that starts today and runs into
    //                    tomorrow
    function crossMidnightEntriesInto(date) {
        if (!date) date = new Date()
            const prevDate = new Date(date)
            prevDate.setDate(date.getDate() - 1)
            const ownerDateKey = root.dateKeyFor(prevDate)
            const prevEntries = root.effectiveEntriesForDate(prevDate)
            return prevEntries
            .filter(e => e.endMinute >= 1440)
            .map(e => Object.assign({}, e, {
                "ownerDateKey": ownerDateKey,
                "relativeStart": e.startMinute - 1440,
                "relativeEnd": e.endMinute - 1440,
                "carriedFromPrevDay": true
            }))
    }

    // Everything actually relevant to `date` for "what's happening right
    // now" / live-tracking purposes: that date's own entries, plus the
    // tail of anything carried over from the day before. This is what
    // StudyScheduler.check() and any "current/live" view should read —
    // effectiveEntriesForDate() alone doesn't know about the part of an
    // overnight block that lands on the following day.
    function activeEntriesForDate(date) {
        if (!date) date = new Date()
            const ownerDateKey = root.dateKeyFor(date)
            const own = root.effectiveEntriesForDate(date).map(e => Object.assign({}, e, {
                "ownerDateKey": ownerDateKey,
                "relativeStart": e.startMinute,
                "relativeEnd": e.endMinute,
                "carriedFromPrevDay": false
            }))
            return own.concat(root.crossMidnightEntriesInto(date))
            .sort((a, b) => a.relativeStart - b.relativeStart)
    }

    function minutesNow(d) {
        return d.getHours() * 60 + d.getMinutes()
    }

    // The block that's running right now, or null. Uses activeEntriesForDate
    // so a block that started yesterday and hasn't hit its end time yet
    // still shows as current after midnight.
    function currentEntry() {
        const now = new Date()
        const mins = root.minutesNow(now)
        const todays = root.activeEntriesForDate(now).filter(e => e.enabled)
        for (const e of todays) {
            if (mins >= e.relativeStart && mins < e.relativeEnd) return e
        }
        return null
    }

    // Up to `limit` upcoming blocks: rest of today first, then tomorrow.
    // Each returned entry is tagged with a `dayLabel` of "Today" or "Tomorrow".
    function upcomingEntries(limit) {
        limit = limit || 4
        const now = new Date()
        const mins = root.minutesNow(now)
        const result = []

        const todays = root.effectiveEntriesForDate(now).filter(e => e.enabled && e.startMinute > mins)
        for (const e of todays) {
            if (result.length >= limit) break
                result.push(Object.assign({}, e, { "dayLabel": "Today" }))
        }

        if (result.length < limit) {
            const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000)
            const tomorrows = root.effectiveEntriesForDate(tomorrow).filter(e => e.enabled)
            for (const e of tomorrows) {
                if (result.length >= limit) break
                    result.push(Object.assign({}, e, { "dayLabel": "Tomorrow" }))
            }
        }

        return result
    }

    // m can be >= 1440 for a block that crosses midnight (storage keeps
    // endMinute > startMinute by adding a full day rather than wrapping),
    // so normalize to a 0-23 hour before formatting.
    function formatMinute(m) {
        const h = Math.floor(m / 60) % 24
        const mm = m % 60
        const period = h < 12 ? "AM" : "PM"
        let h12 = h % 12
        if (h12 === 0) h12 = 12
            return h12 + ":" + (mm < 10 ? "0" + mm : mm) + " " + period
    }

    function refresh() {
        scheduleFileView.reload()
    }

    Component.onCompleted: refresh()

    FileView {
        id: scheduleFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            try {
                const parsed = JSON.parse(scheduleFileView.text())
                if (Array.isArray(parsed)) {
                    // Old format: bare array of templates, no overrides yet.
                    root.list = parsed
                    root.overrides = []
                } else {
                    root.list = parsed.templates || []
                    root.overrides = parsed.overrides || []
                }
            } catch (e) {
                console.log("[StudySchedule] Failed to parse file, starting empty:", e)
                root.list = []
                root.overrides = []
            }
            console.log("[StudySchedule] File loaded")
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                console.log("[StudySchedule] File not found, creating new file.")
                root.list = []
                root.overrides = []
                scheduleFileView.setText(JSON.stringify({ "templates": root.list, "overrides": root.overrides }))
            } else {
                console.log("[StudySchedule] Error loading file: " + error)
            }
        }
    }
}

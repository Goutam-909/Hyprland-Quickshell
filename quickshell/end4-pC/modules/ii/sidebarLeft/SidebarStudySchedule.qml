pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    readonly property var dayNames: StudySchedule.dayNames
    readonly property var dayShort: StudySchedule.dayShort
    readonly property var monthShort: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    // One distinct Material shape per weekday (Mon→Sun) so each day in the
    // strip has its own identity instead of 7 identical pills. Kept subtle
    // (small + dim) when not selected — see the day-picker delegate below —
    // so only the selected day's shape actually stands out.
    readonly property var dayShapes: [
        MaterialShape.Shape.Sunny, MaterialShape.Shape.Cookie4Sided, MaterialShape.Shape.Pentagon,
        MaterialShape.Shape.Gem, MaterialShape.Shape.Cookie6Sided, MaterialShape.Shape.Clover4Leaf,
        MaterialShape.Shape.Cookie9Sided
    ]

    // ── Week navigation — real calendar dates, not a perpetual "this
    // week", so Prev/Next/Today actually move you between weeks instead
    // of always snapping back to whatever week contains today.
    property var viewWeekStart: root._startOfWeek(new Date())
    property var weekDates: root._computeWeekDates(root.viewWeekStart)
    property int selectedDayIndex: (new Date().getDay() + 6) % 7
    property var selectedDate: (root.selectedDayIndex >= 0 && root.selectedDayIndex < root.weekDates.length)
    ? root.weekDates[root.selectedDayIndex]
    : root.weekDates[(new Date().getDay() + 6) % 7]
    property var dayEntries: []

    function _startOfWeek(d) {
        const copy = new Date(d)
        copy.setHours(0, 0, 0, 0)
        copy.setDate(copy.getDate() - ((copy.getDay() + 6) % 7)) // back up to Monday
        return copy
    }
    function _computeWeekDates(weekStart) {
        const dates = []
        for (let i = 0; i < 7; i++) {
            const d = new Date(weekStart)
            d.setDate(weekStart.getDate() + i)
            dates.push(d)
        }
        return dates
    }
    function _addDays(d, n) {
        const copy = new Date(d)
        copy.setDate(copy.getDate() + n)
        return copy
    }
    function goToPrevWeek() {
        root.viewWeekStart = root._addDays(root.viewWeekStart, -7)
        root.weekDates = root._computeWeekDates(root.viewWeekStart)
    }
    function goToNextWeek() {
        root.viewWeekStart = root._addDays(root.viewWeekStart, 7)
        root.weekDates = root._computeWeekDates(root.viewWeekStart)
    }
    function goToThisWeek() {
        root.viewWeekStart = root._startOfWeek(new Date())
        root.weekDates = root._computeWeekDates(root.viewWeekStart)
        root.selectedDayIndex = (new Date().getDay() + 6) % 7
    }
    function formatDateShort(d) {
        return root.monthShort[d.getMonth()] + " " + d.getDate()
    }
    function weekRangeLabel() {
        return root.formatDateShort(root.weekDates[0]) + " – " + root.formatDateShort(root.weekDates[6])
    }
    function isViewingThisWeek() {
        const thisWeekStart = root._startOfWeek(new Date())
        return root.viewWeekStart.getTime() === thisWeekStart.getTime()
    }
    // Past dates are history, not something to edit — you can only
    // remove an occurrence from them, not change its time/label/repeat.
    function isPastDate(d) {
        const today0 = new Date()
        today0.setHours(0, 0, 0, 0)
        const cmp = new Date(d)
        cmp.setHours(0, 0, 0, 0)
        return cmp.getTime() < today0.getTime()
    }

    function refresh() {
        root.dayEntries = StudySchedule.activeEntriesForDate(root.selectedDate)
    }

    onSelectedDateChanged: root.refresh()
    Component.onCompleted: root.refresh()

    Connections {
        target: StudySchedule
        function onListChanged() { root.refresh() }
        function onOverridesChanged() { root.refresh() }
    }

    // ── Weekly study-log summary (bottom panel) ───────────────────────────
    // Sourced from StudyLog (actually-completed blocks), not StudySchedule
    // (what's planned) — deliberately independent of selectedDate/showForm
    // so it always reflects the same 7-day window as the week strip above.
    readonly property var logWeekMinutes: root.weekDates.map(d => StudyLog.minutesOn(d))
    readonly property int logWeekTotal: root.logWeekMinutes.reduce((sum, m) => sum + m, 0)
    readonly property int logWeekMax: Math.max(1, ...root.logWeekMinutes)

    // ── Add / edit form state ────────────────────────────────────────────
    property bool showForm: false
    property var editingId: null
    property bool editIsStandalone: false
    property var editTemplateId: null
    property var editOverrideId: null
    property bool justThisDate: false
    property bool editEnabled: true
    // The date an edit/delete should actually apply to. Normally
    // selectedDate, but for an entry carried in from yesterday (viewed
    // on today's list because it runs past midnight), this is set back
    // one day so "just this date" / delete-occurrence act on the date
    // the block actually started, not the day you happened to view it.
    property var editDate: null

    property string labelInput: ""
    property int startMinute: 9 * 60
    property int endMinute: 10 * 60
    property bool longSession: false
    property bool noBreak: false

    // Current wall-clock time as minutes-since-midnight, rounded to the
    // nearest 5 minutes so the Start field lands on a tidy value instead
    // of something like 9:47.
    function _currentMinuteOfDay() {
        const d = new Date()
        const raw = d.getHours() * 60 + d.getMinutes()
        return Math.round(raw / 5) * 5 % 1440
    }

    function resetForm() {
        root.editingId = null
        root.editIsStandalone = false
        root.editTemplateId = null
        root.editOverrideId = null
        root.justThisDate = true
        root.editEnabled = true
        root.editDate = null
        root.labelInput = ""
        root.startMinute = 9 * 60
        root.endMinute = 10 * 60
        root.longSession = false
        root.noBreak = false
    }

    function formValid() {
        if (root.labelInput.trim().length === 0) return false
            return StudySchedule.isValidDuration(root.startMinute, root.endMinute, root.noBreak)
    }

    // Deliberately no cross-adjustment here — Start and End are each just
    // set to exactly what was typed/spun. If End ends up at or before
    // Start, that's not an error to silently "fix": it means the block
    // runs past midnight into the next day (handled in save()/formValid()
    // below), so nudging the other field around behind the person's back
    // would just be wrong.
    function setStart(newStart) {
        root.startMinute = newStart
    }
    function setEnd(newEnd) {
        root.endMinute = newEnd
    }

    function hour12Of(m) { const h = Math.floor(m / 60) % 24; let h12 = h % 12; if (h12 === 0) h12 = 12; return h12 }
    function minutePartOf(m) { return m % 60 }
    function isPMOf(m) { return Math.floor(m / 60) % 24 >= 12 }
    function withHour12(m, h12, isPM) { let h = h12 % 12; if (isPM) h += 12; return h * 60 + (m % 60) }
    function withMinutePart(m, mm) { return Math.floor(m / 60) * 60 + mm }
    function withAmPm(m, isPM) {
        const h = Math.floor(m / 60) % 24
        const isCurrentlyPM = h >= 12
        if (isCurrentlyPM === isPM) return m
            return m + (isPM ? 12 * 60 : -12 * 60)
    }

    // Sibling of TimeChip (inline components must be top-level, not
    // nested inside another component's children) — one hour/minute
    // stepper column: up arrow, editable number, down arrow.
    component TimeStepper: ColumnLayout {
        id: stepperRoot
        required property string valueText
        required property var onBump // function(delta)
        required property var onCommit // function(text)
        spacing: 0

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 16
            buttonRadius: Appearance.rounding.small
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer1Hover
            colRipple: Appearance.colors.colLayer1Active
            downAction: () => stepperRoot.onBump(1)
            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                iconSize: 14
                color: Appearance.colors.colSubtext
                text: "keyboard_arrow_up"
            }
        }

        StyledTextInput {
            id: valueInput
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 22
            horizontalAlignment: TextInput.AlignHCenter
            text: stepperRoot.valueText
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer0
            maximumLength: 2
            selectByMouse: true
            validator: IntValidator { bottom: 0; top: 59 }
            onEditingFinished: {
                stepperRoot.onCommit(text)
                // Typing directly into this field breaks its declarative
                // binding to stepperRoot.valueText (normal QML behavior
                // for TextInput) — resync explicitly so a rejected or
                // out-of-range entry snaps back to the real value instead
                // of just sitting there wrong.
                text = stepperRoot.valueText
            }
        }
        Connections {
            target: stepperRoot
            // Also resync after the +/- steppers change the value from
            // outside — without this, once the binding above has been
            // broken by a single manual edit, the up/down arrows would
            // silently stop updating what's displayed.
            function onValueTextChanged() {
                if (!valueInput.activeFocus) valueInput.text = stepperRoot.valueText
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 16
            buttonRadius: Appearance.rounding.small
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer1Hover
            colRipple: Appearance.colors.colLayer1Active
            downAction: () => stepperRoot.onBump(-1)
            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                iconSize: 14
                color: Appearance.colors.colSubtext
                text: "keyboard_arrow_down"
            }
        }
    }

    // A compact Material "pill" for a single Start/End time — replaces
    // the old pair of raw QtQuick SpinBoxes (which had their own fixed
    // OS-default width and just sat there leaving a dead gap next to
    // them). This has a natural, content-sized width, so two side by
    // side in a Flow read as a balanced pair, and if the sidebar gets
    // narrow enough they wrap onto their own line instead of squeezing.
    component TimeChip: Rectangle {
        id: chip
        required property string chipLabel
        required property int totalMinute
        required property var onSet // function(newTotalMinute)

        implicitWidth: 164
        implicitHeight: 68
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2

        readonly property int hour12: root.hour12Of(chip.totalMinute)
        readonly property int minutePart: root.minutePartOf(chip.totalMinute)
        readonly property bool isPM: root.isPMOf(chip.totalMinute)

        function bumpHour(delta) {
            let h = chip.hour12 + delta
            if (h > 12) h = 1
                if (h < 1) h = 12
                    chip.onSet(root.withHour12(chip.totalMinute, h, chip.isPM))
        }
        function bumpMinute(delta) {
            let m = chip.minutePart + delta
            if (m > 59) m = 0
                if (m < 0) m = 59
                    chip.onSet(root.withMinutePart(chip.totalMinute, m))
        }
        function commitHourText(text) {
            const n = parseInt(text, 10)
            if (!isNaN(n) && n >= 1 && n <= 12) chip.onSet(root.withHour12(chip.totalMinute, n, chip.isPM))
        }
        function commitMinuteText(text) {
            const n = parseInt(text, 10)
            if (!isNaN(n) && n >= 0 && n <= 59) chip.onSet(root.withMinutePart(chip.totalMinute, n))
        }

        ColumnLayout {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 }
            spacing: 2

            StyledText {
                text: chip.chipLabel
                font.pixelSize: Appearance.font.pixelSize.smaller
                opacity: 0.65
                color: Appearance.colors.colOnLayer0
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                TimeStepper {
                    valueText: chip.hour12.toString()
                    onBump: (delta) => chip.bumpHour(delta)
                    onCommit: (text) => chip.commitHourText(text)
                }
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: ":"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }
                TimeStepper {
                    valueText: chip.minutePart.toString().padStart(2, "0")
                    onBump: (delta) => chip.bumpMinute(delta)
                    onCommit: (text) => chip.commitMinuteText(text)
                }

                Item { Layout.fillWidth: true }

                RippleButton {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 38; implicitHeight: 26
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    downAction: () => chip.onSet(root.withAmPm(chip.totalMinute, !chip.isPM))
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: chip.isPM ? "PM" : "AM"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    }

    // Same RippleButton everyone already uses (ripple + radius morph),
    // with a spring-in press bounce layered on top via the existing-but-
    // unused Appearance.animation.clickBounce token — squashes down on
    // press, springs back past 1.0 on release, instead of just snapping.
    component BouncyRippleButton: RippleButton {
        id: bouncyRoot
        scale: bouncyRoot.down ? 0.93 : 1.0
        Behavior on scale {
            animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
        }
    }

    // A genuine Material 3 Expressive polygon (MaterialShapeWrappedMaterialSymbol)
    // standing in for a RippleButton where a small icon-only action lives —
    // edit/delete, add/close. ShapeCanvas already morphs between shapes on
    // its own (see MaterialShape.qml), so swapping `shape` at the call site
    // is enough to get a fluid shape-shift for free; this just layers hover
    // pop + press-bounce feedback on top, the same spring used above.
    component ShapedIconButton: MaterialShapeWrappedMaterialSymbol {
        id: shapedBtn
        signal clicked()
        property bool down: false
        property bool hovered: false
        scale: shapedBtn.down ? 0.85 : (shapedBtn.hovered ? 1.06 : 1.0)
        Behavior on scale {
            animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: shapedBtn.hovered = true
            onExited: shapedBtn.hovered = false
            onPressed: shapedBtn.down = true
            onReleased: {
                shapedBtn.down = false
                if (containsMouse) shapedBtn.clicked()
            }
            onCanceled: shapedBtn.down = false
        }
    }

    function openNew() {
        root.resetForm()
        // Default Start to right now (rounded to the nearest 5 min)
        // instead of the fixed 9:00 fallback used elsewhere — End follows
        // one hour later, wrapped back into a plain 0-1439 clock value;
        // save() handles it correctly even if that wraps past midnight.
        root.startMinute = root._currentMinuteOfDay()
        root.endMinute = (root.startMinute + 60) % 1440
        root.editDate = root.selectedDate
        root.showForm = true
    }
    function openEdit(entry) {
        root.editingId = entry.id
        root.editIsStandalone = !!entry.standalone
        root.editTemplateId = entry.templateId ?? entry.id
        root.editOverrideId = entry.overrideId ?? null
        root.justThisDate = !!entry.standalone
        root.editEnabled = entry.enabled !== false
        // A carried-over entry is shown on today's list but actually
        // belongs to yesterday — edits/deletes need to target that date.
        if (entry.carriedFromPrevDay) {
            const d = new Date(root.selectedDate)
            d.setDate(d.getDate() - 1)
            root.editDate = d
        } else {
            root.editDate = root.selectedDate
        }
        root.labelInput = entry.label
        root.startMinute = entry.startMinute
        // Stored endMinute may be >= 1440 for a block that crosses
        // midnight — fold it back to a plain 0-1439 clock value for the
        // Start/End spinboxes; save() re-adds the day if it still crosses.
        root.endMinute = entry.endMinute % 1440
        root.longSession = !!entry.longSession
        root.noBreak = !!entry.noBreak
        root.showForm = true
    }
    function closeForm() {
        root.resetForm()
        root.showForm = false
    }

    function save() {
        // Force any Start/End hour-or-minute field that's still being
        // typed into to lose focus *before* we read startMinute/endMinute.
        // TextInput only commits what you typed on Enter or on losing
        // focus (see TimeStepper's onEditingFinished above) — clicking
        // Save doesn't reliably do that on its own, so without this a
        // value you'd just typed could still be sitting uncommitted and
        // get silently dropped. This makes Save always commit it first,
        // instead of relying on you touching another field (like AM/PM)
        // to force the same thing as a side effect.
        root.forceActiveFocus()
        if (!root.formValid()) return
            // End at or before Start means it runs past midnight — store it
            // as +1 day so downstream duration math (end - start) stays
            // correct, without ever touching what the person typed for Start.
            const crossesMidnight = root.endMinute <= root.startMinute
            const savedEnd = crossesMidnight ? root.endMinute + 1440 : root.endMinute
            const targetDate = root.editDate || root.selectedDate
            const patch = {
                "label": root.labelInput, "startMinute": root.startMinute, "endMinute": savedEnd,
                "longSession": root.longSession, "noBreak": root.noBreak, "enabled": root.editEnabled
            }
            if (!root.editingId) {
                if (root.justThisDate) {
                    StudySchedule.addOneOff(targetDate, root.labelInput, root.startMinute,
                                            savedEnd, root.longSession, root.noBreak)
                } else {
                    StudySchedule.addEntry(targetDate.getDay(), root.labelInput,
                                           root.startMinute, savedEnd, root.longSession, root.noBreak)
                }
            } else if (root.editIsStandalone) {
                StudySchedule.updateOverride(root.editOverrideId, patch)
            } else if (root.justThisDate) {
                StudySchedule.overrideModify(root.editTemplateId, targetDate, patch)
            } else {
                StudySchedule.updateEntry(root.editTemplateId, patch)
            }
            root.closeForm()
            root.refresh()
    }

    function deleteOccurrence(entry) {
        const targetDate = entry.carriedFromPrevDay
        ? (() => { const d = new Date(root.selectedDate); d.setDate(d.getDate() - 1); return d })()
        : root.selectedDate
        if (entry.standalone) StudySchedule.removeOverride(entry.overrideId)
            else StudySchedule.overrideSkip(entry.templateId, targetDate)
                root.refresh()
    }
    function deleteSeries() {
        if (!root.editTemplateId) return
            StudySchedule.deleteTemplate(root.editTemplateId)
            root.closeForm()
            root.refresh()
    }

    // ── UI ──────────────────────────────────────────────────────────────
    Rectangle {
        id: background
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: -1
        anchors.bottomMargin: 4
        radius: Appearance.rounding.normal
        color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.9)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.height * 0.04
            spacing: 10

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialShapeWrappedMaterialSymbol {
                    shape: MaterialShape.Shape.Clover4Leaf
                    color: Appearance.colors.colPrimaryContainer
                    colSymbol: Appearance.colors.colPrimary
                    text: "calendar_month"
                    iconSize: Appearance.font.pixelSize.large
                    fill: 1
                    padding: 7
                    implicitWidth: 38
                    implicitHeight: 38
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Study schedule")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                }
                // Genuinely morphs shape (not just corner radius) between an
                // inviting "add" burst and a tighter "close" shape, and
                // rotates a quarter turn as it does — the ShapeCanvas morph
                // + rotation together read as one deliberate transformation.
                ShapedIconButton {
                    id: addCloseButton
                    implicitWidth: 40; implicitHeight: 40
                    shape: root.showForm ? MaterialShape.Shape.Clover4Leaf : MaterialShape.Shape.Sunny
                    enabled: root.showForm || !root.isPastDate(root.selectedDate)
                    opacity: enabled ? 1 : 0.4
                    color: root.showForm ? ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.7) : Appearance.colors.colPrimary
                    colSymbol: root.showForm ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
                    text: root.showForm ? "close" : "add"
                    iconSize: 20
                    fill: 1
                    padding: 9
                    rotation: root.showForm ? 90 : 0
                    onClicked: { if (root.showForm) root.closeForm(); else root.openNew() }

                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }
            }

            // ── Week navigation ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: !root.showForm

                BouncyRippleButton {
                    implicitWidth: 26; implicitHeight: 26
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    downAction: () => root.goToPrevWeek()
                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        text: "chevron_left"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer0
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.weekRangeLabel()
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    opacity: 0.75
                }

                BouncyRippleButton {
                    implicitWidth: 26; implicitHeight: 26
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    downAction: () => root.goToNextWeek()
                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        text: "chevron_right"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer0
                    }
                }

                BouncyRippleButton {
                    visible: !root.isViewingThisWeek()
                    implicitWidth: 52; implicitHeight: 26
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    downAction: () => root.goToThisWeek()
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Today")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            // ── Day picker: 7 pill/circle shapes, morphing like the play button ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: -2
                spacing: 4
                visible: !root.showForm

                Repeater {
                    model: root.weekDates
                    // Not a RippleButton — the shape itself IS the button
                    // background (ShapeCanvas doesn't fit RippleButton's
                    // rectangular ripple mask), so this is a plain Item
                    // with its own MouseArea, following MediaWidget's
                    // shaped-icon pattern.
                    delegate: Item {
                        id: dayButton
                        required property var modelData
                        required property int index
                        readonly property bool isSelected: index === root.selectedDayIndex
                        readonly property bool isToday: root.isViewingThisWeek() && index === (new Date().getDay() + 6) % 7
                        readonly property var dayShape: root.dayShapes[dayButton.index]
                        Layout.fillWidth: true
                        implicitHeight: 44

                        MaterialShape {
                            id: dayShapeBg
                            anchors.centerIn: parent
                            shape: dayButton.dayShape
                            // Only the selected day gets its shape at full
                            // size/color — everyone else stays small and dim
                            // ("hidden"), so the strip reads as one shape
                            // popping forward rather than seven competing ones.
                            implicitSize: dayButton.isSelected
                            ? Math.min(dayButton.width, dayButton.height)
                            : Math.min(dayButton.width, dayButton.height) * 1.08
                            opacity: dayButton.isSelected ? 1 : (dayButton.isToday ? 0.55 : 0.3)
                            color: dayButton.isSelected
                            ? Appearance.colors.colPrimary
                            : (dayButton.isToday ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer)
                            scale: dayMouseArea.pressed ? 0.82 : (dayMouseArea.containsMouse ? 1.08 : 1)

                            Behavior on implicitSize {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                            Behavior on scale {
                                animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: root.dayShort[dayButton.index].substring(0, 1)
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Bold
                                color: dayButton.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: dayButton.modelData.getDate()
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                opacity: 0.8
                                color: dayButton.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                            }
                        }

                        MouseArea {
                            id: dayMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedDayIndex = dayButton.index
                        }
                    }
                }
            }

            // ── Bottom split: entry list (2/3) + weekly study-log panel
            // (1/3). Both size themselves off this Item's own height
            // (fillHeight from the outer ColumnLayout), NOT root.height —
            // binding the log panel to root.height directly was the bug:
            // it didn't reliably reflect the space actually available in
            // this column, so the log panel ballooned and squeezed the
            // entry list out entirely. Anchoring both to a shared
            // container's real, laid-out height fixes that. ──
            Item {
                id: bottomSplit
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.showForm

                readonly property int splitSpacing: 10

                // ── Entry list for the selected day (top 2/3) ──
                StyledFlickable {
                    id: entryListFlick
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: (parent.height - bottomSplit.splitSpacing) * 2 / 3
                    contentHeight: entriesCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: entriesCol
                        width: parent.width
                        spacing: 8

                        StyledText {
                            Layout.fillWidth: true
                            Layout.topMargin: 12
                            visible: root.dayEntries.length === 0
                            horizontalAlignment: Text.AlignHCenter
                            text: Translation.tr("Nothing scheduled")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        Repeater {
                            model: root.dayEntries
                            delegate: Rectangle {
                                id: entryCard
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: entryRow.implicitHeight + 18
                                radius: modelData.enabled ? Appearance.rounding.normal : Appearance.rounding.small
                                color: modelData.enabled
                                ? ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.55)
                                : Appearance.colors.colLayer1
                                opacity: modelData.enabled ? 1 : 0.6

                                RowLayout {
                                    id: entryRow
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        margins: 12
                                    }
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: entryCard.modelData.label
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnSecondaryContainer
                                            elide: Text.ElideRight
                                        }
                                        StyledText {
                                            text: StudySchedule.formatMinute(entryCard.modelData.startMinute) + " – " + StudySchedule.formatMinute(entryCard.modelData.endMinute)
                                            + (entryCard.modelData.carriedFromPrevDay ? " " + Translation.tr("(from yesterday)")
                                            : entryCard.modelData.endMinute >= 1440 ? " " + Translation.tr("(next day)") : "")
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                        }
                                    }

                                    // Faceted Gem for edit, a sharper Boom
                                    // burst for delete — the shape itself
                                    // signals "safe" vs "destructive" before
                                    // you even read the icon inside it.
                                    ShapedIconButton {
                                        id: shapedEditBtn
                                        implicitWidth: 28; implicitHeight: 28
                                        visible: !root.isPastDate(root.selectedDate)
                                        shape: MaterialShape.Shape.Gem
                                        color: shapedEditBtn.hovered
                                        ? ColorUtils.transparentize(Appearance.colors.colOnSecondaryContainer, 0.85)
                                        : ColorUtils.transparentize(Appearance.colors.colOnSecondaryContainer, 1)
                                        colSymbol: Appearance.colors.colOnSecondaryContainer
                                        text: "edit"
                                        iconSize: 14
                                        padding: 7
                                        onClicked: root.openEdit(entryCard.modelData)
                                    }
                                    ShapedIconButton {
                                        id: shapedDeleteBtn
                                        implicitWidth: 28; implicitHeight: 28
                                        shape: MaterialShape.Shape.Clover4Leaf
                                        color: shapedDeleteBtn.hovered
                                        ? ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                        : ColorUtils.transparentize(Appearance.colors.colError, 1)
                                        colSymbol: Appearance.colors.colError
                                        text: "delete"
                                        iconSize: 14
                                        padding: 7
                                        onClicked: root.deleteOccurrence(entryCard.modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Weekly study-log panel (bottom 1/3) — actually-
                // completed minutes from StudyLog, independent of
                // selectedDate, always showing the same 7-day window as
                // the week strip above. ──
                ColumnLayout {
                    id: logPanel
                    anchors {
                        top: entryListFlick.bottom; topMargin: bottomSplit.splitSpacing
                        left: parent.left; right: parent.right; bottom: parent.bottom
                    }
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Appearance.rounding.normal
                        color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.35)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                MaterialSymbol {
                                    text: "history_edu"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("This week")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                    opacity: 0.75
                                }
                                StyledText {
                                    text: StudyLog.formatDuration(root.logWeekTotal)
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            // ── One bar per day: fill height shows minutes
                            // studied relative to this week's busiest day, so
                            // the shape of the week reads at a glance. ──
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6

                                Repeater {
                                    model: root.weekDates
                                    delegate: ColumnLayout {
                                        id: dayBar
                                        required property var modelData
                                        required property int index
                                        readonly property int studiedMinutes: root.logWeekMinutes[dayBar.index] ?? 0
                                        readonly property bool isToday: root.isViewingThisWeek() && dayBar.index === (new Date().getDay() + 6) % 7
                                        readonly property real fillRatio: dayBar.studiedMinutes > 0
                                        ? Math.max(0.08, dayBar.studiedMinutes / root.logWeekMax)
                                        : 0

                                        // Equal preferredWidth on every column
                                        // is what actually makes fillWidth
                                        // split space evenly — without it each
                                        // column's width was implicitly driven
                                        // by its own day-letter glyph (bold
                                        // "M" vs "S" measure differently),
                                        // which is why the bars weren't
                                        // matching widths before.
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        spacing: 4

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            Layout.fillHeight: true

                                            Rectangle {
                                                id: barTrack
                                                anchors.fill: parent
                                                radius: Appearance.rounding.small
                                                color: Appearance.colors.colLayer1
                                            }
                                            Rectangle {
                                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                                height: barTrack.height * dayBar.fillRatio
                                                radius: Appearance.rounding.small
                                                color: dayBar.isToday ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                                                Behavior on height {
                                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                ToolTip.visible: containsMouse
                                                ToolTip.text: StudyLog.formatDuration(dayBar.studiedMinutes)
                                                ToolTip.delay: 300
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            horizontalAlignment: Text.AlignHCenter
                                            text: root.dayShort[dayBar.index].substring(0, 1)
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: dayBar.isToday ? Font.Bold : Font.Normal
                                            color: dayBar.isToday ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Add / edit form ──
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.showForm
                spacing: 10

                Rectangle {
                    id: labelField
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    border.width: labelInput.activeFocus ? 2 : 0
                    border.color: Appearance.colors.colPrimary

                    Behavior on border.width {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: labelInput.forceActiveFocus()
                    }

                    StyledText {
                        anchors {
                            left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                            leftMargin: 12; rightMargin: 12
                        }
                        visible: labelInput.text.length === 0
                        text: Translation.tr("e.g. Physics — Mechanics")
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }

                    StyledTextInput {
                        id: labelInput
                        anchors {
                            left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                            leftMargin: 12; rightMargin: 12
                        }
                        text: root.labelInput
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.normal
                        selectByMouse: true
                        selectionColor: Appearance.colors.colPrimary
                        clip: true
                        onTextChanged: root.labelInput = text
                    }
                }

                FlowButtonGroup {
                    Layout.fillWidth: true
                    spacing: 8

                    TimeChip {
                        chipLabel: Translation.tr("Start")
                        totalMinute: root.startMinute
                        onSet: (v) => root.setStart(v)
                    }
                    TimeChip {
                        chipLabel: Translation.tr("End")
                        totalMinute: root.endMinute
                        onSet: (v) => root.setEnd(v)
                    }
                }

                // ── Pill toggles: long session / no break / repeat weekly —
                // content-sized (not Layout.fillWidth, which a Flow ignores
                // anyway) so they wrap onto their own line instead of
                // squeezing when the sidebar is narrow. ──
                FlowButtonGroup {
                    Layout.fillWidth: true
                    spacing: 6

                    BouncyRippleButton {
                        implicitHeight: 32
                        implicitWidth: longSessionRow.implicitWidth + 24
                        enabled: !root.noBreak
                        opacity: enabled ? 1 : 0.4
                        buttonRadius: root.longSession ? Appearance.rounding.verylarge : Appearance.rounding.small
                        colBackground: root.longSession ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        colBackgroundHover: root.longSession ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                        colRipple: root.longSession ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2Active
                        downAction: () => root.longSession = !root.longSession
                        Behavior on buttonRadius {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        contentItem: RowLayout {
                            id: longSessionRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "hourglass_top"
                                iconSize: Appearance.font.pixelSize.normal
                                color: root.longSession ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("45/5")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: root.longSession ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                    BouncyRippleButton {
                        implicitHeight: 32
                        implicitWidth: noBreakRow.implicitWidth + 24
                        buttonRadius: root.noBreak ? Appearance.rounding.verylarge : Appearance.rounding.small
                        colBackground: root.noBreak ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        colBackgroundHover: root.noBreak ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                        colRipple: root.noBreak ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2Active
                        downAction: () => root.noBreak = !root.noBreak
                        Behavior on buttonRadius {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        contentItem: RowLayout {
                            id: noBreakRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "not_interested"
                                iconSize: Appearance.font.pixelSize.normal
                                color: root.noBreak ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("No break")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: root.noBreak ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                    BouncyRippleButton {
                        implicitHeight: 32
                        implicitWidth: repeatRow.implicitWidth + 24
                        visible: !root.editIsStandalone
                        buttonRadius: !root.justThisDate ? Appearance.rounding.verylarge : Appearance.rounding.small
                        colBackground: !root.justThisDate ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        colBackgroundHover: !root.justThisDate ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                        colRipple: !root.justThisDate ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2Active
                        downAction: () => root.justThisDate = !root.justThisDate
                        Behavior on buttonRadius {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        contentItem: RowLayout {
                            id: repeatRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "repeat"
                                iconSize: Appearance.font.pixelSize.normal
                                color: !root.justThisDate ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("Repeat weekly")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: !root.justThisDate ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    opacity: 0.75
                    color: root.formValid() ? Appearance.colors.colSubtext : Appearance.colors.colError
                    text: {
                        if (root.labelInput.trim().length === 0) return Translation.tr("Give it a name to save.")
                            if (root.endMinute === root.startMinute) return Translation.tr("Start and end can't be the same.")
                                const scoped = root.editIsStandalone || root.justThisDate
                                const repeatDate = root.editDate || root.selectedDate
                                const scopeText = scoped
                                ? Translation.tr("Applies only to this date.")
                                : Translation.tr("Repeats every") + " " + root.dayNames[(repeatDate.getDay() + 6) % 7] + "."
                                // End at/before Start isn't an error — it just
                                // means the block runs into the next day.
                                return root.endMinute < root.startMinute
                                ? Translation.tr("Continues past midnight into the next day.") + " " + scopeText
                                : scopeText
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        visible: root.editingId !== null && !root.editIsStandalone
                        text: Translation.tr("Delete series")
                        color: Appearance.colors.colError
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.underline: true
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteSeries()
                        }
                    }
                    Item { Layout.fillWidth: true }
                    BouncyRippleButton {
                        implicitWidth: 104; implicitHeight: 36
                        enabled: root.formValid()
                        opacity: enabled ? 1 : 0.4
                        buttonRadius: root.formValid() ? Appearance.rounding.verylarge : Appearance.rounding.small
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        colRipple: Appearance.colors.colPrimaryActive
                        downAction: () => root.save()
                        Behavior on buttonRadius {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            MaterialSymbol {
                                text: root.editingId ? "check" : "add_task"
                                iconSize: Appearance.font.pixelSize.normal
                                fill: 1
                                color: Appearance.colors.colOnPrimary
                            }
                            StyledText {
                                horizontalAlignment: Text.AlignHCenter
                                text: root.editingId ? Translation.tr("Update") : Translation.tr("Save")
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }
    }
}

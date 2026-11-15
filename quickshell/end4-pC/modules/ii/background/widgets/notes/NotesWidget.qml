
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "notes"
    hoverEnabled: true

    implicitWidth: 320
    implicitHeight: 380

    property string mode: "list" // "list" | "edit" | "schedule"
    property string _flipTarget: "list"
    property var pendingNoteId: null
    property string editingText: ""
    onModeChanged: GlobalStates.desktopWidgetKeyboardFocus = (mode === "edit" || mode === "schedule")

    // ── Note editing ─────────────────────────────────────────────────────
    function toggleFlip(targetMode) {
        root._flipTarget = targetMode !== undefined ? targetMode : (root.mode === "list" ? "edit" : "list")
        flipAnim.start()
    }

    function openNewNote() {
        root.pendingNoteId = null
        root.editingText = ""
        toggleFlip("edit")
    }

    function openNote(note) {
        root.pendingNoteId = note.id
        root.editingText = note.content
        toggleFlip("edit")
    }

    function saveAndBack() {
        if (root.editingText.length > 0) {
            if (root.pendingNoteId) {
                Notes.updateNote(root.pendingNoteId, root.editingText)
            } else {
                Notes.addNote(root.editingText)
            }
        }
        toggleFlip("list")
    }

    // ── Study schedule ───────────────────────────────────────────────────
    property var currentBlock: null
    property var upcomingBlocks: []
    property int nowMinutes: 0

    readonly property var monthShort: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    property var scheduleViewWeekStart: root._startOfWeek(new Date())
    property var scheduleWeekDates: root._computeWeekDates(root.scheduleViewWeekStart)
    property int scheduleSelectedDayIndex: (new Date().getDay() + 6) % 7

    property var scheduleEditingId: null
    property bool scheduleEditIsOverride: false
    property bool scheduleEditIsStandalone: false
    property var scheduleEditTemplateId: null
    property var scheduleEditOverrideId: null
    property bool scheduleJustThisDate: false
    property bool scheduleEditEnabled: true

    property string scheduleLabelInput: ""
    property int scheduleStartMinute: 9 * 60
    property int scheduleEndMinute: 10 * 60
    property bool scheduleShowForm: false
    property bool scheduleLongSession: false
    property bool scheduleNoBreak: false

    // 12-hour clock helpers — canonical storage stays 0-1439 minutes-since-
    // midnight (scheduleStartMinute/scheduleEndMinute); these just convert
    // for AM/PM display in the form.
    function hour12Of(totalMinute) {
        const h = Math.floor(totalMinute / 60) % 24
        let h12 = h % 12
        if (h12 === 0) h12 = 12
        return h12
    }
    function minutePartOf(totalMinute) {
        return totalMinute % 60
    }
    function isPMOf(totalMinute) {
        return Math.floor(totalMinute / 60) % 24 >= 12
    }
    function withHour12(totalMinute, hour12, isPM) {
        let h = hour12 % 12
        if (isPM) h += 12
        return h * 60 + (totalMinute % 60)
    }
    function withMinutePart(totalMinute, minutePart) {
        return Math.floor(totalMinute / 60) * 60 + minutePart
    }
    function withAmPm(totalMinute, isPM) {
        const h = Math.floor(totalMinute / 60) % 24
        const isCurrentlyPM = h >= 12
        if (isCurrentlyPM === isPM) return totalMinute
        return totalMinute + (isPM ? 12 * 60 : -12 * 60)
    }

    // ── Week navigation — the day tabs show real calendar dates, not just
    // abstract weekday names, so it's clear "this is Mon Aug 4" and not
    // some perpetual generic Monday. ─────────────────────────────────────
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
        root.scheduleViewWeekStart = root._addDays(root.scheduleViewWeekStart, -7)
        root.scheduleWeekDates = root._computeWeekDates(root.scheduleViewWeekStart)
    }
    function goToNextWeek() {
        root.scheduleViewWeekStart = root._addDays(root.scheduleViewWeekStart, 7)
        root.scheduleWeekDates = root._computeWeekDates(root.scheduleViewWeekStart)
    }
    function goToThisWeek() {
        root.scheduleViewWeekStart = root._startOfWeek(new Date())
        root.scheduleWeekDates = root._computeWeekDates(root.scheduleViewWeekStart)
        root.scheduleSelectedDayIndex = (new Date().getDay() + 6) % 7
    }
    function formatDateShort(d) {
        return root.monthShort[d.getMonth()] + " " + d.getDate()
    }
    function weekRangeLabel() {
        return root.formatDateShort(root.scheduleWeekDates[0]) + " – " + root.formatDateShort(root.scheduleWeekDates[6])
    }
    function isViewingThisWeek() {
        const thisWeekStart = root._startOfWeek(new Date())
        return root.scheduleViewWeekStart.getTime() === thisWeekStart.getTime()
    }
    property var selectedDate: (root.scheduleSelectedDayIndex >= 0 && root.scheduleSelectedDayIndex < root.scheduleWeekDates.length)
        ? root.scheduleWeekDates[root.scheduleSelectedDayIndex]
        : root.scheduleWeekDates[(new Date().getDay() + 6) % 7]

    function refreshScheduleView() {
        root.currentBlock = StudySchedule.currentEntry()
        root.upcomingBlocks = StudySchedule.upcomingEntries(3)
        root.nowMinutes = root.minutesNow(new Date())
    }

    function minutesNow(d) {
        return d.getHours() * 60 + d.getMinutes()
    }

    // "Completed" / "Missed" badge for a block on the date currently shown
    // in the editor. Works for any date in the past (not just today) since
    // StudyLog keeps a real, permanent per-date record — that's the whole
    // point of logging with real dates: you can look back at any prior
    // date, not only "today".
    function statusLabelFor(entry) {
        const selectedDateKey = StudySchedule.dateKeyFor(root.selectedDate)
        const todayKey = StudyLog.todayKey()
        if (selectedDateKey > todayKey) return "" // future date, nothing happened yet
        if (selectedDateKey === todayKey && root.nowMinutes < entry.endMinute) return "" // still upcoming today
        return StudyLog.hasCompleted(entry.id, selectedDateKey) ? "Completed" : "Missed"
    }

    function openScheduleEditor() {
        root.goToThisWeek()
        root.scheduleShowForm = false
        root.scheduleEditingId = null
        toggleFlip("schedule")
    }

    function resetScheduleForm() {
        root.scheduleEditingId = null
        root.scheduleEditIsOverride = false
        root.scheduleEditIsStandalone = false
        root.scheduleEditTemplateId = null
        root.scheduleEditOverrideId = null
        root.scheduleJustThisDate = false
        root.scheduleEditEnabled = true
        root.scheduleLabelInput = ""
        root.scheduleStartMinute = 9 * 60
        root.scheduleEndMinute = 10 * 60
        root.scheduleLongSession = false
        root.scheduleNoBreak = false
    }

    function scheduleFormValid() {
        if (root.scheduleLabelInput.trim().length === 0) return false
        return StudySchedule.isValidDuration(root.scheduleStartMinute, root.scheduleEndMinute, root.scheduleNoBreak)
    }

    function saveScheduleEntry() {
        if (!root.scheduleFormValid()) return

        const patch = {
            "label": root.scheduleLabelInput,
            "startMinute": root.scheduleStartMinute,
            "endMinute": root.scheduleEndMinute,
            "longSession": root.scheduleLongSession,
            "noBreak": root.scheduleNoBreak,
            "enabled": root.scheduleEditEnabled
        }

        if (!root.scheduleEditingId) {
            // Creating new
            if (root.scheduleJustThisDate) {
                StudySchedule.addOneOff(root.selectedDate, root.scheduleLabelInput, root.scheduleStartMinute,
                                         root.scheduleEndMinute, root.scheduleLongSession, root.scheduleNoBreak)
            } else {
                StudySchedule.addEntry(root.selectedDate.getDay(), root.scheduleLabelInput,
                                        root.scheduleStartMinute, root.scheduleEndMinute,
                                        root.scheduleLongSession, root.scheduleNoBreak)
            }
        } else if (root.scheduleEditIsStandalone) {
            // Already date-scoped, always
            StudySchedule.updateOverride(root.scheduleEditOverrideId, patch)
        } else if (root.scheduleJustThisDate) {
            // Template-linked, but scoping this edit to just this date
            StudySchedule.overrideModify(root.scheduleEditTemplateId, root.selectedDate, patch)
        } else {
            // Template-linked, edit applies to every week
            StudySchedule.updateEntry(root.scheduleEditTemplateId, patch)
        }

        root.resetScheduleForm()
        root.scheduleShowForm = false
        root.refreshScheduleView()
    }

    function editScheduleEntry(entry) {
        root.scheduleEditingId = entry.id
        root.scheduleEditIsOverride = !!entry.isOverride
        root.scheduleEditIsStandalone = !!entry.standalone
        root.scheduleEditTemplateId = entry.templateId ?? entry.id
        root.scheduleEditOverrideId = entry.overrideId ?? null
        root.scheduleJustThisDate = !!entry.standalone
        root.scheduleEditEnabled = entry.enabled !== false
        root.scheduleLabelInput = entry.label
        root.scheduleStartMinute = entry.startMinute
        root.scheduleEndMinute = entry.endMinute
        root.scheduleLongSession = !!entry.longSession
        root.scheduleNoBreak = !!entry.noBreak
        root.scheduleShowForm = true
    }

    // Removes one occurrence from the selected date. A standalone one-off
    // is deleted outright; a template-linked occurrence (whether currently
    // modified or plain) is skipped for this date only — every other week
    // keeps running normally.
    function deleteScheduleOccurrence(entry) {
        if (entry.standalone) {
            StudySchedule.removeOverride(entry.overrideId)
        } else {
            StudySchedule.overrideSkip(entry.templateId, root.selectedDate)
        }
        root.refreshScheduleView()
    }

    // Deletes the whole recurring series (every week, going forward) —
    // only offered from the edit form for a template-linked entry.
    function deleteScheduleSeries() {
        if (!root.scheduleEditTemplateId) return
        StudySchedule.deleteTemplate(root.scheduleEditTemplateId)
        root.resetScheduleForm()
        root.scheduleShowForm = false
        root.refreshScheduleView()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshScheduleView()
    }

    Connections {
        target: StudySchedule
        function onListChanged() { root.refreshScheduleView() }
    }

    Item {
        id: cardWrapper
        anchors.fill: parent

        transform: Scale {
            id: flipScale
            origin.x: cardWrapper.width  / 2
            origin.y: cardWrapper.height / 2
            xScale: 1
        }

        SequentialAnimation {
            id: flipAnim
            NumberAnimation {
                target: flipScale; property: "xScale"
                to: 0; duration: 150; easing.type: Easing.InQuad
            }
            ScriptAction {
                script: root.mode = root._flipTarget
            }
            NumberAnimation {
                target: flipScale; property: "xScale"
                to: 1; duration: 150; easing.type: Easing.OutQuad
            }
        }

        StyledDropShadow { target: contentRect }

        Rectangle {
            id: contentRect
            anchors.fill: parent
            color: Appearance.colors.colPrimaryContainer
            radius: Appearance.rounding?.verylarge ?? 30

            FastBlurred {
                anchors.fill: parent
                blurSource: root.wallpaperItem
                cardRadius: contentRect.radius
                tint: Appearance.colors.colLayer1
                tintOpacity: 0.55
                trackX: root.x
                trackY: root.y
                visible: Config.options.background.widgets.blurWidgets
            }

            // ── List page (notes + schedule summary) ────────────────────
            ColumnLayout {
                id: listPage
                anchors { fill: parent; margins: 12 }
                spacing: 8
                visible: root.mode === "list"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        Layout.topMargin: -4
                        Layout.leftMargin: 8
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimaryContainer
                        text: "Notes"
                    }
                    Item { Layout.fillWidth: true }

                    ToolbarPairedFab {
                        Layout.alignment: Qt.AlignVCenter
                        baseSize: 34
                        iconText: "edit_calendar"
                        onClicked: root.openScheduleEditor()
                    }

                    ToolbarPairedFab {
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignVCenter
                        baseSize: 38
                        iconText: "add"
                        onClicked: root.openNewNote()
                    }
                }

                // ── Studied today ─────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    spacing: 4
                    visible: StudyLog.minutesToday() > 0

                    MaterialSymbol {
                        text: "local_fire_department"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.65
                    }
                    StyledText {
                        text: "Studied today: " + StudyLog.formatDuration(StudyLog.minutesToday())
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.65
                    }
                }

                // ── Now / Upcoming schedule summary ──────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.currentBlock !== null || root.upcomingBlocks.length > 0

                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.currentBlock !== null
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colPrimary
                        implicitHeight: nowRow.implicitHeight + 16

                        RowLayout {
                            id: nowRow
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 12; rightMargin: 12
                            }
                            spacing: 8

                            Rectangle {
                                implicitWidth: 8; implicitHeight: 8; radius: 4
                                color: Appearance.colors.colOnPrimary
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 700 }
                                    NumberAnimation { to: 1; duration: 700 }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    Layout.fillWidth: true
                                    text: "Now · " + (root.currentBlock?.label ?? "")
                                    color: Appearance.colors.colOnPrimary
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    text: root.currentBlock
                                        ? StudySchedule.formatMinute(root.currentBlock.startMinute) + " – " + StudySchedule.formatMinute(root.currentBlock.endMinute)
                                        : ""
                                    color: Appearance.colors.colOnPrimary
                                    opacity: 0.8
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: root.upcomingBlocks.length > 0

                        StyledText {
                            Layout.leftMargin: 4
                            text: "Upcoming"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.65
                        }

                        Repeater {
                            model: root.upcomingBlocks
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colSurfaceContainerLow
                                implicitHeight: upRow.implicitHeight + 12

                                RowLayout {
                                    id: upRow
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 10; rightMargin: 10
                                    }
                                    spacing: 8

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnLayer0
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                    StyledText {
                                        text: (modelData.dayLabel === "Tomorrow" ? "Tmrw " : "")
                                            + StudySchedule.formatMinute(modelData.startMinute) + " – " + StudySchedule.formatMinute(modelData.endMinute)
                                        color: Appearance.colors.colOnLayer0
                                        opacity: 0.65
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                    }
                                }
                            }
                        }
                    }
                }

                StyledListView {
                    id: notesListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: Notes.list

                    delegate: SwipeDelegate {
                        id: noteCard
                        required property var modelData
                        required property int index

                        width: notesListView.width
                        implicitHeight: 55
                        padding: 0
                        background: null
                        clip: true

                        property color bg: {
                            const cyclePos = index % 3
                            if (cyclePos === 0) return Appearance.colors.colPrimary
                            if (cyclePos === 1) return Appearance.colors.colSecondary
                            return Appearance.colors.colTertiary
                        }
                        property color fg: {
                            const cyclePos = index % 3
                            if (cyclePos === 0) return Appearance.colors.colOnPrimary
                            if (cyclePos === 1) return Appearance.colors.colOnSecondary
                            return Appearance.colors.colOnTertiary
                        }

                        onClicked: root.openNote(noteCard.modelData)

                        contentItem: Rectangle {
                            radius: Appearance.rounding.normal
                            color: noteCard.bg
                            width: parent.width - Math.abs(noteCard.swipe.position) * 6

                            StyledText {
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 12; rightMargin: 12
                                }
                                color: noteCard.fg
                                text: noteCard.modelData.content
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        swipe.right: Rectangle {
                            width: 64
                            anchors.right: parent.right
                            height: parent.height
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colError

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnError
                            }

                            SwipeDelegate.onClicked: Notes.deleteNote(noteCard.modelData.id)
                        }
                    }
                }
            }

            // ── Note edit page ───────────────────────────────────────────
            ColumnLayout {
                id: editPage
                anchors { fill: parent; margins: 12 }
                spacing: 10
                visible: root.mode === "edit"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        radius: Appearance.rounding.full
                        color: "transparent"
                        implicitWidth: 28; implicitHeight: 28
                        MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: Appearance.font.pixelSize.normal
                            text: "arrow_back"
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleFlip("list")
                        }
                    }
                    Item { Layout.fillWidth: true }

                    ToolbarPairedFab {
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignVCenter
                        baseSize: 38
                        iconText: "save"
                        onClicked: root.saveAndBack()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow

                    TextArea {
                        id: editTextArea
                        anchors.fill: parent
                        anchors.margins: 8
                        text: root.editingText
                        wrapMode: TextArea.Wrap
                        placeholderText: "Type your note..."
                        color: Appearance.colors.colOnLayer0
                        background: null
                        onTextChanged: root.editingText = text
                    }
                }
            }

            // ── Study schedule editor page ───────────────────────────────
            ColumnLayout {
                id: schedulePage
                anchors { fill: parent; margins: 12 }
                spacing: 8
                visible: root.mode === "schedule"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        radius: Appearance.rounding.full
                        color: "transparent"
                        implicitWidth: 28; implicitHeight: 28
                        MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: Appearance.font.pixelSize.normal
                            text: "arrow_back"
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleFlip("list")
                        }
                    }

                    StyledText {
                        Layout.leftMargin: 6
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimaryContainer
                        text: "Study schedule"
                    }
                    Item { Layout.fillWidth: true }

                    ToolbarPairedFab {
                        Layout.rightMargin: 4
                        baseSize: 34
                        iconText: root.scheduleShowForm ? "close" : "add"
                        onClicked: {
                            if (root.scheduleShowForm) {
                                root.resetScheduleForm()
                                root.scheduleShowForm = false
                            } else {
                                root.scheduleShowForm = true
                            }
                        }
                    }
                }

                // ── Week navigation ───────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RippleButton {
                        implicitWidth: 26; implicitHeight: 26
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        downAction: () => root.goToPrevWeek()
                        MaterialSymbol {
                            anchors.centerIn: parent
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

                    RippleButton {
                        implicitWidth: 26; implicitHeight: 26
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        downAction: () => root.goToNextWeek()
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_right"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                        }
                    }

                    RippleButton {
                        visible: !root.isViewingThisWeek()
                        implicitWidth: 52; implicitHeight: 26
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colLayer1
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        downAction: () => root.goToThisWeek()
                        StyledText {
                            anchors.centerIn: parent
                            text: "Today"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }

                SecondaryTabBar {
                    id: dayTabBar
                    Layout.fillWidth: true
                    currentIndex: root.scheduleSelectedDayIndex
                    onCurrentIndexChanged: {
                        // The Repeater below rebuilds its buttons whenever
                        // scheduleWeekDates changes (prev/next/today week
                        // nav), and SecondaryTabBar transiently reports -1
                        // mid-rebuild. Ignore that instead of propagating
                        // it into scheduleSelectedDayIndex, which would
                        // make scheduleWeekDates[-1] (undefined) leak into
                        // every place that reads root.selectedDate.
                        if (currentIndex >= 0) root.scheduleSelectedDayIndex = currentIndex
                    }

                    Repeater {
                        model: root.scheduleWeekDates
                        delegate: SecondaryTabButton {
                            required property var modelData
                            required property int index
                            buttonText: StudySchedule.dayShort[index] + " " + modelData.getDate()
                        }
                    }
                }


                // ── Add / edit block form ────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.scheduleShowForm
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    implicitHeight: formCol.implicitHeight + 20

                    ColumnLayout {
                        id: formCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8

                        TextField {
                            id: labelField
                            Layout.fillWidth: true
                            text: root.scheduleLabelInput
                            placeholderText: "e.g. Physics — Mechanics"
                            color: Appearance.colors.colOnLayer0
                            background: Rectangle {
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colLayer1
                            }
                            onTextChanged: root.scheduleLabelInput = text
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    text: "Start"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    opacity: 0.65
                                    color: Appearance.colors.colOnLayer0
                                }
                                RowLayout {
                                    spacing: 4
                                    SpinBox {
                                        id: startHour
                                        from: 1; to: 12
                                        editable: true
                                        value: root.hour12Of(root.scheduleStartMinute)
                                        onValueModified: root.scheduleStartMinute = root.withHour12(root.scheduleStartMinute, value, root.isPMOf(root.scheduleStartMinute))
                                    }
                                    StyledText { text: ":"; color: Appearance.colors.colOnLayer0 }
                                    SpinBox {
                                        id: startMin
                                        from: 0; to: 59
                                        editable: true
                                        value: root.minutePartOf(root.scheduleStartMinute)
                                        onValueModified: root.scheduleStartMinute = root.withMinutePart(root.scheduleStartMinute, value)
                                    }
                                    RippleButton {
                                        implicitWidth: 42; implicitHeight: 30
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: Appearance.colors.colLayer1
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        colRipple: Appearance.colors.colLayer1Active
                                        downAction: () => root.scheduleStartMinute = root.withAmPm(root.scheduleStartMinute, !root.isPMOf(root.scheduleStartMinute))

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: root.isPMOf(root.scheduleStartMinute) ? "PM" : "AM"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnLayer1
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    text: "End"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    opacity: 0.65
                                    color: Appearance.colors.colOnLayer0
                                }
                                RowLayout {
                                    spacing: 4
                                    SpinBox {
                                        id: endHour
                                        from: 1; to: 12
                                        editable: true
                                        value: root.hour12Of(root.scheduleEndMinute)
                                        onValueModified: root.scheduleEndMinute = root.withHour12(root.scheduleEndMinute, value, root.isPMOf(root.scheduleEndMinute))
                                    }
                                    StyledText { text: ":"; color: Appearance.colors.colOnLayer0 }
                                    SpinBox {
                                        id: endMin
                                        from: 0; to: 59
                                        editable: true
                                        value: root.minutePartOf(root.scheduleEndMinute)
                                        onValueModified: root.scheduleEndMinute = root.withMinutePart(root.scheduleEndMinute, value)
                                    }
                                    RippleButton {
                                        implicitWidth: 42; implicitHeight: 30
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: Appearance.colors.colLayer1
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        colRipple: Appearance.colors.colLayer1Active
                                        downAction: () => root.scheduleEndMinute = root.withAmPm(root.scheduleEndMinute, !root.isPMOf(root.scheduleEndMinute))

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: root.isPMOf(root.scheduleEndMinute) ? "PM" : "AM"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnLayer1
                                        }
                                    }
                                }
                            }
                        }

                        // ── Long session / no break toggles ──────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            RippleButton {
                                implicitHeight: 32
                                implicitWidth: longSessionRow.implicitWidth + 20
                                buttonRadius: Appearance.rounding.full
                                enabled: !root.scheduleNoBreak
                                opacity: root.scheduleNoBreak ? 0.4 : 1
                                colBackground: root.scheduleLongSession ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                colBackgroundHover: root.scheduleLongSession ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colPrimaryActive
                                downAction: () => root.scheduleLongSession = !root.scheduleLongSession

                                RowLayout {
                                    id: longSessionRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "hourglass_top"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: root.scheduleLongSession ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        text: "Long session (45/5)"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: root.scheduleLongSession ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                    }
                                }
                            }

                            RippleButton {
                                implicitHeight: 32
                                implicitWidth: noBreakRow.implicitWidth + 20
                                buttonRadius: Appearance.rounding.full
                                colBackground: root.scheduleNoBreak ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                colBackgroundHover: root.scheduleNoBreak ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colPrimaryActive
                                downAction: () => root.scheduleNoBreak = !root.scheduleNoBreak

                                RowLayout {
                                    id: noBreakRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "not_interested"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: root.scheduleNoBreak ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        text: "No break"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: root.scheduleNoBreak ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                    }
                                }
                            }

                            RippleButton {
                                implicitHeight: 32
                                implicitWidth: justThisDateRow.implicitWidth + 20
                                buttonRadius: Appearance.rounding.full
                                // A standalone one-off is inherently date-only already —
                                // no point toggling something that's already the only option.
                                visible: !root.scheduleEditIsStandalone
                                colBackground: root.scheduleJustThisDate ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                colBackgroundHover: root.scheduleJustThisDate ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colPrimaryActive
                                downAction: () => root.scheduleJustThisDate = !root.scheduleJustThisDate

                                RowLayout {
                                    id: justThisDateRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "event"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: root.scheduleJustThisDate ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        text: "Just this date"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: root.scheduleJustThisDate ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            opacity: 0.6
                            color: root.scheduleFormValid() ? Appearance.colors.colOnLayer0 : Appearance.colors.colError
                            text: {
                                const unit = root.scheduleLongSession ? StudySchedule.longFocusMinutes : StudySchedule.minFocusMinutes
                                const duration = root.scheduleEndMinute - root.scheduleStartMinute
                                let base
                                if (root.scheduleNoBreak) {
                                    base = "Continuous focus for the whole block, then it ends — no breaks."
                                } else if (duration > 0 && duration <= unit) {
                                    base = `${duration} min or less runs straight through as one focus session, same as No break.`
                                } else {
                                    base = `Cycles ${unit} min focus / ${StudySchedule.breakMinutes} min break, repeating — the last stretch just ends whenever the block does, however short that leaves it.`
                                }
                                const scoped = root.scheduleEditIsStandalone || root.scheduleJustThisDate
                                const scopeNote = scoped
                                    ? ` Applies only to ${root.formatDateShort(root.selectedDate)}.`
                                    : ` Repeats every ${StudySchedule.dayNames[(root.selectedDate.getDay() + 6) % 7]}.`
                                return base + scopeNote
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.scheduleEditingId !== null && !root.scheduleEditIsStandalone

                            StyledText {
                                Layout.fillWidth: true
                                text: "Delete this and every future " + StudySchedule.dayNames[(root.selectedDate.getDay() + 6) % 7]
                                color: Appearance.colors.colError
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.underline: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.deleteScheduleSeries()
                                }
                            }
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignRight
                            implicitWidth: 78; implicitHeight: 34
                            buttonRadius: Appearance.rounding.small
                            enabled: root.scheduleFormValid()
                            opacity: enabled ? 1 : 0.4
                            colBackground: Appearance.colors.colPrimary
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            colRipple: Appearance.colors.colPrimaryActive
                            downAction: () => root.saveScheduleEntry()

                            StyledText {
                                anchors.centerIn: parent
                                text: root.scheduleEditingId ? "Update" : "Save"
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }

                // ── Blocks for the selected day ──────────────────────────
                StyledListView {
                    id: dayEntriesList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: StudySchedule.effectiveEntriesForDate(root.selectedDate)

                    delegate: SwipeDelegate {
                        id: entryCard
                        required property var modelData

                        width: dayEntriesList.width
                        implicitHeight: 52
                        padding: 0
                        background: null
                        clip: true

                        onClicked: root.editScheduleEntry(entryCard.modelData)

                        contentItem: Rectangle {
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colSurfaceContainerLow
                            opacity: entryCard.modelData.enabled ? 1 : 0.5
                            width: parent.width - Math.abs(entryCard.swipe.position) * 6

                            RowLayout {
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 12; rightMargin: 8
                                }
                                spacing: 6

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: entryCard.modelData.label
                                            elide: Text.ElideRight
                                            color: Appearance.colors.colOnLayer0
                                            font.weight: Font.Medium
                                        }
                                        MaterialSymbol {
                                            visible: !!entryCard.modelData.noBreak
                                            text: "not_interested"
                                            iconSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnLayer0
                                            opacity: 0.55
                                        }
                                        MaterialSymbol {
                                            visible: !entryCard.modelData.noBreak && !!entryCard.modelData.longSession
                                            text: "hourglass_top"
                                            iconSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnLayer0
                                            opacity: 0.55
                                        }
                                        MaterialSymbol {
                                            visible: !!entryCard.modelData.isOverride
                                            text: "event"
                                            iconSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnLayer0
                                            opacity: 0.55
                                        }
                                    }
                                    StyledText {
                                        text: StudySchedule.formatMinute(entryCard.modelData.startMinute) + " – " + StudySchedule.formatMinute(entryCard.modelData.endMinute)
                                        color: Appearance.colors.colOnLayer0
                                        opacity: 0.65
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                    }
                                    StyledText {
                                        property string status: root.statusLabelFor(entryCard.modelData)
                                        visible: status !== ""
                                        text: status === "Completed" ? "✓ Completed" : "Missed"
                                        color: status === "Completed" ? Appearance.colors.colPrimary : Appearance.colors.colError
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Medium
                                    }
                                }

                                Switch {
                                    checked: entryCard.modelData.enabled
                                    onToggled: StudySchedule.toggleEnabledForEffectiveEntry(entryCard.modelData)
                                }
                            }
                        }

                        swipe.right: Rectangle {
                            width: 64
                            anchors.right: parent.right
                            height: parent.height
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colError

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnError
                            }

                            SwipeDelegate.onClicked: root.deleteScheduleOccurrence(entryCard.modelData)
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        visible: StudySchedule.effectiveEntriesForDate(root.selectedDate).length === 0
                        width: parent.width

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                iconSize: 40
                                color: Appearance.colors.colOnPrimaryContainer
                                opacity: 0.5
                                text: "event_busy"
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No blocks on " + StudySchedule.dayNames[(root.selectedDate.getDay() + 6) % 7] + ", " + root.formatDateShort(root.selectedDate)
                                color: Appearance.colors.colOnPrimaryContainer
                                opacity: 0.5
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }
            }
        }
    }
}




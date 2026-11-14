pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.config

Item {
    id: root


    // ── macOS restyle: local stand-ins so every control here uses the Mac look ──
    component StyledRect: MacRect {}

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    property string currentSection: ""

    component SectionButton: MacSectionRow {
        id: sectionBtn
        onClicked: root.currentSection = sectionBtn.sectionId
    }

    // Main content
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 8

            // Header wrapper
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titlebar.height

                PanelTitlebar {
                    id: titlebar
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    title: root.currentSection === "" ? "System" : (root.currentSection === "system" ? "System Resources" : (root.currentSection.charAt(0).toUpperCase() + root.currentSection.slice(1)))
                    statusText: ""

                    actions: {
                        if (root.currentSection !== "") {
                            return [
                                {
                                    icon: Icons.arrowLeft,
                                    tooltip: "Back",
                                    onClicked: function () {
                                        root.currentSection = "";
                                    }
                                }
                            ];
                        }
                        return [];
                    }
                }
            }

            // Content wrapper - centered
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumn.implicitHeight

                ColumnLayout {
                    id: contentColumn
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    // ═══════════════════════════════════════════════════════════════
                    // MENU SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === ""
                        Layout.fillWidth: true
                        spacing: 8

                        MacGroup {
                            SectionButton {
                                text: "Prefixes"
                                sectionId: "prefixes"
                            }
                            SectionButton {
                                text: "Weather"
                                sectionId: "weather"
                            }
                            SectionButton {
                                text: "Performance"
                                sectionId: "performance"
                            }
                            SectionButton {
                                text: "System Resources"
                                sectionId: "system"
                            }
                            SectionButton {
                                text: "Idle"
                                sectionId: "idle"
                            }
                        }
                    }

                    // =====================
                    // PREFIX SECTION
                    // =====================
                    ColumnLayout {
                        visible: root.currentSection === "prefixes"
                        property string settingsSection: "prefixes"
                        Layout.fillWidth: true
                        spacing: 8


                        Text {
                            text: "Keyboard shortcuts for quick actions in launcher"
                            font.family: MacStyle.fontFamily
                            font.pixelSize: MacStyle.fontSize(-2)
                            color: MacStyle.labelSecondary
                            opacity: 0.7
                        }

                        // Clipboard prefix
                        MacGroup {
                            PrefixRow {
                                Layout.fillWidth: true
                                label: "Clipboard"
                                prefixValue: Config.prefix.clipboard
                                onPrefixEdited: newValue => {
                                    Config.prefix.clipboard = newValue;
                                }
                            }

                            // Emoji prefix
                            PrefixRow {
                                Layout.fillWidth: true
                                label: "Emoji"
                                prefixValue: Config.prefix.emoji
                                onPrefixEdited: newValue => {
                                    Config.prefix.emoji = newValue;
                                }
                            }

                            // Tmux prefix
                            PrefixRow {
                                Layout.fillWidth: true
                                label: "Tmux"
                                prefixValue: Config.prefix.tmux
                                onPrefixEdited: newValue => {
                                    Config.prefix.tmux = newValue;
                                }
                            }

                            // Wallpapers prefix
                            PrefixRow {
                                Layout.fillWidth: true
                                label: "Wallpapers"
                                prefixValue: Config.prefix.wallpapers
                                onPrefixEdited: newValue => {
                                    Config.prefix.wallpapers = newValue;
                                }
                            }

                            // Notes prefix
                            PrefixRow {
                                Layout.fillWidth: true
                                label: "Notes"
                                prefixValue: Config.prefix.notes
                                onPrefixEdited: newValue => {
                                    Config.prefix.notes = newValue;
                                }
                            }
                        }
                    }

                    // =====================
                    // WEATHER SECTION
                    // =====================
                    ColumnLayout {
                        visible: root.currentSection === "weather"
                        property string settingsSection: "weather"
                        Layout.fillWidth: true
                        spacing: 8


                        // Location
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Location"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                Layout.preferredWidth: 100
                            }

                            StyledRect {
                                variant: "common"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: MacStyle.radius(-2)

                                TextInput {
                                    id: locationInput
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    font.family: MacStyle.fontFamily
                                    font.pixelSize: MacStyle.fontSize(0)
                                    color: MacStyle.label
                                    selectByMouse: true
                                    clip: true
                                    verticalAlignment: TextInput.AlignVCenter

                                    readonly property string configValue: Config.weather.location

                                    onConfigValueChanged: {
                                        if (text !== configValue) {
                                            text = configValue;
                                        }
                                    }

                                    Component.onCompleted: text = configValue

                                    onEditingFinished: {
                                        if (text !== Config.weather.location) {
                                            Config.weather.location = text.trim();
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !locationInput.text && !locationInput.activeFocus
                                        text: "e.g. Buenos Aires, Tokyo..."
                                        font: locationInput.font
                                        color: MacStyle.labelSecondary
                                    }
                                }
                            }
                        }

                        // Unit selector
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Unit"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                Layout.preferredWidth: 100
                            }

                            Row {
                                spacing: 8

                                Repeater {
                                    model: [
                                        {
                                            id: "C",
                                            label: "Celsius"
                                        },
                                        {
                                            id: "F",
                                            label: "Fahrenheit"
                                        }
                                    ]

                                    delegate: StyledRect {
                                        id: unitButton
                                        required property var modelData
                                        required property int index

                                        property bool isSelected: Config.weather.unit === modelData.id
                                        property bool isHovered: false

                                        variant: isSelected ? "primary" : (isHovered ? "focus" : "common")
                                        width: unitLabel.width + 24
                                        height: 36
                                        radius: MacStyle.radius(-2)

                                        Text {
                                            id: unitLabel
                                            anchors.centerIn: parent
                                            text: unitButton.modelData.label
                                            font.family: MacStyle.fontFamily
                                            font.pixelSize: MacStyle.fontSize(0)
                                            font.weight: unitButton.isSelected ? Font.Bold : Font.Normal
                                            color: unitButton.item
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: unitButton.isHovered = true
                                            onExited: unitButton.isHovered = false
                                            onClicked: Config.weather.unit = unitButton.modelData.id
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =====================
                    // PERFORMANCE SECTION
                    // =====================
                    ColumnLayout {
                        visible: root.currentSection === "performance"
                        property string settingsSection: "performance"
                        Layout.fillWidth: true
                        spacing: 8


                        Text {
                            text: "Toggle visual effects to improve performance"
                            font.family: MacStyle.fontFamily
                            font.pixelSize: MacStyle.fontSize(-2)
                            color: MacStyle.labelSecondary
                            opacity: 0.7
                        }

                        // Blur Transition toggle
                        MacGroup {
                            ToggleRow {
                                Layout.fillWidth: true
                                label: "Blur Transition"
                                description: "Animated blur when opening panels"
                                checked: Config.performance.blurTransition
                                onToggled: checked => {
                                    Config.performance.blurTransition = checked;
                                }
                            }

                            // Window Preview toggle
                            ToggleRow {
                                Layout.fillWidth: true
                                label: "Window Preview"
                                description: "Show window thumbnails in overview"
                                checked: Config.performance.windowPreview
                                onToggled: checked => {
                                    Config.performance.windowPreview = checked;
                                }
                            }

                            // Wavy Line toggle
                            ToggleRow {
                                Layout.fillWidth: true
                                label: "Wavy Line"
                                description: "Animated wavy line effect"
                                checked: Config.performance.wavyLine
                                onToggled: checked => {
                                    Config.performance.wavyLine = checked;
                                }
                            }

                            // Rotate Cover Art toggle
                            ToggleRow {
                                Layout.fillWidth: true
                                label: "Disable Cover Art Rotation"
                                description: "Stop the vinyl disc from spinning"
                                checked: !Config.performance.rotateCoverArt
                                onToggled: checked => {
                                    Config.performance.rotateCoverArt = !checked;
                                }
                            }
                        }
                    }

                    // =====================
                    // SYSTEM SECTION
                    // =====================
                    ColumnLayout {
                        visible: root.currentSection === "system"
                        property string settingsSection: "system"
                        Layout.fillWidth: true
                        spacing: 8

                        MacHeader {
                            text: "System Resources"
                        }

                        Text {
                            text: "Configure which disks to monitor"
                            font.family: MacStyle.fontFamily
                            font.pixelSize: MacStyle.fontSize(-2)
                            color: MacStyle.labelSecondary
                            opacity: 0.7
                        }

                        // Disks list
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                id: disksRepeater
                                model: Config.system.disks

                                delegate: RowLayout {
                                    id: diskRow
                                    required property string modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    spacing: 8

                                    StyledRect {
                                        variant: "common"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        radius: MacStyle.radius(-2)

                                        TextInput {
                                            id: diskInput
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            font.family: Config.theme.monoFont
                                            font.pixelSize: MacStyle.monoFontSize(0)
                                            color: MacStyle.label
                                            selectByMouse: true
                                            clip: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: diskRow.modelData

                                            onEditingFinished: {
                                                if (text.trim() !== diskRow.modelData) {
                                                    let newDisks = Config.system.disks.slice();
                                                    newDisks[diskRow.index] = text.trim();
                                                    Config.system.disks = newDisks;
                                                }
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: !diskInput.text && !diskInput.activeFocus
                                                text: "e.g. /, /home..."
                                                font: diskInput.font
                                                color: MacStyle.labelSecondary
                                            }
                                        }
                                    }

                                    // Remove button
                                    StyledRect {
                                        id: removeDiskButton
                                        variant: removeDiskArea.containsMouse ? "focus" : "common"
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: MacStyle.radius(-2)
                                        visible: disksRepeater.count > 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.trash
                                            font.family: Icons.font
                                            font.pixelSize: 14
                                            color: MacStyle.destructive
                                        }

                                        MouseArea {
                                            id: removeDiskArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let newDisks = Config.system.disks.slice();
                                                newDisks.splice(diskRow.index, 1);
                                                Config.system.disks = newDisks;
                                            }
                                        }

                                        StyledToolTip {
                                            visible: removeDiskArea.containsMouse
                                            tooltipText: "Remove disk"
                                        }
                                    }
                                }
                            }

                            // Add disk button
                            StyledRect {
                                id: addDiskButton
                                variant: addDiskArea.containsMouse ? "primaryfocus" : "primary"
                                Layout.preferredWidth: addDiskContent.width + 24
                                Layout.preferredHeight: 36
                                radius: MacStyle.radius(-2)

                                Row {
                                    id: addDiskContent
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: Icons.plus
                                        font.family: Icons.font
                                        font.pixelSize: 14
                                        color: addDiskButton.item
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Add Disk"
                                        font.family: MacStyle.fontFamily
                                        font.pixelSize: MacStyle.fontSize(0)
                                        color: addDiskButton.item
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: addDiskArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let newDisks = Config.system.disks.slice();
                                        newDisks.push("/");
                                        Config.system.disks = newDisks;
                                    }
                                }
                            }
                        }
                    }

                    // =====================
                    // IDLE SECTION
                    // =====================
                    ColumnLayout {
                        visible: root.currentSection === "idle"
                        property string settingsSection: "idle"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            TextInputRow {
                                label: "Lock Cmd"
                                value: Config.system.idle.general.lock_cmd ?? ""
                                placeholder: "Command to lock screen"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.system.idle.general.lock_cmd) {
                                        GlobalStates.markShellChanged();
                                        Config.system.idle.general.lock_cmd = newValue;
                                    }
                                }
                            }

                            TextInputRow {
                                label: "Before Sleep"
                                value: Config.system.idle.general.before_sleep_cmd ?? ""
                                placeholder: "Command before sleep"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.system.idle.general.before_sleep_cmd) {
                                        GlobalStates.markShellChanged();
                                        Config.system.idle.general.before_sleep_cmd = newValue;
                                    }
                                }
                            }

                            TextInputRow {
                                label: "After Sleep"
                                value: Config.system.idle.general.after_sleep_cmd ?? ""
                                placeholder: "Command after sleep"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.system.idle.general.after_sleep_cmd) {
                                        GlobalStates.markShellChanged();
                                        Config.system.idle.general.after_sleep_cmd = newValue;
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Listeners"
                            font.family: MacStyle.fontFamily
                            font.pixelSize: MacStyle.fontSize(0)
                            color: MacStyle.label
                            Layout.topMargin: 8
                        }

                        Repeater {
                            model: Config.system.idle.listeners

                            delegate: ColumnLayout {
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                spacing: 4
                                Layout.bottomMargin: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Colors.surfaceBright
                                    visible: index > 0
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Listener " + (index + 1)
                                        font.family: MacStyle.fontFamily
                                        font.pixelSize: MacStyle.fontSize(-1)
                                        font.bold: true
                                        color: MacStyle.accent
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    StyledRect {
                                        id: deleteListenerBtn
                                        variant: "error"
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        radius: MacStyle.radius(-2)

                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.trash
                                            font.family: Icons.font
                                            color: deleteListenerBtn.item
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                // Create a copy of the list to ensure change detection
                                                var list = [];
                                                for (var i = 0; i < Config.system.idle.listeners.length; i++)
                                                    list.push(Config.system.idle.listeners[i]);
                                                list.splice(index, 1);
                                                Config.system.idle.listeners = list;
                                                GlobalStates.markShellChanged();
                                            }
                                        }
                                    }
                                }

                                NumberInputRow {
                                    label: "Timeout (s)"
                                    value: modelData.timeout || 0
                                    minValue: 1
                                    maxValue: 7200
                                    onValueEdited: val => {
                                        var list = [];
                                        for (var i = 0; i < Config.system.idle.listeners.length; i++)
                                            list.push(Config.system.idle.listeners[i]);
                                        list[index].timeout = val;
                                        Config.system.idle.listeners = list;
                                        GlobalStates.markShellChanged();
                                    }
                                }

                                TextInputRow {
                                    label: "On Timeout"
                                    value: modelData.onTimeout || ""
                                    onValueEdited: val => {
                                        var list = [];
                                        for (var i = 0; i < Config.system.idle.listeners.length; i++)
                                            list.push(Config.system.idle.listeners[i]);
                                        list[index].onTimeout = val;
                                        Config.system.idle.listeners = list;
                                        GlobalStates.markShellChanged();
                                    }
                                }

                                TextInputRow {
                                    label: "On Resume"
                                    value: modelData.onResume || ""
                                    onValueEdited: val => {
                                        var list = [];
                                        for (var i = 0; i < Config.system.idle.listeners.length; i++)
                                            list.push(Config.system.idle.listeners[i]);
                                        list[index].onResume = val;
                                        Config.system.idle.listeners = list;
                                        GlobalStates.markShellChanged();
                                    }
                                }
                            }
                        }

                        StyledRect {
                            id: addListenerBtn
                            variant: "common"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: MacStyle.radius(-2)

                            Text {
                                anchors.centerIn: parent
                                text: "Add Listener"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                font.bold: true
                                color: addListenerBtn.item
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var list = [];
                                    if (Config.system.idle.listeners) {
                                        for (var i = 0; i < Config.system.idle.listeners.length; i++)
                                            list.push(Config.system.idle.listeners[i]);
                                    }
                                    list.push({
                                        "timeout": 60,
                                        "onTimeout": "",
                                        "onResume": ""
                                    });
                                    Config.system.idle.listeners = list;
                                    GlobalStates.markShellChanged();
                                }
                            }
                        }
                    }

                    // Bottom spacing
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                    }
                }
            }
        }
    }

    // =====================
    // HELPER COMPONENTS
    // =====================

    // Inline component for number input rows
    component NumberInputRow: MacNumberRow {}

    // Inline component for text input rows
    component TextInputRow: MacTextRow {}

    // PrefixRow component for prefix inputs
    component PrefixRow: MacPrefixRow {}

    // ToggleRow component for boolean toggles
    component ToggleRow: MacToggleRow {}
}

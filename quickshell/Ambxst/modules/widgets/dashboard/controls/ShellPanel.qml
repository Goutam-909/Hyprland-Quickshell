pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.config

Item {
    id: root


    // ── macOS restyle: local stand-ins so every control here uses the Mac look ──
    component StyledRect: MacRect {}
    component StyledSlider: MacSlider {}
    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: MacStyle.separator
    }

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    // Available color names for color picker
    readonly property var colorNames: Colors.availableColorNames

    // Color picker state
    property bool colorPickerActive: false
    property var colorPickerColorNames: []
    property string colorPickerCurrentColor: ""
    property string colorPickerDialogTitle: ""
    property var colorPickerCallback: null

    function openColorPicker(colorNames, currentColor, dialogTitle, callback) {
        colorPickerColorNames = colorNames;
        colorPickerCurrentColor = currentColor;
        colorPickerDialogTitle = dialogTitle;
        colorPickerCallback = callback;
        colorPickerActive = true;
    }

    function closeColorPicker() {
        colorPickerActive = false;
        colorPickerCallback = null;
    }

    function handleColorSelected(color) {
        if (colorPickerCallback) {
            colorPickerCallback(color);
        }
        colorPickerCurrentColor = color;
    }

    property string currentSection: ""

    component SectionButton: MacSectionRow {
        id: sectionBtn
        onClicked: root.currentSection = sectionBtn.sectionId
    }

    component ActionButton: MacActionRow {}

    // Inline component for toggle rows
    component ToggleRow: MacToggleRow {}

    // Inline component for number input rows
    component NumberInputRow: MacNumberRow {}

    // Inline component for text input rows
    component TextInputRow: MacTextRow {}

    // Inline component for segmented selector rows
    component SelectorRow: MacSelectorRow {}

    // Inline component for screen list selection
    component ScreenListRow: MacScreenListRow {}

    // Main content
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !root.colorPickerActive

        // Horizontal slide + fade animation
        opacity: root.colorPickerActive ? 0 : 1
        transform: Translate {
            x: root.colorPickerActive ? -30 : 0

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

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
                    title: root.currentSection === "" ? "Shell" : (root.currentSection.charAt(0).toUpperCase() + root.currentSection.slice(1))
                    statusText: GlobalStates.shellHasChanges ? "Unsaved changes" : ""
                    statusColor: MacStyle.destructive

                    actions: {
                        let baseActions = [
                            {
                                icon: Icons.arrowCounterClockwise,
                                tooltip: "Discard changes",
                                enabled: GlobalStates.shellHasChanges,
                                onClicked: function () {
                                    GlobalStates.discardShellChanges();
                                }
                            },
                            {
                                icon: Icons.disk,
                                tooltip: "Apply changes",
                                enabled: GlobalStates.shellHasChanges,
                                onClicked: function () {
                                    GlobalStates.applyShellChanges();
                                }
                            }
                        ];

                        if (root.currentSection !== "") {
                            return [
                                {
                                    icon: Icons.arrowLeft,
                                    tooltip: "Back",
                                    onClicked: function () {
                                        root.currentSection = "";
                                    }
                                }
                            ].concat(baseActions);
                        }

                        // Discard / apply icons only show once you are inside a section
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
                                text: "Bar"
                                sectionId: "bar"
                            }
                            SectionButton {
                                text: "Frame"
                                sectionId: "frame"
                            }
                            SectionButton {
                                text: "Notch"
                                sectionId: "notch"
                            }
                            SectionButton {
                                text: "Workspaces"
                                sectionId: "workspaces"
                            }
                            SectionButton {
                                text: "Overview"
                                sectionId: "overview"
                            }
                            SectionButton {
                                text: "Dock"
                                sectionId: "dock"
                            }
                            SectionButton {
                                text: "Lockscreen"
                                sectionId: "lockscreen"
                            }
                            SectionButton {
                                text: "Desktop"
                                sectionId: "desktop"
                            }
                            SectionButton {
                                text: "System"
                                sectionId: "system"
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // BAR SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "bar"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            SelectorRow {
                                label: ""
                                options: [
                                    {
                                        label: "Top",
                                        value: "top",
                                        icon: Icons.arrowUp
                                    },
                                    {
                                        label: "Bottom",
                                        value: "bottom",
                                        icon: Icons.arrowDown
                                    },
                                    {
                                        label: "Left",
                                        value: "left",
                                        icon: Icons.arrowLeft
                                    },
                                    {
                                        label: "Right",
                                        value: "right",
                                        icon: Icons.arrowRight
                                    }
                                ]
                                value: Config.bar.position ?? "top"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.bar.position) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.position = newValue;
                                    }
                                }
                            }

                            TextInputRow {
                                label: "Launcher Icon"
                                value: Config.bar.launcherIcon ?? ""
                                placeholder: "Symbol or path to icon..."
                                onValueEdited: newValue => {
                                    if (newValue !== Config.bar.launcherIcon) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.launcherIcon = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Launcher Icon Tint"
                                checked: Config.bar.launcherIconTint ?? true
                                onToggled: value => {
                                    if (value !== Config.bar.launcherIconTint) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.launcherIconTint = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Launcher Icon Full Tint"
                                checked: Config.bar.launcherIconFullTint ?? true
                                onToggled: value => {
                                    if (value !== Config.bar.launcherIconFullTint) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.launcherIconFullTint = value;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Launcher Icon Size"
                                value: Config.bar.launcherIconSize ?? 24
                                minValue: 12
                                maxValue: 64
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.bar.launcherIconSize) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.launcherIconSize = newValue;
                                    }
                                }
                            }

                            SelectorRow {
                                label: "Pill Style"
                                options: [
                                    {
                                        label: "Default",
                                        value: "default"
                                    },
                                    {
                                        label: "Squished",
                                        value: "squished"
                                    }
                                ]
                                value: Config.bar.pillStyle ?? "default"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.bar.pillStyle) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.pillStyle = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Use 12h Format"
                                checked: Config.bar.use12hFormat ?? false
                                onToggled: value => {
                                    if (value !== Config.bar.use12hFormat) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.use12hFormat = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Enable Firefox Player"
                                checked: Config.bar.enableFirefoxPlayer ?? false
                                onToggled: value => {
                                    if (value !== Config.bar.enableFirefoxPlayer) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.enableFirefoxPlayer = value;
                                    }
                                }
                            }
                        }


                        MacHeader {
                            text: "Auto-hide"
                        }

                        MacGroup {
                            ToggleRow {
                                label: "Pinned on Startup"
                                checked: Config.bar.pinnedOnStartup ?? true
                                onToggled: value => {
                                    if (value !== Config.bar.pinnedOnStartup) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.pinnedOnStartup = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Hover to Reveal"
                                checked: Config.bar.hoverToReveal ?? true
                                onToggled: value => {
                                    if (value !== Config.bar.hoverToReveal) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.hoverToReveal = value;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Hover Region Height"
                                value: Config.bar.hoverRegionHeight ?? 8
                                minValue: 0
                                maxValue: 32
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.bar.hoverRegionHeight) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.hoverRegionHeight = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Show Pin Button"
                                checked: Config.bar.showPinButton ?? true
                                onToggled: value => {
                                    if (value !== Config.bar.showPinButton) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.showPinButton = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Available on Fullscreen"
                                checked: Config.bar.availableOnFullscreen ?? false
                                onToggled: value => {
                                    if (value !== Config.bar.availableOnFullscreen) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.availableOnFullscreen = value;
                                    }
                                }
                            }

                            ScreenListRow {
                                label: "Screens"
                                selectedScreens: Config.bar.screenList ?? []
                                onScreensChanged: newList => {
                                    GlobalStates.markShellChanged();
                                    Config.bar.screenList = newList;
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // FRAME SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "frame"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            ToggleRow {
                                label: "Enabled"
                                checked: Config.bar.frameEnabled ?? false
                                onToggled: value => {
                                    if (value !== Config.bar.frameEnabled) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.frameEnabled = value;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Thickness"
                                value: Config.bar.frameThickness ?? 6
                                minValue: 1
                                maxValue: 40
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.bar.frameThickness) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.frameThickness = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Contain Bar"
                                checked: Config.bar.containBar ?? false
                                onToggled: value => {
                                    if (value !== Config.bar.containBar) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.containBar = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Keep Bar Shadow"
                                checked: Config.bar.keepBarShadow ?? false
                                visible: Config.bar.containBar ?? false
                                onToggled: value => {
                                    if (value !== Config.bar.keepBarShadow) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.keepBarShadow = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Keep Bar Border"
                                checked: Config.bar.keepBarBorder ?? false
                                visible: Config.bar.containBar ?? false
                                onToggled: value => {
                                    if (value !== Config.bar.keepBarBorder) {
                                        GlobalStates.markShellChanged();
                                        Config.bar.keepBarBorder = value;
                                    }
                                }
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        visible: false
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // NOTCH SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "notch"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            SelectorRow {
                                label: ""
                                options: [
                                    {
                                        label: "Top",
                                        value: "top",
                                        icon: Icons.arrowUp
                                    },
                                    {
                                        label: "Bottom",
                                        value: "bottom",
                                        icon: Icons.arrowDown
                                    }
                                ]
                                value: Config.notch.position ?? "top"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.notch.position) {
                                        GlobalStates.markShellChanged();
                                        Config.notch.position = newValue;
                                    }
                                }
                            }

                            SelectorRow {
                                label: ""
                                options: [
                                    {
                                        label: "Default",
                                        value: "default"
                                    },
                                    {
                                        label: "Island",
                                        value: "island"
                                    }
                                ]
                                value: Config.notch.theme ?? "default"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.notch.theme) {
                                        GlobalStates.markShellChanged();
                                        Config.notch.theme = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Hover Region Height"
                                value: Config.notch.hoverRegionHeight ?? 8
                                minValue: 0
                                maxValue: 32
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.notch.hoverRegionHeight) {
                                        GlobalStates.markShellChanged();
                                        Config.notch.hoverRegionHeight = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Keep Hidden"
                                checked: Config.notch.keepHidden ?? false
                                onToggled: value => {
                                    if (value !== Config.notch.keepHidden) {
                                        GlobalStates.markShellChanged();
                                        Config.notch.keepHidden = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Disable Hover Expansion"
                                checked: Config.notch.disableHoverExpansion ?? true
                                onToggled: value => {
                                    if (value !== Config.notch.disableHoverExpansion) {
                                        GlobalStates.markShellChanged();
                                        Config.notch.disableHoverExpansion = value;
                                    }
                                }
                            }
                        }


                        MacHeader {
                            text: "No Media Display"
                        }

                        MacGroup {
                            SelectorRow {
                                label: ""
                                options: [
                                    {
                                        label: "User@Host",
                                        value: "userHost",
                                        icon: Icons.user
                                    },
                                    {
                                        label: "Compositor",
                                        value: "compositor",
                                        icon: Icons.compositor
                                    },
                                    {
                                        label: "Custom",
                                        value: "custom",
                                        icon: Icons.textT
                                    }
                                ]
                                value: Config.notch.noMediaDisplay ?? "userHost"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.notch.noMediaDisplay) {
                                        GlobalStates.markShellChanged();
                                        Config.notch.noMediaDisplay = newValue;
                                    }
                                }
                            }

                            TextInputRow {
                                label: "Custom Text"
                                visible: Config.notch.noMediaDisplay === "custom"
                                value: Config.notch.customText ?? "Ambxst"
                                placeholder: "Enter text..."
                                onValueEdited: newValue => {
                                    if (newValue !== Config.notch.customText) {
                                        GlobalStates.markShellChanged();
                                        Config.notch.customText = newValue;
                                    }
                                }
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        visible: false
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // WORKSPACES SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "workspaces"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            SelectorRow {
                                label: "Design"
                                options: [
                                    { label: "Classic", value: "classic" },
                                    { label: "Capsule", value: "capsule" }
                                ]
                                value: Config.workspaces.style ?? "classic"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.workspaces.style) {
                                        GlobalStates.markShellChanged();
                                        Config.workspaces.style = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Shown"
                                value: Config.workspaces.shown ?? 10
                                minValue: 1
                                maxValue: 20
                                onValueEdited: newValue => {
                                    if (newValue !== Config.workspaces.shown) {
                                        GlobalStates.markShellChanged();
                                        Config.workspaces.shown = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Show App Icons"
                                checked: Config.workspaces.showAppIcons ?? true
                                onToggled: value => {
                                    if (value !== Config.workspaces.showAppIcons) {
                                        GlobalStates.markShellChanged();
                                        Config.workspaces.showAppIcons = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Always Show Numbers"
                                checked: Config.workspaces.alwaysShowNumbers ?? false
                                onToggled: value => {
                                    if (value !== Config.workspaces.alwaysShowNumbers) {
                                        GlobalStates.markShellChanged();
                                        Config.workspaces.alwaysShowNumbers = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Show Numbers"
                                checked: Config.workspaces.showNumbers ?? false
                                onToggled: value => {
                                    if (value !== Config.workspaces.showNumbers) {
                                        GlobalStates.markShellChanged();
                                        Config.workspaces.showNumbers = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Dynamic"
                                checked: Config.workspaces.dynamic ?? false
                                onToggled: value => {
                                    if (value !== Config.workspaces.dynamic) {
                                        GlobalStates.markShellChanged();
                                        Config.workspaces.dynamic = value;
                                    }
                                }
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        visible: false
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // OVERVIEW SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "overview"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            NumberInputRow {
                                label: "Rows"
                                value: Config.overview.rows ?? 2
                                minValue: 1
                                maxValue: 5
                                onValueEdited: newValue => {
                                    if (newValue !== Config.overview.rows) {
                                        GlobalStates.markShellChanged();
                                        Config.overview.rows = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Columns"
                                value: Config.overview.columns ?? 5
                                minValue: 1
                                maxValue: 10
                                onValueEdited: newValue => {
                                    if (newValue !== Config.overview.columns) {
                                        GlobalStates.markShellChanged();
                                        Config.overview.columns = newValue;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Scale"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                Layout.preferredWidth: 100
                            }

                            StyledSlider {
                                id: overviewScaleSlider
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
                                progressColor: MacStyle.accent
                                tooltipText: `${(value * 0.2).toFixed(2)}`
                                scroll: true
                                stepSize: 0.05  // 0.05 * 0.2 = 0.01 scale steps
                                snapMode: "always"

                                readonly property real configValue: (Config.overview.scale ?? 0.15) / 0.2

                                onConfigValueChanged: {
                                    if (Math.abs(value - configValue) > 0.001) {
                                        value = configValue;
                                    }
                                }

                                Component.onCompleted: value = configValue

                                onValueChanged: {
                                    let newScale = Math.round(value * 0.2 * 100) / 100;  // Round to 2 decimals
                                    if (Math.abs(newScale - (Config.overview.scale ?? 0.15)) > 0.001) {
                                        GlobalStates.markShellChanged();
                                        Config.overview.scale = newScale;
                                    }
                                }
                            }

                            Text {
                                text: ((Config.overview.scale ?? 0.15)).toFixed(2)
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 40
                            }
                        }

                        MacGroup {
                            NumberInputRow {
                                label: "Workspace Spacing"
                                value: Config.overview.workspaceSpacing ?? 4
                                minValue: 0
                                maxValue: 20
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.overview.workspaceSpacing) {
                                        GlobalStates.markShellChanged();
                                        Config.overview.workspaceSpacing = newValue;
                                    }
                                }
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        visible: false
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // DOCK SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "dock"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            ToggleRow {
                                label: "Enabled"
                                checked: Config.dock.enabled ?? false
                                onToggled: value => {
                                    if (value !== Config.dock.enabled) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.enabled = value;
                                    }
                                }
                            }

                            SelectorRow {
                                label: "Position"
                                options: [
                                    {
                                        label: "Top",
                                        value: "top",
                                        icon: Icons.arrowUp
                                    },
                                    {
                                        label: "Bottom",
                                        value: "bottom",
                                        icon: Icons.arrowDown
                                    },
                                    {
                                        label: "Left",
                                        value: "left",
                                        icon: Icons.arrowLeft
                                    },
                                    {
                                        label: "Right",
                                        value: "right",
                                        icon: Icons.arrowRight
                                    }
                                ]
                                value: Config.dock.position ?? "bottom"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.dock.position) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.position = newValue;
                                    }
                                }
                            }

                            SelectorRow {
                                label: "Theme"
                                options: [
                                    {
                                        label: "Default",
                                        value: "default"
                                    },
                                    {
                                        label: "Floating",
                                        value: "floating"
                                    },
                                    {
                                        label: "Integrated",
                                        value: "integrated"
                                    }
                                ]
                                value: Config.dock.theme ?? "default"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.dock.theme) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.theme = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Height"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                value: Config.dock.height ?? 48
                                minValue: 32
                                maxValue: 128
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.dock.height) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.height = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Icon Size"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                value: Config.dock.iconSize ?? 40
                                minValue: 24
                                maxValue: 96
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.dock.iconSize) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.iconSize = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Spacing"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                value: Config.dock.spacing ?? 10
                                minValue: 0
                                maxValue: 32
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.dock.spacing) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.spacing = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Margin"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                value: Config.dock.margin ?? 8
                                minValue: 0
                                maxValue: 32
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.dock.margin) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.margin = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Hover to Reveal"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                checked: Config.dock.hoverToReveal ?? true
                                onToggled: value => {
                                    if (value !== Config.dock.hoverToReveal) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.hoverToReveal = value;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Hover Region"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                value: Config.dock.hoverRegionHeight ?? 8
                                minValue: 0
                                maxValue: 32
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.dock.hoverRegionHeight) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.hoverRegionHeight = newValue;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Pinned on Startup"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                checked: Config.dock.pinnedOnStartup ?? true
                                onToggled: value => {
                                    if (value !== Config.dock.pinnedOnStartup) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.pinnedOnStartup = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Show Pin Button"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                checked: Config.dock.showPinButton ?? true
                                onToggled: value => {
                                    if (value !== Config.dock.showPinButton) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.showPinButton = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Available on Fullscreen"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                checked: Config.dock.availableOnFullscreen ?? false
                                onToggled: value => {
                                    if (value !== Config.dock.availableOnFullscreen) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.availableOnFullscreen = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Keep Hidden"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                checked: Config.dock.keepHidden ?? false
                                onToggled: value => {
                                    if (value !== Config.dock.keepHidden) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.keepHidden = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Show Running Indicators"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                checked: Config.dock.showRunningIndicators ?? true
                                onToggled: value => {
                                    if (value !== Config.dock.showRunningIndicators) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.showRunningIndicators = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Show Overview Button"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                checked: Config.dock.showOverviewButton ?? true
                                onToggled: value => {
                                    if (value !== Config.dock.showOverviewButton) {
                                        GlobalStates.markShellChanged();
                                        Config.dock.showOverviewButton = value;
                                    }
                                }
                            }

                            ScreenListRow {
                                label: "Screens"
                                visible: (Config.dock.theme ?? "default") !== "integrated"
                                selectedScreens: Config.dock.screenList ?? []
                                onScreensChanged: newList => {
                                    GlobalStates.markShellChanged();
                                    Config.dock.screenList = newList;
                                }
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        visible: false
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // LOCKSCREEN SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "lockscreen"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            SelectorRow {
                                label: ""
                                options: [
                                    {
                                        label: "Top",
                                        value: "top",
                                        icon: Icons.arrowUp
                                    },
                                    {
                                        label: "Bottom",
                                        value: "bottom",
                                        icon: Icons.arrowDown
                                    }
                                ]
                                value: Config.lockscreen.position ?? "bottom"
                                onValueSelected: newValue => {
                                    if (newValue !== Config.lockscreen.position) {
                                        GlobalStates.markShellChanged();
                                        Config.lockscreen.position = newValue;
                                    }
                                }
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        visible: false
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // DESKTOP SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "desktop"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            ToggleRow {
                                label: "Show Icons"
                                checked: Config.desktop.iconsEnabled ?? false
                                onToggled: value => {
                                    if (value !== Config.desktop.iconsEnabled) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.iconsEnabled = value;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Icon Size"
                                value: Config.desktop.iconSize ?? 40
                                minValue: 24
                                maxValue: 96
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.desktop.iconSize) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.iconSize = newValue;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Vertical Spacing"
                                value: Config.desktop.spacingVertical ?? 16
                                minValue: 0
                                maxValue: 48
                                suffix: "px"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.desktop.spacingVertical) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.spacingVertical = newValue;
                                    }
                                }
                            }
                        }

                        // Text Color with ColorButton
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Text Color"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                Layout.preferredWidth: 100
                            }

                            ColorButton {
                                id: desktopTextColorButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                colorNames: root.colorNames
                                currentColor: Config.desktop.textColor ?? "overBackground"
                                dialogTitle: "Desktop Text Color"
                                compact: false

                                onOpenColorPicker: (colorNames, currentColor, dialogTitle) => {
                                    root.openColorPicker(colorNames, currentColor, dialogTitle, function (color) {
                                        if (color !== Config.desktop.textColor) {
                                            GlobalStates.markShellChanged();
                                            Config.desktop.textColor = color;
                                        }
                                    });
                                }
                            }
                        }

                        // ── Cava Visualizer ──────────────────────────────────
                        Text {
                            text: "Cava Visualizer"
                            font.family: MacStyle.fontFamily
                            font.pixelSize: MacStyle.fontSize(-2)
                            color: MacStyle.accent
                            font.bold: true
                            Layout.topMargin: 8
                        }

                        MacGroup {
                            ToggleRow {
                                label: "Enabled"
                                checked: Config.desktop.cavaEnabled ?? false
                                onToggled: value => {
                                    if (value !== Config.desktop.cavaEnabled) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaEnabled = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Media Player Visualizer"
                                checked: Config.desktop.cavaPlayerVisualizer ?? true
                                onToggled: value => {
                                    if (value !== Config.desktop.cavaPlayerVisualizer) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaPlayerVisualizer = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Pause Visualizers on Battery"
                                checked: Config.desktop.cavaDisableOnBattery ?? true
                                onToggled: value => {
                                    if (value !== Config.desktop.cavaDisableOnBattery) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaDisableOnBattery = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Show Shadow"
                                checked: Config.desktop.cavaShowShadow ?? true
                                onToggled: value => {
                                    if (value !== Config.desktop.cavaShowShadow) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaShowShadow = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Use Wallpaper Colors"
                                checked: Config.desktop.cavaWallpaperColors ?? false
                                onToggled: value => {
                                    if (value !== Config.desktop.cavaWallpaperColors) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaWallpaperColors = value;
                                    }
                                }
                            }

                            NumberInputRow {
                                label: "Bar Count"
                                value: Config.desktop.cavaBarCount ?? 40
                                minValue: 10
                                maxValue: 200
                                suffix: "bars"
                                onValueEdited: newValue => {
                                    if (newValue !== Config.desktop.cavaBarCount) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaBarCount = newValue;
                                    }
                                }
                            }

                            SelectorRow {
                                label: "Rotation"
                                options: [
                                    { label: "0°",   value: "0"   },
                                    { label: "90°",  value: "90"  },
                                    { label: "180°", value: "180" },
                                    { label: "270°", value: "270" }
                                ]
                                value: String(Config.desktop.cavaRotation ?? 0)
                                onValueSelected: newValue => {
                                    const v = parseInt(newValue);
                                    if (v !== Config.desktop.cavaRotation) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaRotation = v;
                                    }
                                }
                            }
                        }

                        // Intensity
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Intensity"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                Layout.preferredWidth: 100
                            }

                            StyledSlider {
                                // StyledSlider is always 0-1; map intensity range [0.1, 3.0] manually
                                readonly property real intensityMin: 0.1
                                readonly property real intensityMax: 3.0
                                readonly property real intensitySpan: intensityMax - intensityMin

                                Layout.fillWidth: true
                                stepSize: 0.05 / intensitySpan  // step of 0.05 in intensity space
                                value: ((Config.desktop.cavaVisualizerIntensity ?? 1.0) - intensityMin) / intensitySpan
                                onValueChanged: {
                                    let actual = Math.round((value * intensitySpan + intensityMin) * 100) / 100;
                                    actual = Math.max(intensityMin, Math.min(intensityMax, actual));
                                    if (Math.abs(actual - (Config.desktop.cavaVisualizerIntensity ?? 1.0)) > 0.001) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaVisualizerIntensity = actual;
                                    }
                                }
                            }

                            Text {
                                text: (Config.desktop.cavaVisualizerIntensity ?? 1.0).toFixed(2)
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.labelSecondary
                                Layout.preferredWidth: 36
                            }
                        }

                        // Opacity
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Opacity"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                Layout.preferredWidth: 100
                            }

                            StyledSlider {
                                // Opacity is already 0-1, matches StyledSlider's native range
                                Layout.fillWidth: true
                                stepSize: 0.05
                                value: Config.desktop.cavaOpacity ?? 1.0
                                onValueChanged: {
                                    let rounded = Math.round(value * 100) / 100;
                                    if (Math.abs(rounded - (Config.desktop.cavaOpacity ?? 1.0)) > 0.001) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.cavaOpacity = rounded;
                                    }
                                }
                            }

                            Text {
                                text: (Config.desktop.cavaOpacity ?? 1.0).toFixed(2)
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.labelSecondary
                                Layout.preferredWidth: 36
                            }
                        }

                        // Gradient colors — hidden when wallpaper colors is on
                        ColumnLayout {
                            visible: !(Config.desktop.cavaWallpaperColors ?? false)
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Gradient Colors"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(-2)
                                color: MacStyle.labelSecondary
                                font.weight: Font.Medium
                            }

                            MacGroup {
                                TextInputRow {
                                    label: "Start"
                                    value: Config.desktop.cavaGradientStart ?? "#4158D0"
                                    placeholder: "#4158D0"
                                    onValueEdited: newValue => {
                                        if (newValue !== Config.desktop.cavaGradientStart) {
                                            GlobalStates.markShellChanged();
                                            Config.desktop.cavaGradientStart = newValue;
                                        }
                                    }
                                }

                                TextInputRow {
                                    label: "Mid 1"
                                    value: Config.desktop.cavaGradientMid1 ?? "#C850C0"
                                    placeholder: "#C850C0"
                                    onValueEdited: newValue => {
                                        if (newValue !== Config.desktop.cavaGradientMid1) {
                                            GlobalStates.markShellChanged();
                                            Config.desktop.cavaGradientMid1 = newValue;
                                        }
                                    }
                                }

                                TextInputRow {
                                    label: "Mid 2"
                                    value: Config.desktop.cavaGradientMid2 ?? "#FFCC70"
                                    placeholder: "#FFCC70"
                                    onValueEdited: newValue => {
                                        if (newValue !== Config.desktop.cavaGradientMid2) {
                                            GlobalStates.markShellChanged();
                                            Config.desktop.cavaGradientMid2 = newValue;
                                        }
                                    }
                                }

                                TextInputRow {
                                    label: "End"
                                    value: Config.desktop.cavaGradientEnd ?? "#ffe53b"
                                    placeholder: "#ffe53b"
                                    onValueEdited: newValue => {
                                        if (newValue !== Config.desktop.cavaGradientEnd) {
                                            GlobalStates.markShellChanged();
                                            Config.desktop.cavaGradientEnd = newValue;
                                        }
                                    }
                                }
                            }
                        }

                        // ── Clock Widget ──────────────────────────────────────
                        Text {
                            text: "Clock Widget"
                            font.family: MacStyle.fontFamily
                            font.pixelSize: MacStyle.fontSize(-2)
                            color: MacStyle.accent
                            font.bold: true
                            Layout.topMargin: 8
                        }

                        MacGroup {
                            ToggleRow {
                                label: "Enabled"
                                checked: Config.desktop.clockEnabled ?? false
                                onToggled: value => {
                                    if (value !== Config.desktop.clockEnabled) {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.clockEnabled = value;
                                        Config.saveDesktop();
                                    }
                                }
                            }
                        }

                        // Clock color picker row
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: Config.desktop.clockEnabled ?? false

                            Text {
                                text: "Color"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(-1)
                                font.weight: Font.Medium
                                color: MacStyle.labelSecondary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // ── Auto button ───────────────────────────────
                                StyledRect {
                                    id: clockAutoBtn
                                    readonly property bool isAuto: (Config.desktop.clockColor ?? "auto") === "auto"
                                    property bool isHovered: false

                                    variant: isAuto ? "primary" : (isHovered ? "focus" : "common")
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 48
                                    radius: MacStyle.radius(-1)

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            width: 14; height: 14
                                            radius: 7
                                            color: Colors.primary
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.25)
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "Auto"
                                            font.family: MacStyle.fontFamily
                                            font.pixelSize: MacStyle.fontSize(-2)
                                            font.bold: clockAutoBtn.isAuto
                                            color: clockAutoBtn.isAuto
                                            ? MacStyle.accent
                                            : Colors.overSurfaceVariant
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: clockAutoBtn.isHovered = true
                                        onExited:  clockAutoBtn.isHovered = false
                                        onClicked: {
                                            if (Config.desktop.clockColor !== "auto") {
                                                GlobalStates.markShellChanged();
                                                Config.desktop.clockColor = "auto";
                                                Config.saveDesktop();
                                            }
                                        }
                                    }
                                }

                                // ── Specific colour picker ────────────────────
                                ColorButton {
                                    id: clockColorButton
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    colorNames: root.colorNames
                                    currentColor: (Config.desktop.clockColor ?? "auto") === "auto"
                                    ? "primary"
                                    : Config.desktop.clockColor
                                    dialogTitle: "Clock Color"
                                    compact: false

                                    onOpenColorPicker: (colorNames, currentColor, dialogTitle) => {
                                        root.openColorPicker(colorNames, currentColor, dialogTitle, function (color) {
                                            if (color !== Config.desktop.clockColor) {
                                                GlobalStates.markShellChanged();
                                                Config.desktop.clockColor = color;
                                                Config.saveDesktop();
                                            }
                                        });
                                    }
                                }
                            }
                        }

                        // Position hint (read-only; drag the widget to reposition)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: Config.desktop.clockEnabled ?? false

                            Text {
                                text: "Position"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.label
                                Layout.preferredWidth: 100
                            }

                            Text {
                                text: "X " + Math.round(Config.desktop.clockX ?? 0)
                                + "  Y " + Math.round(Config.desktop.clockY ?? 0)
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.labelSecondary
                            }

                            Item { Layout.fillWidth: true }

                            // Reset position button
                            StyledRect {
                                id: resetPosBtn
                                property bool isHovered: false
                                variant: isHovered ? "focus" : "common"
                                Layout.preferredWidth: resetPosLabel.implicitWidth + 24
                                Layout.preferredHeight: 32
                                radius: MacStyle.radius(-2)

                                Text {
                                    id: resetPosLabel
                                    anchors.centerIn: parent
                                    text: "Reset"
                                    font.family: MacStyle.fontFamily
                                    font.pixelSize: MacStyle.fontSize(-1)
                                    color: MacStyle.label
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: resetPosBtn.isHovered = true
                                    onExited:  resetPosBtn.isHovered = false
                                    onClicked: {
                                        GlobalStates.markShellChanged();
                                        Config.desktop.clockX = 0;
                                        Config.desktop.clockY = 0;
                                        Config.saveDesktop();
                                    }
                                }
                            }
                        }
                    }

                    Separator {
                        Layout.fillWidth: true
                        visible: false
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // SYSTEM SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === "system"
                        Layout.fillWidth: true
                        spacing: 8


                        MacGroup {
                            ToggleRow {
                                label: "Update Service"
                                checked: Config.system.updateServiceEnabled ?? true
                                onToggled: value => {
                                    if (value !== Config.system.updateServiceEnabled) {
                                        GlobalStates.markShellChanged();
                                        Config.system.updateServiceEnabled = value;
                                    }
                                }
                            }

                            ActionButton {
                                text: "About Ambxst " + Config.version
                                icon: Icons.info
                                onClicked: Quickshell.execDetached(["xdg-open", "https://axeni.de/ambxst"])
                            }

                            ActionButton {
                                text: "Donate ❤️"
                                icon: Icons.heart
                                onClicked: Quickshell.execDetached(["xdg-open", "https://axeni.de/donate"])
                            }
                        }

                        Text {
                            text: "OCR Languages"
                            font.family: MacStyle.fontFamily
                            font.pixelSize: MacStyle.fontSize(-2)
                            color: MacStyle.accent
                            font.bold: true
                            Layout.topMargin: 8
                        }

                        MacGroup {
                            ToggleRow {
                                label: "English"
                                checked: Config.system.ocr.eng ?? true
                                onToggled: value => {
                                    if (value !== Config.system.ocr.eng) {
                                        GlobalStates.markShellChanged();
                                        Config.system.ocr.eng = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Spanish"
                                checked: Config.system.ocr.spa ?? true
                                onToggled: value => {
                                    if (value !== Config.system.ocr.spa) {
                                        GlobalStates.markShellChanged();
                                        Config.system.ocr.spa = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Latin"
                                checked: Config.system.ocr.lat ?? false
                                onToggled: value => {
                                    if (value !== Config.system.ocr.lat) {
                                        GlobalStates.markShellChanged();
                                        Config.system.ocr.lat = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Japanese"
                                checked: Config.system.ocr.jpn ?? false
                                onToggled: value => {
                                    if (value !== Config.system.ocr.jpn) {
                                        GlobalStates.markShellChanged();
                                        Config.system.ocr.jpn = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Chinese (Simplified)"
                                checked: Config.system.ocr.chi_sim ?? false
                                onToggled: value => {
                                    if (value !== Config.system.ocr.chi_sim) {
                                        GlobalStates.markShellChanged();
                                        Config.system.ocr.chi_sim = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Chinese (Traditional)"
                                checked: Config.system.ocr.chi_tra ?? false
                                onToggled: value => {
                                    if (value !== Config.system.ocr.chi_tra) {
                                        GlobalStates.markShellChanged();
                                        Config.system.ocr.chi_tra = value;
                                    }
                                }
                            }

                            ToggleRow {
                                label: "Korean"
                                checked: Config.system.ocr.kor ?? false
                                onToggled: value => {
                                    if (value !== Config.system.ocr.kor) {
                                        GlobalStates.markShellChanged();
                                        Config.system.ocr.kor = value;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Color picker view (shown when colorPickerActive)
    Item {
        id: colorPickerContainer
        anchors.fill: parent
        clip: true

        // Horizontal slide + fade animation (enters from right)
        opacity: root.colorPickerActive ? 1 : 0
        transform: Translate {
            x: root.colorPickerActive ? 0 : 30

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

        // Prevent interaction when hidden
        enabled: root.colorPickerActive

        // Block interaction with elements behind when active
        MouseArea {
            anchors.fill: parent
            enabled: root.colorPickerActive
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onPressed: event => event.accepted = true
            onReleased: event => event.accepted = true
            onWheel: event => event.accepted = true
        }

        ColorPickerView {
            id: colorPickerContent
            anchors.fill: parent
            anchors.leftMargin: root.sideMargin
            anchors.rightMargin: root.sideMargin
            colorNames: root.colorPickerColorNames
            currentColor: root.colorPickerCurrentColor
            dialogTitle: root.colorPickerDialogTitle

            onColorSelected: color => root.handleColorSelected(color)
            onClosed: root.closeColorPicker()
        }
    }
}

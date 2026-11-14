pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.config

Item {
    id: root


    // ── macOS restyle: local stand-ins so every control here uses the Mac look ──
    component StyledRect: MacRect {}
    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: MacStyle.separator
    }

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    property string currentSection: ""

    component SectionButton: MacSectionRow {
        id: sectionBtn
        onClicked: root.currentSection = sectionBtn.sectionId
    }

    // Available color names for color picker
    readonly property var colorNames: Colors.availableColorNames

    // Color picker state
    property bool colorPickerActive: false
    property var colorPickerColorNames: []
    property string colorPickerCurrentColor: ""
    property string colorPickerDialogTitle: ""
    property var colorPickerCallback: null

    function openColorPicker(colorNames, currentColor, dialogTitle, callback) {
        // Ensure colorNames is a valid array for QML
        colorPickerColorNames = colorNames;
        // Ensure currentColor is a string
        colorPickerCurrentColor = currentColor.toString();
        // Ensure dialogTitle is a string
        colorPickerDialogTitle = dialogTitle ? dialogTitle.toString() : "";
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

    // Inline component for toggle rows
    component ToggleRow: MacToggleRow {}

    // Inline component for number input rows
    component NumberInputRow: MacNumberRow {}

    // Inline component for decimal input rows
    component DecimalInputRow: MacDecimalRow {}

    // Inline component for Border Gradients (Multi-color list)
    component BorderGradientRow: ColumnLayout {
        id: gradientRow
        property string label: ""
        property var colors: []
        property string dialogTitle: ""
        property bool enabled: true
        signal colorsEdited(var newColors)

        spacing: 8
        Layout.fillWidth: true
        opacity: enabled ? 1.0 : 0.5

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: gradientRow.label
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fontSize(0)
                color: MacStyle.label
                Layout.fillWidth: true
            }
            Text {
                text: "Right click to remove"
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fontSize(-2)
                color: MacStyle.labelSecondary
                visible: gradientRow.colors.length > 1
            }
        }

        // Color List
        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                id: colorsRepeater
                model: gradientRow.colors
                delegate: MouseArea {
                    width: 32
                    height: 32
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    required property int index
                    required property var modelData

                    // Swatch
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Config.resolveColor(parent.modelData)
                        border.width: 2
                        border.color: parent.containsMouse ? MacStyle.accent : Colors.outline

                        // Inner check for visual depth
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 4
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Colors.surface
                            opacity: 0.3
                        }
                    }

                    // Tooltip
                    StyledToolTip {
                        text: parent.modelData.toString()
                        visible: parent.containsMouse && !contextMenu.visible
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            // Remove color (if more than 1)
                            if (gradientRow.colors.length > 1) {
                                let newColors = [...gradientRow.colors];
                                newColors.splice(index, 1);
                                gradientRow.colorsEdited(newColors);
                            }
                        } else {
                            // Edit color
                            root.openColorPicker(root.colorNames, modelData, gradientRow.dialogTitle, function (selectedColor) {
                                let newColors = [...gradientRow.colors];
                                newColors[index] = selectedColor;
                                gradientRow.colorsEdited(newColors);
                            });
                        }
                    }
                }
            }
            StyledRect {
                width: 32
                height: 32
                radius: 16
                variant: "common"
                color: mouseAreaAdd.containsMouse ? Colors.surfaceBright : Colors.surface
                border.width: 1
                border.color: Colors.outline

                Text {
                    anchors.centerIn: parent
                    text: Icons.plus
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: MacStyle.labelSecondary
                }

                MouseArea {
                    id: mouseAreaAdd
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        let newColors = [...gradientRow.colors];
                        // Duplicate last color or default to primary
                        let colorToAdd = newColors.length > 0 ? newColors[newColors.length - 1] : "primary";
                        newColors.push(colorToAdd);
                        gradientRow.colorsEdited(newColors);
                    }
                }
            }
        }
    }

    // Inline component for Compositor Tabs
    component CompositorTabButton: MacTabButton {}

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
                    title: root.currentSection === "" ? "Compositor" : (root.currentSection.charAt(0).toUpperCase() + root.currentSection.slice(1))
                    statusText: GlobalStates.compositorHasChanges ? "Unsaved changes" : ""
                    statusColor: MacStyle.destructive

                    actions: {
                        let baseActions = [
                            {
                                icon: Icons.arrowCounterClockwise,
                                tooltip: "Discard changes",
                                enabled: GlobalStates.compositorHasChanges,
                                onClicked: function () {
                                    GlobalStates.discardCompositorChanges();
                                }
                            },
                            {
                                icon: Icons.disk,
                                tooltip: "Apply changes",
                                enabled: GlobalStates.compositorHasChanges,
                                onClicked: function () {
                                    GlobalStates.applyCompositorChanges();
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

            // Tabs Switch
            Item {
                visible: root.currentSection === ""
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    CompositorTabButton {
                        label: "Hyprland"
                        image: Qt.resolvedUrl("../../../../assets/compositors/hyprland.svg")
                        isSelected: stackLayout.currentIndex === 0
                        onClicked: stackLayout.currentIndex = 0
                    }

                    CompositorTabButton {
                        label: "Coming Soon"
                        icon: Icons.clock
                        isSelected: stackLayout.currentIndex === 1
                        onClicked: stackLayout.currentIndex = 1
                    }
                }
            }

            // Stack for content
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: stackLayout.height

                StackLayout {
                    id: stackLayout
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: currentIndex === 0 ? hyprlandPage.implicitHeight : placeholderPage.implicitHeight
                    currentIndex: 0

                    // ═══════════════════════════════════════════════════════════════
                    // HYPRLAND TAB
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        id: hyprlandPage
                        Layout.fillWidth: true
                        spacing: 16

                        // Menu Section
                        ColumnLayout {
                            visible: root.currentSection === ""
                            Layout.fillWidth: true
                            spacing: 8

                            MacGroup {
                                SectionButton {
                                    text: "General"
                                    sectionId: "general"
                                }
                                SectionButton {
                                    text: "Colors"
                                    sectionId: "colors"
                                }
                                SectionButton {
                                    text: "Shadows"
                                    sectionId: "shadows"
                                }
                                SectionButton {
                                    text: "Blur"
                                    sectionId: "blur"
                                }
                            }
                        }

                        // General Section
                        ColumnLayout {
                            visible: root.currentSection === "general"
                            Layout.fillWidth: true
                            spacing: 8


                            MacGroup {
                                ToggleRow {
                                    label: "Sync Border Size"
                                    checked: Config.hyprland.syncBorderWidth ?? false
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.syncBorderWidth = value;
                                    }
                                }

                                NumberInputRow {
                                    label: "Border Size"
                                    value: Config.hyprland.borderSize ?? 2
                                    minValue: 0
                                    maxValue: 999
                                    suffix: "px"
                                    enabled: !Config.hyprland.syncBorderWidth
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.borderSize = newValue;
                                    }
                                }

                                ToggleRow {
                                    label: "Sync Rounding"
                                    checked: Config.hyprland.syncRoundness ?? true
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.syncRoundness = value;
                                    }
                                }

                                NumberInputRow {
                                    label: "Rounding"
                                    value: Config.hyprland.rounding ?? 16
                                    minValue: 0
                                    maxValue: 999
                                    suffix: "px"
                                    enabled: !Config.hyprland.syncRoundness
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.rounding = newValue;
                                    }
                                }

                                NumberInputRow {
                                    label: "Gaps In"
                                    value: Config.hyprland.gapsIn ?? 5
                                    minValue: 0
                                    maxValue: 50
                                    suffix: "px"
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.gapsIn = newValue;
                                    }
                                }

                                NumberInputRow {
                                    label: "Gaps Out"
                                    value: Config.hyprland.gapsOut ?? 10
                                    minValue: 0
                                    maxValue: 50
                                    suffix: "px"
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.gapsOut = newValue;
                                    }
                                }

                                NumberInputRow {
                                    label: "Border Angle"
                                    value: Config.hyprland.borderAngle ?? 45
                                    minValue: 0
                                    maxValue: 360
                                    suffix: "deg"
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.borderAngle = newValue;
                                    }
                                }

                                NumberInputRow {
                                    label: "Inactive Angle"
                                    value: Config.hyprland.inactiveBorderAngle ?? 45
                                    minValue: 0
                                    maxValue: 360
                                    suffix: "deg"
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.inactiveBorderAngle = newValue;
                                    }
                                }
                            }
                        }

                        Separator {
                            Layout.fillWidth: true
                            visible: false
                        }

                        // Colors Section
                        ColumnLayout {
                            visible: root.currentSection === "colors"
                            Layout.fillWidth: true
                            spacing: 8


                            MacGroup {
                                ToggleRow {
                                    label: "Sync Border Color"
                                    checked: Config.hyprland.syncBorderColor ?? false
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.syncBorderColor = value;
                                    }
                                }
                            }

                            // Active Border Color
                            BorderGradientRow {
                                label: "Active Border"
                                colors: Config.hyprland.activeBorderColor || ["primary"]
                                dialogTitle: "Edit Active Border Color"
                                enabled: !Config.hyprland.syncBorderColor
                                onColorsEdited: newColors => {
                                    GlobalStates.markCompositorChanged();
                                    Config.hyprland.activeBorderColor = newColors;
                                }
                            }

                            // Inactive Border Color
                            BorderGradientRow {
                                label: "Inactive Border"
                                colors: Config.hyprland.inactiveBorderColor || ["surface"]
                                dialogTitle: "Edit Inactive Border Color"
                                onColorsEdited: newColors => {
                                    GlobalStates.markCompositorChanged();
                                    Config.hyprland.inactiveBorderColor = newColors;
                                }
                            }
                        }

                        Separator {
                            Layout.fillWidth: true
                            visible: false
                        }

                        // Shadows Section
                        ColumnLayout {
                            visible: root.currentSection === "shadows"
                            Layout.fillWidth: true
                            spacing: 8


                            MacGroup {
                                ToggleRow {
                                    label: "Enabled"
                                    checked: Config.hyprland.shadowEnabled ?? true
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.shadowEnabled = value;
                                    }
                                }

                                ToggleRow {
                                    label: "Sync Color"
                                    checked: Config.hyprland.syncShadowColor ?? false
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.syncShadowColor = value;
                                    }
                                }

                                ToggleRow {
                                    label: "Sync Opacity"
                                    checked: Config.hyprland.syncShadowOpacity ?? false
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.syncShadowOpacity = value;
                                    }
                                }

                                NumberInputRow {
                                    label: "Range"
                                    value: Config.hyprland.shadowRange ?? 4
                                    minValue: 0
                                    maxValue: 100
                                    suffix: "px"
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.shadowRange = newValue;
                                    }
                                }

                                NumberInputRow {
                                    label: "Offset X"
                                    value: parseInt((Config.hyprland.shadowOffset ?? "0 0").split(" ")[0]) || 0
                                    minValue: -50
                                    maxValue: 50
                                    suffix: "px"
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        let parts = (Config.hyprland.shadowOffset ?? "0 0").split(" ");
                                        let y = parts.length > 1 ? parts[1] : "0";
                                        Config.hyprland.shadowOffset = newValue + " " + y;
                                    }
                                }

                                NumberInputRow {
                                    label: "Offset Y"
                                    value: parseInt((Config.hyprland.shadowOffset ?? "0 0").split(" ")[1]) || 0
                                    minValue: -50
                                    maxValue: 50
                                    suffix: "px"
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        let parts = (Config.hyprland.shadowOffset ?? "0 0").split(" ");
                                        let x = parts.length > 0 ? parts[0] : "0";
                                        Config.hyprland.shadowOffset = x + " " + newValue;
                                    }
                                }

                                NumberInputRow {
                                    label: "Render Power"
                                    value: Config.hyprland.shadowRenderPower ?? 3
                                    minValue: 1
                                    maxValue: 4
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.shadowRenderPower = newValue;
                                    }
                                }

                                DecimalInputRow {
                                    label: "Scale"
                                    value: Config.hyprland.shadowScale ?? 1.0
                                    minValue: 0.0
                                    maxValue: 1.0
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.shadowScale = newValue;
                                    }
                                }

                                DecimalInputRow {
                                    label: "Opacity"
                                    value: Config.hyprland.shadowOpacity ?? 0.5
                                    minValue: 0.0
                                    maxValue: 1.0
                                    enabled: !Config.hyprland.syncShadowOpacity
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.shadowOpacity = newValue;
                                    }
                                }

                                ToggleRow {
                                    label: "Sharp"
                                    checked: Config.hyprland.shadowSharp ?? false
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.shadowSharp = value;
                                    }
                                }

                                ToggleRow {
                                    label: "Ignore Window"
                                    checked: Config.hyprland.shadowIgnoreWindow ?? true
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.shadowIgnoreWindow = value;
                                    }
                                }
                            }
                        }

                        Separator {
                            Layout.fillWidth: true
                            visible: false
                        }

                        // Blur Section
                        ColumnLayout {
                            visible: root.currentSection === "blur"
                            Layout.fillWidth: true
                            spacing: 8


                            MacGroup {
                                ToggleRow {
                                    label: "Enabled"
                                    checked: Config.hyprland.blurEnabled ?? true
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurEnabled = value;
                                    }
                                }

                                NumberInputRow {
                                    label: "Size"
                                    value: Config.hyprland.blurSize ?? 8
                                    minValue: 0
                                    maxValue: 20
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurSize = newValue;
                                    }
                                }

                                NumberInputRow {
                                    label: "Passes"
                                    value: Config.hyprland.blurPasses ?? 1
                                    minValue: 0
                                    maxValue: 4
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurPasses = newValue;
                                    }
                                }

                                ToggleRow {
                                    label: "Xray"
                                    checked: Config.hyprland.blurXray ?? false
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurXray = value;
                                    }
                                }

                                ToggleRow {
                                    label: "New Optimizations"
                                    checked: Config.hyprland.blurNewOptimizations ?? true
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurNewOptimizations = value;
                                    }
                                }

                                ToggleRow {
                                    label: "Ignore Opacity"
                                    checked: Config.hyprland.blurIgnoreOpacity ?? true
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurIgnoreOpacity = value;
                                    }
                                }

                                ToggleRow {
                                    label: "Explicit Ignorealpha"
                                    checked: Config.hyprland.blurExplicitIgnoreAlpha ?? false
                                    onToggled: value => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurExplicitIgnoreAlpha = value;
                                    }
                                }

                                DecimalInputRow {
                                    label: "Ignorealpha Value"
                                    value: Config.hyprland.blurIgnoreAlphaValue ?? 0.2
                                    minValue: 0.0
                                    maxValue: 1.0
                                    enabled: Config.hyprland.blurExplicitIgnoreAlpha
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurIgnoreAlphaValue = newValue;
                                    }
                                }

                                DecimalInputRow {
                                    label: "Noise"
                                    value: Config.hyprland.blurNoise ?? 0.01
                                    minValue: 0.0
                                    maxValue: 1.0
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurNoise = newValue;
                                    }
                                }

                                DecimalInputRow {
                                    label: "Contrast"
                                    value: Config.hyprland.blurContrast ?? 0.89
                                    minValue: 0.0
                                    maxValue: 2.0
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurContrast = newValue;
                                    }
                                }

                                DecimalInputRow {
                                    label: "Brightness"
                                    value: Config.hyprland.blurBrightness ?? 0.81
                                    minValue: 0.0
                                    maxValue: 2.0
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurBrightness = newValue;
                                    }
                                }

                                DecimalInputRow {
                                    label: "Vibrancy"
                                    value: Config.hyprland.blurVibrancy ?? 0.17
                                    minValue: 0.0
                                    maxValue: 1.0
                                    onValueEdited: newValue => {
                                        GlobalStates.markCompositorChanged();
                                        Config.hyprland.blurVibrancy = newValue;
                                    }
                                }
                            }
                        }

                        // Bottom Padding
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16
                        }
                    }

                    // ═══════════════════════════════════════════════════════════════
                    // COMING SOON TAB
                    // ═══════════════════════════════════════════════════════════════
                    Item {
                        id: placeholderPage
                        Layout.fillWidth: true
                        implicitHeight: 300

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 16

                            Text {
                                text: Icons.clock
                                font.family: Icons.font
                                font.pixelSize: 64
                                color: Colors.surfaceVariant
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Coming Soon"
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(2)
                                font.bold: true
                                color: MacStyle.label
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Support for more compositors\nis planned for future updates."
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fontSize(0)
                                color: MacStyle.labelSecondary
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
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

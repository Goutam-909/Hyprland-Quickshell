pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.config
import qs.modules.widgets.dashboard.controls

// Fixed-size viewport. Pages slide horizontally like Windows 11 Quick Settings:
// clicking the Wi-Fi / Bluetooth chevron slides the whole view left to a sub-page.
// The back arrow slides back. Popup height never changes.
Item {
    id: root

    // "none" | "wifi" | "bt"
    property string activePage: "none"

    // Called by ControlCenterButton when popup closes — resets to main page
    function resetPages() {
        activePage = "none"
    }

    // ── Shared wifi icon — single source of truth used by tile AND bar button ─
    // Also used in ControlCenterButton via the same NetworkService properties.
    readonly property string wifiIcon: {
        if (!NetworkService.wifiEnabled)                   return Icons.wifiOff
            if (NetworkService.wifiStatus === "connecting")    return Icons.wifiLow
                const s = NetworkService.networkStrength
                if (s > 80) return Icons.wifiHigh
                    if (s > 55) return Icons.wifiMedium
                        if (s > 30) return Icons.wifiLow
                            if (s > 0)  return Icons.wifiNone
                                return NetworkService.wifi ? Icons.wifiNone : Icons.wifiOff
    }

    // ── Popup-gated refresh timer ─────────────────────────────────────────────
    // Fires every 3 s while the control center is open; completely stops when closed.
    property bool popupVisible: false   // set by ControlCenterButton via binding

    Timer {
        id: refreshTimer
        interval: 3000
        repeat:   true
        running:  root.popupVisible
        onTriggered: {
            NetworkService.update()
            BluetoothService.updateStatus()
        }
    }

    clip: true

    // ── Sliding container ─────────────────────────────────────────────────────
    Item {
        id: slideContainer
        width: root.width
        height: root.height
        clip: true

        Item {
            id: pageStrip
            width: root.width * 2
            height: parent.height

            x: root.activePage !== "none" ? -(pageStrip.width / 2) : 0
            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
            }

            // ────────────────────────────────────────────────────────────────────
            // PAGE 1 — Main quick-settings
            // ────────────────────────────────────────────────────────────────────
            Item {
                id: mainPage
                x: 0
                width: pageStrip.width / 2
                height: root.height

                Flickable {
                    id: mainFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: mainCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: mainCol
                        width: mainFlick.width
                        spacing: 0

                        // ── Header: tools left · screenshot + lock + power right ─
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12

                            // Tools — left side
                            Row {
                                anchors.left:           parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                CCHeaderBtn {
                                    icon:      Icons.toolbox
                                    onClicked: { /* TODO: open tools */ }
                                }
                            }

                            // Screenshot + Lock + Power — right side
                            Row {
                                anchors.right:          parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                // Screenshot button (placeholder)
                                CCHeaderBtn {
                                    icon:      Icons.regionScreenshot
                                    onClicked: { /* TODO: take screenshot */ }
                                }

                                // Lock button (placeholder)
                                CCHeaderBtn {
                                    icon:      Icons.lock
                                    onClicked: { /* TODO: lock screen */ }
                                }

                                // Power button (placeholder)
                                CCHeaderBtn {
                                    icon:      Icons.shutdown
                                    onClicked: { /* TODO: open power menu */ }
                                }
                            }
                        }

                        // ── Toggle grid ─────────────────────────────────────────
                        Item {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.bottomMargin: 12
                            implicitHeight: tileGrid.implicitHeight

                            GridLayout {
                                id: tileGrid
                                anchors { left: parent.left; right: parent.right }
                                columns: 2
                                rowSpacing: 8
                                columnSpacing: 8

                                // Wi-Fi
                                CCToggleTile {
                                    Layout.fillWidth: true
                                    icon: root.wifiIcon
                                    label:     "Wi-Fi"
                                    sublabel:  NetworkService.wifiEnabled
                                    ? (NetworkService.networkName !== "" ? NetworkService.networkName : "On")
                                    : "Off"
                                    active:    NetworkService.wifiEnabled
                                    hasChevron: true
                                    onToggled:        NetworkService.enableWifi(!NetworkService.wifiEnabled)
                                    onChevronClicked: root.activePage = "wifi"
                                }

                                // Bluetooth
                                CCToggleTile {
                                    Layout.fillWidth: true
                                    icon:     BluetoothService.enabled
                                    ? (BluetoothService.connected ? Icons.bluetoothConnected : Icons.bluetooth)
                                    : Icons.bluetoothOff
                                    label:    "Bluetooth"
                                    sublabel: BluetoothService.enabled
                                    ? (BluetoothService.connected
                                    ? BluetoothService.connectedDevices + " connected"
                                    : "On")
                                    : "Off"
                                    active:   BluetoothService.enabled
                                    hasChevron: true
                                    onToggled:        BluetoothService.toggle()
                                    onChevronClicked: root.activePage = "bt"
                                }

                                // Do Not Disturb — wired to Notifications.silent
                                CCToggleTile {
                                    Layout.fillWidth: true
                                    icon:     Notifications.silent ? Icons.bellSlash : Icons.bell
                                    label:    "Do Not Disturb"
                                    sublabel: Notifications.silent ? "On" : "Off"
                                    active:   Notifications.silent
                                    onToggled: Notifications.silent = !Notifications.silent
                                }

                                // Caffeine — wired to CaffeineService (idle inhibitor)
                                CCToggleTile {
                                    Layout.fillWidth: true
                                    icon:     Icons.caffeine
                                    label:    "Caffeine"
                                    sublabel: CaffeineService.inhibit ? "Screen on" : "Off"
                                    active:   CaffeineService.inhibit
                                    onToggled: CaffeineService.toggleInhibit()
                                }

                                // Night Light — placeholder (wire to hyprsunset/gammastep if available)
                                CCToggleTile {
                                    id: nightLightTile
                                    Layout.fillWidth: true
                                    icon:     active ? Icons.moon : Icons.nightLight
                                    label:    "Night Light"
                                    sublabel: active ? "On" : "Off"
                                    active:   false
                                    onToggled: active = !active
                                }

                                // Hotspot — placeholder
                                CCToggleTile {
                                    Layout.fillWidth: true
                                    icon:     Icons.router
                                    label:    "Hotspot"
                                    sublabel: active ? "On" : "Off"
                                    active:   false
                                    onToggled: active = !active
                                }
                            }
                        }

                        // ── Divider ─────────────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Colors.outline
                            opacity: 0.18
                        }

                        // ── Sliders section ─────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 16
                            Layout.rightMargin: 16
                            Layout.topMargin: 12
                            Layout.bottomMargin: 14
                            spacing: 14

                            // ── Volume (AudioVolumeEntry-style) ─────────────────
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                // Name row: label ··· muted/percentage
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: "Volume"
                                        font.family:    Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overSurfaceVariant
                                    }
                                    Separator { Layout.fillWidth: true }
                                    Text {
                                        text: (Audio.sink?.audio?.muted ?? false)
                                        ? "Muted"
                                        : `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}%`
                                        font.family:         Config.theme.font
                                        font.pixelSize:      Styling.fontSize(-2)
                                        color:               Colors.overSurfaceVariant
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // Mute button + StyledSlider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Button {
                                        id: volMuteBtn
                                        flat: true
                                        implicitWidth:  32
                                        implicitHeight: 32
                                        Layout.preferredWidth:  32
                                        Layout.maximumWidth:    32
                                        Layout.fillWidth:       false

                                        background: StyledRect {
                                            variant: volMuteBtn.hovered ? "focus" : "common"
                                            radius: Styling.radius(4)
                                        }

                                        contentItem: Item {
                                            Text {
                                                anchors.centerIn: parent
                                                text: {
                                                    if (Audio.sink?.audio?.muted) return Icons.speakerSlash
                                                        const v = Audio.sink?.audio?.volume ?? 0
                                                        if (v < 0.01) return Icons.speakerX
                                                            if (v < 0.19) return Icons.speakerNone
                                                                if (v < 0.49) return Icons.speakerLow
                                                                    return Icons.speakerHigh
                                                }
                                                font.family:    Icons.font
                                                font.pixelSize: 16
                                                color: (Audio.sink?.audio?.muted ?? false)
                                                ? Colors.error
                                                : Colors.overBackground
                                                Behavior on color {
                                                    enabled: Config.animDuration > 0
                                                    ColorAnimation { duration: Config.animDuration / 2 }
                                                }
                                            }
                                        }

                                        onClicked: {
                                            if (Audio.sink?.audio)
                                                Audio.sink.audio.muted = !Audio.sink.audio.muted
                                        }

                                        StyledToolTip {
                                            visible: volMuteBtn.hovered
                                            tooltipText: (Audio.sink?.audio?.muted ?? false) ? "Unmute" : "Mute"
                                        }
                                    }

                                    StyledSlider {
                                        id: volSlider
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 20
                                        value: Audio.sink?.audio?.volume ?? 0
                                        scroll: false

                                        property bool syncingFromPipewire: false

                                        progressColor: {
                                            if (Audio.sink?.audio?.muted ?? false) return Colors.outline
                                                return Styling.srItem("overprimary")
                                        }
                                        Behavior on progressColor {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation { duration: Config.animDuration / 2 }
                                        }

                                        Connections {
                                            target: Audio.sink?.audio ?? null
                                            ignoreUnknownSignals: true
                                            function onVolumeChanged() {
                                                if (!Audio.sink?.audio) return
                                                    volSlider.syncingFromPipewire = true
                                                    volSlider.value = Audio.sink.audio.volume
                                                    volSlider.syncingFromPipewire = false
                                            }
                                        }

                                        onValueChanged: {
                                            if (volSlider.syncingFromPipewire) return
                                                if (Audio.sink?.audio && Math.abs(value - (Audio.sink.audio.volume ?? 0)) > 0.001)
                                                    Audio.setNodeVolume(Audio.sink, value)
                                        }

                                        WheelHandler {
                                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                            onWheel: event => {
                                                const step  = 0.05
                                                const delta = event.angleDelta.y > 0 ? step : -step
                                                const nv    = Math.max(0, Math.min(1, volSlider.value + delta))
                                                if (Audio.sink?.audio && Math.abs(nv - (Audio.sink.audio.volume ?? 0)) > 0.001)
                                                    Audio.setNodeVolume(Audio.sink, nv)
                                            }
                                        }
                                    }
                                }
                            }

                            // ── Brightness (AudioVolumeEntry-style) ─────────────
                            ColumnLayout {
                                id: brightCol
                                Layout.fillWidth: true
                                spacing: 4

                                property var mon: Brightness.monitors.length > 0 ? Brightness.monitors[0] : null

                                // Name row: label ··· percentage
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: "Brightness"
                                        font.family:    Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overSurfaceVariant
                                    }
                                    Separator { Layout.fillWidth: true }
                                    Text {
                                        text: `${Math.round((brightCol.mon?.brightness ?? 0.5) * 100)}%`
                                        font.family:         Config.theme.font
                                        font.pixelSize:      Styling.fontSize(-2)
                                        color:               Colors.overSurfaceVariant
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // Sun icon button + StyledSlider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Button {
                                        id: brightIconBtn
                                        flat: true
                                        implicitWidth:  32
                                        implicitHeight: 32
                                        Layout.preferredWidth:  32
                                        Layout.maximumWidth:    32
                                        Layout.fillWidth:       false

                                        background: StyledRect {
                                            variant: brightIconBtn.hovered ? "focus" : "common"
                                            radius: Styling.radius(4)
                                        }

                                        contentItem: Item {
                                            Text {
                                                anchors.centerIn: parent
                                                text: (brightCol.mon?.brightness ?? 0.5) < 0.25
                                                ? Icons.sunDim : Icons.sun
                                                font.family:    Icons.font
                                                font.pixelSize: 16
                                                color: Colors.overBackground
                                            }
                                        }

                                        // Tap to toggle between 30 % dim and full brightness
                                        onClicked: {
                                            if (!brightCol.mon?.ready) return
                                                const cur = brightCol.mon.brightness
                                                brightCol.mon.setBrightness(cur > 0.31 ? 0.30 : 1.0)
                                        }

                                        StyledToolTip {
                                            visible: brightIconBtn.hovered
                                            tooltipText: "Toggle dim / full"
                                        }
                                    }

                                    StyledSlider {
                                        id: brightSlider
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 20
                                        value: brightCol.mon?.brightness ?? 0.5
                                        scroll: false

                                        property bool syncingFromMonitor: false

                                        progressColor: Styling.srItem("overprimary")

                                        Connections {
                                            target: brightCol.mon ?? null
                                            ignoreUnknownSignals: true
                                            function onBrightnessChanged() {
                                                if (!brightCol.mon) return
                                                    brightSlider.syncingFromMonitor = true
                                                    brightSlider.value = brightCol.mon.brightness
                                                    brightSlider.syncingFromMonitor = false
                                            }
                                            function onReadyChanged() {
                                                if (brightCol.mon?.ready) {
                                                    brightSlider.syncingFromMonitor = true
                                                    brightSlider.value = brightCol.mon.brightness
                                                    brightSlider.syncingFromMonitor = false
                                                }
                                            }
                                        }

                                        onValueChanged: {
                                            if (brightSlider.syncingFromMonitor) return
                                                if (brightCol.mon?.ready)
                                                    brightCol.mon.setBrightness(value)
                                        }

                                        WheelHandler {
                                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                            onWheel: event => {
                                                if (!brightCol.mon?.ready) return
                                                    const step  = 0.05
                                                    const delta = event.angleDelta.y > 0 ? step : -step
                                                    brightCol.mon.setBrightness(
                                                        Math.max(0, Math.min(1, brightSlider.value + delta))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ────────────────────────────────────────────────────────────────────
            // PAGE 2 — Sub-page (Wi-Fi networks or Bluetooth devices)
            // ────────────────────────────────────────────────────────────────────
            Item {
                id: subPage
                x: pageStrip.width / 2
                width: pageStrip.width / 2
                height: root.height

                // Back button strip
                Item {
                    id: backStrip
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 40

                    Item {
                        id: backBtn
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 32; height: 32

                        property bool hov: false
                        HoverHandler { onHoveredChanged: backBtn.hov = hovered }

                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: Colors.overBackground
                            opacity: backBtn.hov ? 0.12 : 0
                            Behavior on opacity {
                                enabled: Config.animDuration > 0
                                NumberAnimation { duration: Config.animDuration / 2 }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Icons.caretLeft
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: Colors.overBackground
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activePage = "none"
                        }
                    }
                }

                // WifiPanel
                Loader {
                    id: wifiPanelLoader
                    anchors {
                        top: backStrip.bottom
                        left: parent.left; right: parent.right; bottom: parent.bottom
                        leftMargin: 12; rightMargin: 12
                    }
                    active: root.activePage === "wifi"
                    visible: active
                    sourceComponent: Component { WifiPanel {} }
                }

                // BluetoothPanel
                Loader {
                    id: btPanelLoader
                    anchors {
                        top: backStrip.bottom
                        left: parent.left; right: parent.right; bottom: parent.bottom
                        leftMargin: 12; rightMargin: 12
                    }
                    active: root.activePage === "bt"
                    visible: active
                    sourceComponent: Component { BluetoothPanel {} }
                }
            }
        } // pageStrip
    } // slideContainer

    // ══════════════════════════════════════════════════════════════════════════
    // CCToggleTile inline component
    // ══════════════════════════════════════════════════════════════════════════

    component CCHeaderBtn: Item {
        id: hBtn
        property string icon: ""
        signal clicked
        implicitWidth:  32
        implicitHeight: 32
        property bool hov: false
        HoverHandler { onHoveredChanged: hBtn.hov = hovered }

        StyledRect {
            id: hBtnBg
            anchors.fill: parent
            variant: hBtn.hov ? "focus" : "common"
            radius: Styling.radius(5)
            opacity: hBtn.hov ? 1.0 : 0.7
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration / 2 }
            }
        }

        Text {
            anchors.centerIn: parent
            text:           hBtn.icon
            font.family:    Icons.font
            font.pixelSize: 15
            color:          Colors.overBackground
        }

        MouseArea {
            anchors.fill:  parent
            hoverEnabled:  false
            cursorShape:   Qt.PointingHandCursor
            onClicked:     hBtn.clicked()
        }
    }

    component CCToggleTile: Item {
        id: tile
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property bool   active: false
        property bool   hasChevron: false
        signal toggled
        signal chevronClicked
        implicitHeight: 64
        property bool hov: false
        HoverHandler { onHoveredChanged: tile.hov = hovered }

        StyledRect {
            id: tileBg
            anchors.fill: parent
            variant: tile.active ? "primary" : "common"
            radius: Styling.radius(5)
            opacity: tile.hov ? 0.82 : 1.0
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration / 2 }
            }
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: tile.hasChevron ? 4 : 12 }
            spacing: 10

            Text {
                text: tile.icon; font.family: Icons.font; font.pixelSize: 18
                color: tile.active ? tileBg.item : Colors.overBackground
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { enabled: Config.animDuration > 0; ColorAnimation { duration: Config.animDuration / 2 } }
            }

            ColumnLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 1
                Text {
                    text: tile.label; font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 1; font.weight: Font.Medium
                    color: tile.active ? tileBg.item : Colors.overBackground
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
                Text {
                    text: tile.sublabel; font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 3
                    color: tile.active ? tileBg.item : Colors.overSurfaceVariant
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }

            Item {
                visible: tile.hasChevron; width: 28; height: 28
                Layout.alignment: Qt.AlignVCenter
                Rectangle {
                    anchors.centerIn: parent; width: 22; height: 22; radius: 11
                    color: Colors.overBackground; opacity: tile.active ? 0.15 : 0.08
                }
                Text {
                    anchors.centerIn: parent
                    text: Icons.caretRight
                    font.family: Icons.font; font.pixelSize: 11
                    color: tile.active ? tileBg.item : Colors.overBackground; opacity: 0.8
                }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -4
                    hoverEnabled: false; cursorShape: Qt.PointingHandCursor
                    onClicked: tile.chevronClicked()
                }
            }
        }

        MouseArea {
            anchors.fill: parent; anchors.rightMargin: tile.hasChevron ? 32 : 0
            hoverEnabled: false; cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }
    }
}

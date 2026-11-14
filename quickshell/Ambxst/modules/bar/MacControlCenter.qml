pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.config
import qs.modules.widgets.dashboard.controls

// ════════════════════════════════════════════════════════════════════════════
// MacControlCenter
// ────────────────────────────────────────────────────────────────────────────
// macOS-style Control Center. Drop-in replacement for ControlCenterContent.qml
// — same public surface (activePage, resetPages(), popupVisible) so it can be
// swapped straight into ControlCenterButton.qml.
//
// Layout mirrors macOS's real Control Center:
//   • Connectivity card  — Wi-Fi + Bluetooth rows, each with a chevron that
//     slides to a full sub-page (reuses your existing WifiPanel / BluetoothPanel)
//   • Focus square        — Do Not Disturb, wired to Notifications.silent
//   • Small square row    — Caffeine, Night Light, Game Mode
//   • Display card         — brightness slider (Brightness service)
//   • Sound card           — volume slider + mute (Audio service)
//   • Now Playing card     — MprisController, only shown when a player exists
//   • Power profile pill   — cycles PowerProfile.availableProfiles
//   • Header               — date + Lock / Screenshot / Power quick actions
// ════════════════════════════════════════════════════════════════════════════
Item {
    id: root

    // "none" | "wifi" | "bt"
    property string activePage: "none"

    // Called by ControlCenterButton when popup closes — resets to main page
    function resetPages() {
        activePage = "none"
    }

    // ── Shared wifi icon — single source of truth ──────────────────────────
    readonly property string wifiIcon: {
        if (!NetworkService.wifiEnabled)                 return Icons.wifiOff
        if (NetworkService.wifiStatus === "connecting")  return Icons.wifiLow
        const s = NetworkService.networkStrength
        if (s > 80) return Icons.wifiHigh
        if (s > 55) return Icons.wifiMedium
        if (s > 30) return Icons.wifiLow
        if (s > 0)  return Icons.wifiNone
        return NetworkService.wifi ? Icons.wifiNone : Icons.wifiOff
    }

    // ── Popup-gated refresh timer ───────────────────────────────────────────
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

    // Live clock for the header date pill — only ticks while the popup is open
    property date now: new Date()
    Timer {
        interval: 30000
        repeat:   true
        running:  root.popupVisible
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    clip: true

    // ── Sliding container (same mechanism as before: main page <-> sub page) ─
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

            // ────────────────────────────────────────────────────────────────
            // PAGE 1 — macOS-style main page
            // ────────────────────────────────────────────────────────────────
            Item {
                id: mainPage
                x: 0
                width: pageStrip.width / 2
                height: root.height

                Flickable {
                    id: mainFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: mainCol.implicitHeight + 16
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: mainCol
                        width: mainFlick.width
                        spacing: 12

                        // ── Header: date left · quick actions right ─────────
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 12
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            spacing: 8

                            Text {
                                text: Qt.formatDateTime(root.now, "ddd, MMM d  ·  hh:mm AP")
                                font.family:    Config.theme.font
                                font.pixelSize: Styling.fontSize(-2)
                                font.weight:    Font.Medium
                                color: Colors.overSurfaceVariant
                                Layout.fillWidth: true
                            }

                            CCHeaderBtn { icon: Icons.regionScreenshot; onClicked: { /* TODO: screenshot */ } }
                            CCHeaderBtn { icon: Icons.lock;             onClicked: { /* TODO: lock screen */ } }
                            CCHeaderBtn { icon: Icons.shutdown;         onClicked: { /* TODO: power menu */ } }
                        }

                        // ── Top row: Connectivity card (wide) + Focus square ─
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            spacing: 10

                            // Connectivity card — Wi-Fi + Bluetooth stacked
                            MacCard {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 2
                                implicitHeight: connCol.implicitHeight + 8

                                ColumnLayout {
                                    id: connCol
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                    spacing: 0

                                    MacRow {
                                        Layout.fillWidth: true
                                        icon:      root.wifiIcon
                                        label:     "Wi-Fi"
                                        sublabel:  NetworkService.wifiEnabled
                                                   ? (NetworkService.networkName !== "" ? NetworkService.networkName : "On")
                                                   : "Off"
                                        active:    NetworkService.wifiEnabled
                                        hasChevron: true
                                        onToggled:        NetworkService.enableWifi(!NetworkService.wifiEnabled)
                                        onChevronClicked: root.activePage = "wifi"
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 46
                                        height: 1
                                        color: Colors.outline
                                        opacity: 0.15
                                    }

                                    MacRow {
                                        Layout.fillWidth: true
                                        icon: BluetoothService.enabled
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
                                }
                            }

                            // Focus / Do Not Disturb — square module
                            MacSquare {
                                Layout.preferredWidth: 76
                                Layout.preferredHeight: connCol.implicitHeight + 8
                                Layout.fillHeight: false
                                icon:     Notifications.silent ? Icons.bellSlash : Icons.bell
                                label:    "Focus"
                                active:   Notifications.silent
                                onClicked: Notifications.silent = !Notifications.silent
                            }
                        }

                        // ── Small square row: Caffeine / Night Light / Game ──
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            spacing: 10

                            MacSquare {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                icon:     Icons.caffeine
                                label:    "Caffeine"
                                active:   CaffeineService.inhibit
                                onClicked: CaffeineService.toggleInhibit()
                            }
                            MacSquare {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                icon:     NightLightService.active ? Icons.moon : Icons.nightLight
                                label:    "Night Light"
                                active:   NightLightService.active
                                onClicked: NightLightService.toggle()
                            }
                            MacSquare {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                icon:     Icons.gameMode
                                label:    "Game Mode"
                                active:   GameModeService.toggled
                                onClicked: GameModeService.toggle()
                            }
                        }

                        // ── Display card — brightness ────────────────────────
                        MacCard {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            implicitHeight: brightCard.implicitHeight + 24

                            ColumnLayout {
                                id: brightCard
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 14 }
                                spacing: 6

                                property var mon: Brightness.monitors.length > 0 ? Brightness.monitors[0] : null

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Display"
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-1)
                                        font.weight: Font.DemiBold
                                        color: Colors.overSurface
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: `${Math.round((brightCard.mon?.brightness ?? 0.5) * 100)}%`
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overSurfaceVariant
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: (brightCard.mon?.brightness ?? 0.5) < 0.25 ? Icons.sunDim : Icons.sun
                                        font.family: Icons.font
                                        font.pixelSize: 15
                                        color: Colors.overSurfaceVariant
                                    }

                                    StyledSlider {
                                        id: brightSlider
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 20
                                        value: brightCard.mon?.brightness ?? 0.5
                                        scroll: false
                                        progressColor: Styling.srItem("overprimary")

                                        property bool syncingFromMonitor: false

                                        Connections {
                                            target: brightCard.mon ?? null
                                            ignoreUnknownSignals: true
                                            function onBrightnessChanged() {
                                                if (!brightCard.mon) return
                                                brightSlider.syncingFromMonitor = true
                                                brightSlider.value = brightCard.mon.brightness
                                                brightSlider.syncingFromMonitor = false
                                            }
                                            function onReadyChanged() {
                                                if (brightCard.mon?.ready) {
                                                    brightSlider.syncingFromMonitor = true
                                                    brightSlider.value = brightCard.mon.brightness
                                                    brightSlider.syncingFromMonitor = false
                                                }
                                            }
                                        }

                                        onValueChanged: {
                                            if (syncingFromMonitor) return
                                            if (brightCard.mon?.ready)
                                                brightCard.mon.setBrightness(value)
                                        }

                                        WheelHandler {
                                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                            onWheel: event => {
                                                if (!brightCard.mon?.ready) return
                                                const step  = 0.05
                                                const delta = event.angleDelta.y > 0 ? step : -step
                                                brightCard.mon.setBrightness(Math.max(0, Math.min(1, brightSlider.value + delta)))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Sound card — volume ──────────────────────────────
                        MacCard {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            implicitHeight: soundCard.implicitHeight + 24

                            ColumnLayout {
                                id: soundCard
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 14 }
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Sound"
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-1)
                                        font.weight: Font.DemiBold
                                        color: Colors.overSurface
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: (Audio.sink?.audio?.muted ?? false) ? "Muted" : `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}%`
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: Colors.overSurfaceVariant
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: {
                                            if (Audio.sink?.audio?.muted) return Icons.speakerSlash
                                            const v = Audio.sink?.audio?.volume ?? 0
                                            if (v < 0.01) return Icons.speakerX
                                            if (v < 0.19) return Icons.speakerNone
                                            if (v < 0.49) return Icons.speakerLow
                                            return Icons.speakerHigh
                                        }
                                        font.family: Icons.font
                                        font.pixelSize: 15
                                        color: (Audio.sink?.audio?.muted ?? false) ? Colors.error : Colors.overSurfaceVariant

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (Audio.sink?.audio) Audio.sink.audio.muted = !Audio.sink.audio.muted
                                        }
                                    }

                                    StyledSlider {
                                        id: volSlider
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 20
                                        value: Audio.sink?.audio?.volume ?? 0
                                        scroll: false
                                        progressColor: Styling.srItem("overprimary")

                                        property bool syncingFromPipewire: false

                                        onValueChanged: {
                                            if (syncingFromPipewire) return
                                            if (Audio.sink?.audio)
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
                        }

                        // ── Now Playing card — only when a player exists ─────
                        MacCard {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            visible: MprisController.activePlayer !== null
                            implicitHeight: visible ? (nowPlaying.implicitHeight + 20) : 0

                            RowLayout {
                                id: nowPlaying
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                                spacing: 10

                                // Artwork
                                Rectangle {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    radius: Styling.radius(3)
                                    color: Colors.overBackground
                                    opacity: 0.1

                                    Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        source: MprisController.activePlayer?.trackArtUrl ?? ""
                                        visible: (MprisController.activePlayer?.trackArtUrl ?? "") !== ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: (MprisController.activePlayer?.trackArtUrl ?? "") === ""
                                        text: Icons.player
                                        font.family: Icons.font
                                        font.pixelSize: 16
                                        color: Colors.overSurfaceVariant
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        text: MprisController.activePlayer?.trackTitle || "Not Playing"
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-1)
                                        font.weight: Font.Medium
                                        color: Colors.overSurface
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: MprisController.activePlayer?.trackArtist || ""
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-3)
                                        color: Colors.overSurfaceVariant
                                        elide: Text.ElideRight
                                    }
                                }

                                Row {
                                    spacing: 2
                                    MacMediaBtn {
                                        icon: Icons.previous
                                        enabled: MprisController.canGoPrevious
                                        onClicked: MprisController.previous()
                                    }
                                    MacMediaBtn {
                                        icon: MprisController.isPlaying ? Icons.pause : Icons.play
                                        enabled: MprisController.canTogglePlaying
                                        onClicked: MprisController.togglePlaying()
                                    }
                                    MacMediaBtn {
                                        icon: Icons.next
                                        enabled: MprisController.canGoNext
                                        onClicked: MprisController.next()
                                    }
                                }
                            }
                        }

                        // ── Power profile pill ───────────────────────────────
                        MacCard {
                            Layout.fillWidth: true
                            Layout.leftMargin: 14
                            Layout.rightMargin: 14
                            Layout.bottomMargin: 14
                            visible: PowerProfile.isAvailable
                            implicitHeight: visible ? 48 : 0

                            RowLayout {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 14 }
                                spacing: 8

                                Text {
                                    text: Icons.power
                                    font.family: Icons.font
                                    font.pixelSize: 15
                                    color: Colors.overSurfaceVariant
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Power Mode"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-1)
                                    color: Colors.overSurface
                                }
                                Text {
                                    text: PowerProfile.currentProfile.length > 0
                                          ? PowerProfile.currentProfile.charAt(0).toUpperCase() + PowerProfile.currentProfile.slice(1).replace("-", " ")
                                          : "—"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                    color: Colors.overSurfaceVariant
                                }
                                Text {
                                    text: Icons.caretRight
                                    font.family: Icons.font
                                    font.pixelSize: 10
                                    color: Colors.overSurfaceVariant
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -14
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const profiles = PowerProfile.availableProfiles
                                        if (!profiles || profiles.length === 0) return
                                        const idx = profiles.indexOf(PowerProfile.currentProfile)
                                        const nextProfile = profiles[(idx + 1) % profiles.length]
                                        PowerProfile.setProfile(nextProfile)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ────────────────────────────────────────────────────────────────
            // PAGE 2 — Sub-page (Wi-Fi networks or Bluetooth devices)
            // ────────────────────────────────────────────────────────────────
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

    // ══════════════════════════════════════════════════════════════════════
    // Inline macOS-flavoured building blocks
    // ══════════════════════════════════════════════════════════════════════

    // Rounded "squircle" card — the base surface for every module
    component MacCard: StyledRect {
        id: card
        variant: "common"
        radius: Math.max(Styling.radius(9), 16)
        enableShadow: false
    }

    // Small header icon button (screenshot / lock / power)
    component CCHeaderBtn: Item {
        id: hBtn
        property string icon: ""
        signal clicked
        implicitWidth:  30
        implicitHeight: 30
        property bool hov: false
        HoverHandler { onHoveredChanged: hBtn.hov = hovered }

        StyledRect {
            anchors.fill: parent
            variant: hBtn.hov ? "focus" : "common"
            radius: width / 2
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
            font.pixelSize: 13
            color:          Colors.overBackground
        }

        MouseArea {
            anchors.fill:  parent
            hoverEnabled:  false
            cursorShape:   Qt.PointingHandCursor
            onClicked:     hBtn.clicked()
        }
    }

    // A row inside a MacCard — icon + label/sublabel + optional chevron
    // (used for Wi-Fi / Bluetooth inside the Connectivity card)
    component MacRow: Item {
        id: row
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property bool   active: false
        property bool   hasChevron: false
        signal toggled
        signal chevronClicked
        implicitHeight: 52
        property bool hov: false
        HoverHandler { onHoveredChanged: row.hov = hovered }

        Rectangle {
            anchors.fill: parent
            color: Colors.overBackground
            opacity: row.hov ? 0.06 : 0
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration / 2 }
            }
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: row.hasChevron ? 8 : 12 }
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 7
                color: row.active ? Styling.srItem("overprimary") : Colors.overBackground
                opacity: row.active ? 1.0 : 0.12

                Text {
                    anchors.centerIn: parent
                    text: row.icon
                    font.family: Icons.font
                    font.pixelSize: 12
                    color: row.active ? Colors.background : Colors.overSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                Text {
                    text: row.label
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    color: Colors.overSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: row.sublabel
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-3)
                    color: Colors.overSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Item {
                visible: row.hasChevron
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Text {
                    anchors.centerIn: parent
                    text: Icons.caretRight
                    font.family: Icons.font
                    font.pixelSize: 10
                    color: Colors.overSurfaceVariant
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.chevronClicked()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: row.hasChevron ? 30 : 0
            hoverEnabled: false
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled()
        }
    }

    // Square module tile (Focus / Caffeine / Night Light / Game Mode)
    component MacSquare: StyledRect {
        id: sq
        property string icon: ""
        property string label: ""
        property bool   active: false
        signal clicked
        variant: sq.active ? "primary" : "common"
        radius: Math.max(Styling.radius(9), 16)
        property bool hov: false
        HoverHandler { onHoveredChanged: sq.hov = hovered }
        opacity: sq.hov ? 0.85 : 1.0
        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation { duration: Config.animDuration / 2 }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: sq.icon
                font.family: Icons.font
                font.pixelSize: 17
                color: sq.active ? sq.item : Colors.overSurface
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: sq.label
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-3)
                color: sq.active ? sq.item : Colors.overSurfaceVariant
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            cursorShape: Qt.PointingHandCursor
            onClicked: sq.clicked()
        }
    }

    // Tiny round media-transport button (prev / play-pause / next)
    component MacMediaBtn: Item {
        id: mBtn
        property string icon: ""
        property bool enabled: true
        signal clicked
        implicitWidth: 26
        implicitHeight: 26
        property bool hov: false
        HoverHandler { onHoveredChanged: mBtn.hov = hovered }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.overBackground
            opacity: mBtn.hov && mBtn.enabled ? 0.12 : 0
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration / 2 }
            }
        }

        Text {
            anchors.centerIn: parent
            text: mBtn.icon
            font.family: Icons.font
            font.pixelSize: 13
            color: Colors.overSurface
            opacity: mBtn.enabled ? 1.0 : 0.3
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            cursorShape: mBtn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (mBtn.enabled) mBtn.clicked()
        }
    }
}

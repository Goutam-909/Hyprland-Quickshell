// modules/bar/controlcenter/ControlCenterContent.qml
// Redesigned Control Center (layout from the C++ "mybar" version):
//
//   [avatar] name / Control center                  (power) (gear)
//   [ Wi-Fi tile       ] [ media card          ]
//   [ Bluetooth tile   ] [                     ]
//   [ 2x3 toggle card  ] [ brightness ] [ volume ]
//   [ Updates tile     ] [ Wallpaper tile      ]
//
// Detail pages (Wi-Fi, Bluetooth, volume mixer, mic mixer, settings, power)
// slide in over the same fixed-size pager, exactly like before, so the popup
// window never resizes while switching pages.
//
// Drop-in: same public API as the old file (popupOpen, activePanel, implicitWidth/Height).
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Services as Services
import qs.modules.services as Backend
import qs.modules.theme
import qs.modules.globals
import qs.common
import qs.common.functions
import qs.config
import "controlpanel"

Item {
    id: root

    // Set by the host popup (ControlCenterButton -> ccPopup.isOpen)
    property bool popupOpen: false
    onPopupOpenChanged: {
        Services.Bluetooth.setUiActive(popupOpen)
        if (popupOpen) {
            syncBrightness()
        } else {
            activePanel = ""
            wifiPasswordOpen = false
        }
    }

    // "", "wifi", "bluetooth", "volume", "mic", "power"
    property string activePanel: ""
    property bool wifiPasswordOpen: false

    // ── layout constants ─────────────────────────────────────────────────────
    readonly property real contentW: 360
    readonly property real gap: 12
    readonly property real halfW: (contentW - gap) / 2      // 174 (bottom tiles)
    readonly property real leftColW: halfW                  // 174
    readonly property real mediaW: halfW                     // 174
    readonly property real sliderW: 70
    readonly property real rowH: 180

    implicitWidth: contentW
    implicitHeight: pager.height

    // ── MPRIS ────────────────────────────────────────────────────────────────
    readonly property string artUrl: (Services.MprisController.activeTrack && Services.MprisController.activeTrack.artUrl) ? Services.MprisController.activeTrack.artUrl : ""
    readonly property bool hasTrack: Services.MprisController.activePlayer !== null
    readonly property bool isPlaying: Services.MprisController.isPlaying
    readonly property string trackTitle: (Services.MprisController.activeTrack && Services.MprisController.activeTrack.title) ? Services.MprisController.activeTrack.title : ""
    readonly property string trackArtist: (Services.MprisController.activeTrack && Services.MprisController.activeTrack.artist) ? Services.MprisController.activeTrack.artist : ""

    // ── Network / Bluetooth derived state ────────────────────────────────────
    readonly property string wifiGlyph: {
        if (Services.Network.ethernet)        return Icons.ethernet
        if (!Services.Network.wifiEnabled)    return Icons.wifiOff
        if (Services.Network.connecting)      return Icons.wifiNone
        if (Services.Network.connected)
            return Backend.NetworkService.wifiIconForStrength(Services.Network.signalStrength > 0 ? Services.Network.signalStrength : 100)
        return Icons.wifiHigh
    }
    readonly property string netTitle: {
        if (Services.Network.ethernet) return "Ethernet"
        if (Services.Network.connected && Services.Network.connectedSsid !== "") return Services.Network.connectedSsid
        return "Wi-Fi"
    }
    readonly property string netSub: {
        if (Services.Network.ethernet)     return "Connected"
        if (!Services.Network.wifiEnabled) return "Off"
        if (Services.Network.connecting)   return "Connecting…"
        if (Services.Network.limited)      return "Limited"
        if (Services.Network.connected)    return "Connected"
        return "Not connected"
    }
    readonly property string btGlyph: !Services.Bluetooth.powered ? Icons.bluetoothOff
                                     : (Services.Bluetooth.connected ? Icons.bluetoothConnected : Icons.bluetooth)
    readonly property string btSub: {
        if (!Services.Bluetooth.powered) return "Off"
        if (Services.Bluetooth.connected) return Services.Bluetooth.deviceName !== "" ? Services.Bluetooth.deviceName : "Connected"
        return "On"
    }

    // ── Volume ───────────────────────────────────────────────────────────────
    readonly property real vol: Services.Audio.ready ? Math.min(1, Services.Audio.sinkVolume) : 0
    readonly property string volGlyph: {
        if (Services.Audio.sinkMuted)  return Icons.speakerSlash
        if (vol <= 0.001)              return Icons.speakerNone
        if (vol < 0.4)                 return Icons.speakerLow
        return Icons.speakerHigh
    }

    // ── Brightness (per focused monitor, same logic as the old slider) ──────
    property real briValue: 0
    property bool briAvailable: false

    function currentMonitor() {
        const name = Hyprland.focusedMonitor?.name
        if (!name) return null
        for (let i = 0; i < Services.Brightness.monitors.length; i++) {
            const m = Services.Brightness.monitors[i]
            if (m?.screen?.name === name) return m
        }
        return null
    }
    function syncBrightness() {
        const m = currentMonitor()
        briAvailable = !!(m && m.ready)
        if (briAvailable) briValue = Math.max(0, Math.min(1, m.brightness))
    }
    function setBrightness(v) {
        briValue = v
        const m = currentMonitor()
        if (m && m.ready) m.setBrightness(v)
    }
    Connections {
        target: Services.Brightness
        function onBrightnessChanged() { root.syncBrightness() }
    }
    Timer {
        interval: 400
        repeat: true
        running: root.popupOpen
        onTriggered: root.syncBrightness()
    }

    function takeScreenshot() {
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.35; ambxst run screenshot 2>/dev/null || (grim -g \"$(slurp)\" - | wl-copy)"])
    }

    // ── Sliding pager ────────────────────────────────────────────────────────
    Item {
        id: pager
        width: parent.width
        height: Math.max(mainMenu.implicitHeight, 420)

        // ================= MAIN MENU =================
        Column {
            id: mainMenu
            width: pager.width
            spacing: root.gap

            opacity: root.activePanel === "" ? 1 : 0
            scale: root.activePanel === "" ? 1 : 0.96
            visible: opacity > 0
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }

            // ---------- header ----------
            Item {
                id: header
                width: parent.width
                height: 46

                Item {
                    id: avatar
                    width: 46
                    height: 46
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.face"
                        sourceSize: Qt.size(92, 92)
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: false
                    }
                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }
                    OpacityMask {
                        anchors.fill: parent
                        source: avatarImg
                        maskSource: avatarMask
                        visible: avatarImg.status === Image.Ready
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Appearance.colors.colPrimary
                        visible: avatarImg.status !== Image.Ready
                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                            font.family: Appearance.font.family.main
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }

                Column {
                    anchors.left: avatar.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Text {
                        text: Quickshell.env("USER") || "user"
                        font.family: Appearance.font.family.main
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnSurface
                    }
                    Text {
                        text: "Control center"
                        font.family: Appearance.font.family.main
                        font.pixelSize: 12
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                HeaderButton {
                    id: gearBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Icons.gear
                    onClicked: GlobalStates.settingsWindowVisible = true
                }
                HeaderButton {
                    anchors.right: gearBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Icons.shutdown
                    onClicked: root.activePanel = "power"
                }
            }

            // ---------- row 1: network + bluetooth | media ----------
            Row {
                width: parent.width
                spacing: root.gap

                Column {
                    id: leftStack
                    width: root.leftColW
                    spacing: root.gap

                    CcTile {
                        width: parent.width
                        circleSize: 48
                        iconPixelSize: 22
                        icon: root.wifiGlyph
                        title: root.netTitle
                        subtitle: root.netSub
                        active: Services.Network.ethernet || Services.Network.connected
                        onIconClicked: Services.Network.toggleWifi()
                        onClicked: {
                            root.activePanel = "wifi"
                            if (Services.Network.wifiEnabled) Services.Network.rescanWifi()
                        }
                    }
                    CcTile {
                        width: parent.width
                        circleSize: 48
                        iconPixelSize: 22
                        icon: root.btGlyph
                        title: "Bluetooth"
                        subtitle: root.btSub
                        active: Services.Bluetooth.powered
                        onIconClicked: Services.Bluetooth.togglePower()
                        onClicked: root.activePanel = "bluetooth"
                    }
                }

                // media card
                Rectangle {
                    width: root.mediaW
                    height: leftStack.height
                    radius: 24
                    color: Appearance.colors.colSurfaceContainerHigh

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 0

                        Item {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48

                            Image {
                                id: artImg
                                anchors.fill: parent
                                source: root.artUrl
                                sourceSize: Qt.size(96, 96)
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                visible: false
                            }
                            Rectangle {
                                id: artMask
                                anchors.fill: parent
                                radius: 10
                                visible: false
                            }
                            OpacityMask {
                                anchors.fill: parent
                                source: artImg
                                maskSource: artMask
                                visible: artImg.status === Image.Ready
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: Appearance.colors.colSurfaceContainerHighest
                                visible: artImg.status !== Image.Ready
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Icons.font
                                    font.pixelSize: 22
                                    text: Icons.player
                                    color: Appearance.colors.colOnSurfaceVariant
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.fillWidth: true
                            text: root.hasTrack && root.trackTitle !== "" ? root.trackTitle : "Nothing playing"
                            elide: Text.ElideRight
                            font.family: Appearance.font.family.main
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnSurface
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.trackArtist
                            elide: Text.ElideRight
                            font.family: Appearance.font.family.main
                            font.pixelSize: 12
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Item { Layout.preferredHeight: 8 }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            MediaButton {
                                glyph: Icons.previous
                                onClicked: Services.MprisController.previous()
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: 22
                                color: Appearance.colors.colPrimary
                                scale: playArea.pressed ? 0.92 : 1
                                Behavior on scale { NumberAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Icons.font
                                    font.pixelSize: 20
                                    text: root.isPlaying ? Icons.pause : Icons.play
                                    color: Appearance.colors.colOnPrimary
                                }
                                MouseArea {
                                    id: playArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.MprisController.togglePlaying()
                                }
                            }
                            Item { Layout.fillWidth: true }
                            MediaButton {
                                glyph: Icons.next
                                onClicked: Services.MprisController.next()
                            }
                        }
                    }
                }
            }

            // ---------- row 2: toggles | brightness | volume ----------
            Row {
                width: parent.width
                spacing: root.gap

                Rectangle {
                    width: root.contentW - root.gap * 2 - root.sliderW * 2
                    height: root.rowH
                    radius: 20
                    color: Appearance.colors.colSurfaceContainerHigh

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        CcToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignCenter
                            icon: Icons.caffeine
                            active: Backend.CaffeineService.inhibit
                            onClicked: Backend.CaffeineService.toggleInhibit()
                        }
                        CcToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignCenter
                            icon: Icons.nightLight
                            active: Backend.NightLightService.active
                            onClicked: Backend.NightLightService.toggle()
                        }
                        CcToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignCenter
                            icon: Backend.ScreenRecorder.isRecording ? Icons.stop : Icons.recordScreen
                            active: Backend.ScreenRecorder.isRecording
                            onClicked: Backend.ScreenRecorder.toggleRecording()
                        }
                        CcToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignCenter
                            icon: Icons.regionScreenshot
                            active: false
                            onClicked: root.takeScreenshot()
                        }
                    }
                }

                CcVSlider {
                    width: root.sliderW
                    height: root.rowH
                    icon: Icons.sun
                    value: root.briValue
                    opacity: root.briAvailable ? 1 : 0.5
                    onMoved: v => root.setBrightness(v)
                }

                CcVSlider {
                    width: root.sliderW
                    height: root.rowH
                    icon: root.volGlyph
                    value: root.vol
                    hasIconAction: true
                    onMoved: v => { if (Services.Audio.ready) Services.Audio.setSinkVolume(v) }
                    onIconClicked: Services.Audio.toggleMute()
                    onSecondaryClicked: root.activePanel = "volume"
                }
            }

            // ---------- row 3: microphone | dark mode ----------
            Row {
                width: parent.width
                spacing: root.gap

                CcTile {
                    width: root.halfW
                    height: 64
                    implicitHeight: 64
                    circleSize: 48
                    iconPixelSize: 22
                    icon: (Services.Audio.micReady && Services.Audio.sourceMuted) ? Icons.micSlash : Icons.mic
                    title: "Microphone"
                    subtitle: !Services.Audio.micReady ? "Not available"
                              : (Services.Audio.sourceMuted ? "Muted" : "On")
                    active: Services.Audio.micReady && !Services.Audio.sourceMuted
                    onClicked: Services.Audio.toggleMicMute()
                    onIconClicked: Services.Audio.toggleMicMute()
                    onRightClicked: root.activePanel = "mic"
                }
                CcTile {
                    width: root.halfW
                    height: 64
                    implicitHeight: 64
                    circleSize: 48
                    iconPixelSize: 22
                    icon: Config.theme.lightMode ? Icons.sun : Icons.moon
                    title: "Dark mode"
                    subtitle: Config.theme.lightMode ? "Off" : "On"
                    active: !Config.theme.lightMode
                    onClicked: Config.theme.lightMode = !Config.theme.lightMode
                    onIconClicked: Config.theme.lightMode = !Config.theme.lightMode
                }
            }
        }

        // ================= DETAIL PAGES =================
        // ---- Wi-Fi ----
        Item {
            width: pager.width; height: pager.height
            opacity: root.activePanel === "wifi" ? 1 : 0
            scale: root.activePanel === "wifi" ? 1 : 0.96
            visible: opacity > 0
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }

            WifiPopupInline {
                id: wifiPopup
                width: parent.width
                height: parent.height
                clip: true
                open: root.activePanel === "wifi"
                onRequestClose: root.activePanel = ""
                onShowPasswordDialogChanged: root.wifiPasswordOpen = showPasswordDialog
            }
        }

        // ---- Bluetooth ----
        Item {
            width: pager.width; height: pager.height
            opacity: root.activePanel === "bluetooth" ? 1 : 0
            scale: root.activePanel === "bluetooth" ? 1 : 0.96
            visible: opacity > 0
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }

            BluetoothPopupInline {
                id: bluetoothPopup
                width: parent.width
                height: parent.height
                clip: true
                open: root.activePanel === "bluetooth"
                onRequestClose: root.activePanel = ""
            }
        }

        // ---- Volume mixer ----
        Item {
            width: pager.width; height: pager.height
            opacity: root.activePanel === "volume" ? 1 : 0
            scale: root.activePanel === "volume" ? 1 : 0.96
            visible: opacity > 0
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }

            VolumeMixerPopupInline {
                id: volumeMixerPopup
                width: parent.width
                height: parent.height
                clip: true
                open: root.activePanel === "volume"
                onRequestClose: root.activePanel = ""
            }
        }

        // ---- Mic mixer ----
        Item {
            width: pager.width; height: pager.height
            opacity: root.activePanel === "mic" ? 1 : 0
            scale: root.activePanel === "mic" ? 1 : 0.96
            visible: opacity > 0
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }

            MicPopupInline {
                id: micMixerPopup
                width: parent.width
                height: parent.height
                clip: true
                open: root.activePanel === "mic"
                onRequestClose: root.activePanel = ""
            }
        }

        // ---- Power page ----
        Item {
            width: pager.width; height: pager.height
            opacity: root.activePanel === "power" ? 1 : 0
            scale: root.activePanel === "power" ? 1 : 0.96
            visible: opacity > 0
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }

            Column {
                width: parent.width
                spacing: 10

                PageHeader {
                    width: parent.width
                    title: "Session"
                    onBack: root.activePanel = ""
                }
                PowerRow {
                    width: parent.width
                    glyph: Icons.lock
                    label: "Lock"
                    onTriggered: Backend.LockscreenService.lock()
                }
                PowerRow {
                    width: parent.width
                    glyph: Icons.suspend
                    label: "Suspend"
                    onTriggered: {
                        Backend.LockscreenService.lock()
                        Quickshell.execDetached(["bash", "-c", "sleep 0.5 && systemctl suspend"])
                    }
                }
                PowerRow {
                    width: parent.width
                    glyph: Icons.logout
                    label: "Log out"
                    onTriggered: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                }
                PowerRow {
                    width: parent.width
                    glyph: Icons.reboot
                    label: "Reboot"
                    onTriggered: Quickshell.execDetached(["systemctl", "reboot"])
                }
                PowerRow {
                    width: parent.width
                    glyph: Icons.shutdown
                    label: "Shut down"
                    danger: true
                    onTriggered: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }

    // ═════════════════════════ small components ═════════════════════════════

    component HeaderButton: Rectangle {
        id: hb
        property string glyph: ""
        signal clicked()
        width: 40
        height: 40
        radius: 20
        color: hbArea.containsMouse ? Appearance.colors.colLayer3Hover
                                    : Appearance.colors.colSurfaceContainerHigh
        scale: hbArea.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation  { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            font.family: Icons.font
            font.pixelSize: 18
            text: hb.glyph
            color: Appearance.colors.colOnSurface
        }
        MouseArea {
            id: hbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hb.clicked()
        }
    }

    component MediaButton: Item {
        id: mb
        property string glyph: ""
        signal clicked()
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: mbArea.containsMouse ? Appearance.colors.colSurfaceContainerHighest : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Text {
            anchors.centerIn: parent
            font.family: Icons.font
            font.pixelSize: 18
            text: mb.glyph
            color: Appearance.colors.colOnSurface
        }
        MouseArea {
            id: mbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.clicked()
        }
    }

    component PageHeader: RowLayout {
        id: ph
        property string title: ""
        signal back()
        height: 44
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: phArea.containsMouse ? Appearance.colors.colLayer3Hover
                                        : Appearance.colors.colSurfaceContainerHigh
            Text {
                anchors.centerIn: parent
                font.family: Icons.font
                font.pixelSize: 18
                text: Icons.caretLeft
                color: Appearance.colors.colOnSurface
            }
            MouseArea {
                id: phArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ph.back()
            }
        }
        Text {
            Layout.fillWidth: true
            text: ph.title
            font.family: Appearance.font.family.main
            font.pixelSize: 18
            font.weight: Font.Bold
            color: Appearance.colors.colOnSurface
        }
    }

    component PowerRow: Rectangle {
        id: pr
        property string glyph: ""
        property string label: ""
        property bool danger: false
        signal triggered()
        height: 56
        radius: 24
        color: prArea.containsMouse ? Appearance.colors.colLayer3Hover
                                    : Appearance.colors.colSurfaceContainerHigh
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: pr.danger ? Appearance.colors.colError : Appearance.colors.colSurfaceContainerHighest
                Text {
                    anchors.centerIn: parent
                    font.family: Icons.font
                    font.pixelSize: 18
                    text: pr.glyph
                    color: pr.danger ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                }
            }
            Text {
                Layout.fillWidth: true
                text: pr.label
                font.family: Appearance.font.family.main
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSurface
            }
        }
        MouseArea {
            id: prArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pr.triggered()
        }
    }
}

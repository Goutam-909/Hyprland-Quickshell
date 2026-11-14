// modules/controlpanel/WifiPopupInline.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Services as Services
import qs.common
import qs.modules.theme

/**
 * Wi-Fi network list page
 * Header (title / scan / power) · scrollable network list · footer (settings / done).
 * Every action goes through Services.Network → NetworkService.
 */
Item {
    id: root

    property bool open: false
    signal requestClose()

    // ControlCenterContent binds to this (keyboard focus handling) — keep the name.
    property bool showPasswordDialog: false
    property string selectedSSID: ""

    // Kept here (not on the delegate) so it survives model updates.
    property string expandedSsid: ""

    function openPasswordFor(ssid) {
        selectedSSID = ssid
        expandedSsid = ""
        passwordField.text = ""
        showPasswordDialog = true
    }

    function closePasswordDialog() {
        passwordField.text = ""
        showPasswordDialog = false
    }

    function submitPassword() {
        if (passwordField.text.length === 0) return
        Services.Network.connectToNetwork(root.selectedSSID, passwordField.text)
        closePasswordDialog()
    }

    onOpenChanged: {
        if (open) {
            Services.Network.refreshForUI()
        } else {
            expandedSsid = ""
            closePasswordDialog()
            Services.Network.clearPasswordRequest()
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.open && Services.Network.wifiEnabled
        onTriggered: Services.Network.rescanWifi()
    }

    // A connect failed because the password is missing/wrong → ask for it.
    Connections {
        target: Services.Network
        function onPasswordRequiredSsidChanged() {
            const ssid = Services.Network.passwordRequiredSsid
            if (root.open && ssid !== "") {
                root.openPasswordFor(ssid)
                Services.Network.clearPasswordRequest()
            }
        }
    }

    // ─── Main page ─────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Styling.radius(8)  // matches the outer BarPopup's own radius
        color: "transparent"//.colors.colSurfaceContainerHigh
        clip: true
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 8
            visible: !root.showPasswordDialog

            // Header: title · scan · power switch
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    font.family: Appearance.font.family.main
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                }

                CcCircleButton {
                    icon: "autorenew"
                    enabled: Services.Network.wifiEnabled
                    spinning: Services.Network.scanning
                    iconColor: Services.Network.scanning
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colOnSurfaceVariant
                    onClicked: Services.Network.rescanWifi(true)
                }

                CcPowerSwitch {
                    checked: Services.Network.wifiEnabled
                    onToggled: Services.Network.toggleWifi()
                }
            }

            // Network list + empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: networkListView
                    anchors.fill: parent
                    spacing: 4
                    clip: true
                    cacheBuffer: 200
                    reuseItems: false
                    boundsBehavior: Flickable.StopAtBounds

                    model: Services.Network.networks

                    delegate: Rectangle {
                        id: networkItem
                        required property var modelData

                        readonly property string ssid: modelData?.ssid ?? ""
                        readonly property bool isActive: modelData?.active ?? false
                        readonly property bool isSecure: modelData?.isSecure ?? false
                        readonly property int strength: modelData?.strength ?? 0
                        // an active network is "known" even if the profile name differs from the SSID
                        readonly property bool isSaved: isActive || Services.Network.isSaved(ssid)
                        readonly property bool isConnecting: Services.Network.connectingSsid === ssid
                        readonly property bool hasError: Services.Network.errorSsid === ssid && Services.Network.errorText !== ""
                        readonly property bool expanded: ssid !== "" && root.expandedSsid === ssid && isSaved

                        function wifiIcon() {
                            if (isSecure) {
                                if (strength >= 75) return "android_wifi_4_bar_lock"
                                if (strength >= 50) return "android_wifi_3_bar_lock"
                                return "network_wifi_1_bar_locked"
                            }
                            if (strength >= 75) return "android_wifi_4_bar"
                            if (strength >= 50) return "wifi_2_bar"
                            return "network_wifi_1_bar"
                        }

                        width: networkListView.width
                        height: networkColumn.implicitHeight + 24
                        radius: Appearance.rounding.large
                        color: itemArea.pressed
                            ? Appearance.colors.colLayer2Active
                            : (itemArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colSurfaceContainerHigh)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        // Main item click area (under the buttons)
                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (networkItem.isConnecting || Services.Network.connecting) return
                                if (networkItem.isSaved) {
                                    root.expandedSsid = networkItem.expanded ? "" : networkItem.ssid
                                } else if (networkItem.isSecure) {
                                    root.openPasswordFor(networkItem.ssid)
                                } else {
                                    Services.Network.connectToNetwork(networkItem.ssid, "")
                                }
                            }
                        }

                        Column {
                            id: networkColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            // Network info row
                            RowLayout {
                                width: parent.width
                                spacing: 12

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    radius: 20
                                    color: networkItem.isActive
                                        ? Appearance.colors.colPrimaryContainer
                                        : Appearance.colors.colSurfaceContainerHighest
                                    Behavior on color { ColorAnimation { duration: 200 } }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        icon: networkItem.wifiIcon()
                                        iconSize: 20
                                        color: networkItem.isActive
                                            ? Appearance.colors.colOnPrimaryContainer
                                            : Appearance.colors.colOnSurfaceVariant
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: networkItem.ssid
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnSurface
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: {
                                            if (networkItem.isConnecting) return "Connecting…"
                                            if (networkItem.hasError) return Services.Network.errorText + " · tap to retry"
                                            if (networkItem.isActive)
                                                return Services.Network.limited ? "Connected · No internet" : "Connected"
                                            if (networkItem.isSaved) return "Saved · " + networkItem.strength + "%"
                                            return (networkItem.isSecure ? "Secured · " : "Open · ") + networkItem.strength + "%"
                                        }
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: 11
                                        color: networkItem.hasError
                                            ? Appearance.colors.colError
                                            : (networkItem.isActive
                                                ? (Services.Network.limited ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)
                                                : Appearance.colors.colOnSurfaceVariant)
                                        elide: Text.ElideRight
                                    }
                                }

                                // Spinner / chevron
                                Item {
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: 20
                                    implicitHeight: 20

                                    Rectangle {
                                        visible: networkItem.isConnecting
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Appearance.colors.colPrimary

                                        Rectangle {
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: Appearance.colors.colPrimary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: 2
                                        }

                                        RotationAnimation on rotation {
                                            running: networkItem.isConnecting
                                            from: 0
                                            to: 360
                                            duration: 1000
                                            loops: Animation.Infinite
                                        }
                                    }

                                    MaterialSymbol {
                                        visible: !networkItem.isConnecting && networkItem.isSaved
                                        anchors.centerIn: parent
                                        icon: "chevron_right"
                                        iconSize: 20
                                        color: Appearance.colors.colOnSurfaceVariant
                                        rotation: networkItem.expanded ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            // Action buttons (expanded state)
                            //   Active network:    Disconnect · Password · Forget
                            //   Saved, inactive:   Connect · Password · Forget
                            RowLayout {
                                visible: networkItem.expanded
                                width: parent.width
                                spacing: 8

                                CcPillButton {
                                    visible: !networkItem.isActive
                                    label: "Connect"
                                    labelColor: Appearance.colors.colOnPrimary
                                    baseColor: Appearance.colors.colPrimary
                                    hoverColor: Appearance.colors.colPrimaryHover
                                    activeColor: Appearance.colors.colPrimaryActive
                                    enabled: !Services.Network.connecting
                                    onClicked: {
                                        Services.Network.connectToNetwork(networkItem.ssid, "")
                                        root.expandedSsid = ""
                                    }
                                }

                                CcPillButton {
                                    visible: networkItem.isActive
                                    label: "Disconnect"
                                    onClicked: {
                                        Services.Network.disconnectFromNetwork()
                                        root.expandedSsid = ""
                                    }
                                }

                                CcPillButton {
                                    visible: networkItem.isSecure
                                    icon: "password"
                                    label: "Password"
                                    enabled: !Services.Network.connecting
                                    onClicked: root.openPasswordFor(networkItem.ssid)
                                }

                                CcPillButton {
                                    label: "Forget"
                                    labelColor: Appearance.colors.colError
                                    onClicked: {
                                        Services.Network.forgetNetwork(networkItem.ssid)
                                        root.expandedSsid = ""
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: networkListView.count === 0
                    spacing: 10

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        icon: Services.Network.wifiEnabled ? "wifi_find" : "wifi_off"
                        iconSize: 48
                        color: Appearance.colors.colOnSurfaceVariant
                        opacity: 0.4
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !Services.Network.wifiEnabled ? "Wi-Fi is off"
                            : (Services.Network.scanning ? "Searching for networks…" : "No networks found")
                        font.family: Appearance.font.family.main
                        font.pixelSize: 13
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }

            // Footer: settings · done
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: 8

                CcCircleButton {
                    icon: "open_in_new"
                    onClicked: Services.Network.openSettings()
                }

                Item { Layout.fillWidth: true }

                CcPillButton {
                    icon: "done"
                    label: "Done"
                    labelColor: Appearance.colors.colOnSurfaceVariant
                    onClicked: root.requestClose()
                }
            }
        }
    }

    // ─── Password dialog overlay ───────────────────────────────────────────
    Item {
        id: passwordDialog
        anchors.fill: parent
        z: 1000
        visible: opacity > 0
        opacity: root.showPasswordDialog ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Dim backdrop — clicking outside the card cancels
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            radius: Styling.radius(8)

            MouseArea {
                anchors.fill: parent
                onClicked: root.closePasswordDialog()
            }
        }

        Rectangle {
            id: dialogCard
            anchors.centerIn: parent
            width: parent.width - 40
            height: dialogColumn.implicitHeight + 40
            radius: 28
            color: Appearance.colors.colLayer2
            scale: root.showPasswordDialog ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            // swallow clicks so they don't reach the backdrop
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: dialogColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 20
                }
                spacing: 14

                Text {
                    text: "Connect to network"
                    font.family: Appearance.font.family.main
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnSurface
                }

                Text {
                    Layout.fillWidth: true
                    text: root.selectedSSID
                    font.family: Appearance.font.family.main
                    font.pixelSize: 13
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                }

                // Shown after a failed attempt ("Wrong password" / "Password required")
                Text {
                    Layout.fillWidth: true
                    visible: Services.Network.errorSsid === root.selectedSSID && Services.Network.errorText !== ""
                    text: Services.Network.errorText
                    font.family: Appearance.font.family.main
                    font.pixelSize: 12
                    color: Appearance.colors.colError
                }

                // Password input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    radius: 25
                    color: Appearance.colors.colLayer3
                    border.width: passwordField.activeFocus ? 2 : 0
                    border.color: Appearance.colors.colPrimary
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 20
                            rightMargin: 8
                        }
                        spacing: 6

                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: "Enter password"
                            echoMode: showToggle.checked ? TextInput.Normal : TextInput.Password
                            color: Appearance.colors.colOnSurface
                            font.family: Appearance.font.family.main
                            font.pixelSize: 14
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter
                            background: Item {}
                            onAccepted: root.submitPassword()
                        }

                        CcCircleButton {
                            id: showToggle
                            property bool checked: false
                            implicitWidth: 34
                            implicitHeight: 34
                            baseTransparent: true
                            icon: checked ? "visibility" : "visibility_off"
                            onClicked: {
                                checked = !checked
                                passwordField.forceActiveFocus()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    CcPillButton {
                        implicitHeight: 40
                        label: "Cancel"
                        onClicked: root.closePasswordDialog()
                    }

                    CcPillButton {
                        implicitHeight: 40
                        label: "Connect"
                        enabled: passwordField.text.length > 0
                        labelColor: Appearance.colors.colOnPrimary
                        baseColor: Appearance.colors.colPrimary
                        hoverColor: Appearance.colors.colPrimaryHover
                        activeColor: Appearance.colors.colPrimaryActive
                        onClicked: root.submitPassword()
                    }
                }
            }
        }

        // Focus the field once the dialog is up
        Connections {
            target: root
            function onShowPasswordDialogChanged() {
                if (root.showPasswordDialog)
                    Qt.callLater(() => passwordField.forceActiveFocus())
            }
        }
    }
}

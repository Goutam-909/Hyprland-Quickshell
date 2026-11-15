import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets

// Ported from the donor's QuickControls.qml. Service bindings below are
// fillers wired to plausible property names on YOUR services
// (services/Audio.qml, Brightness.qml, Network.qml, services/quickToggles
// singletons) - check each TODO against your actual service API and adjust,
// per your instruction not to worry about exact service wiring here.
ColumnLayout {
    id: root
    spacing: 10

    // ---- sliders --------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        MaterialSymbol { text: "volume_up"; iconSize: 18 }
        StyledSlider {
            Layout.fillWidth: true
            from: 0; to: 100
            value: Audio.volume ?? 0 // TODO: verify against services/Audio.qml
            onMoved: Audio.volume = value // TODO
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        MaterialSymbol { text: "brightness_6"; iconSize: 18 }
        StyledSlider {
            Layout.fillWidth: true
            from: 0; to: 100
            value: Brightness.brightness ?? 0 // TODO: verify against services/Brightness.qml
            onMoved: Brightness.brightness = value // TODO
        }
    }

    // ---- toggle grid --------------------------------------------------
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: 8
        columnSpacing: 8

        RippleButtonWithIcon {
            materialIcon: "wifi"
            toggled: Network.wifiEnabled ?? false // TODO: verify against services/Network.qml
            onClicked: Network.wifiEnabled = !Network.wifiEnabled // TODO
        }
        RippleButtonWithIcon {
            materialIcon: "bluetooth"
            toggled: BluetoothStatus.enabled ?? false // TODO: verify against services/BluetoothStatus.qml
            onClicked: BluetoothStatus.enabled = !BluetoothStatus.enabled // TODO
        }
        RippleButtonWithIcon {
            materialIcon: "dark_mode"
            toggled: Hyprsunset.enabled ?? false // TODO: verify against services/Hyprsunset.qml (night light)
            onClicked: Hyprsunset.enabled = !Hyprsunset.enabled // TODO
        }
        RippleButtonWithIcon {
            materialIcon: "coffee"
            toggled: Idle.inhibited ?? false // TODO: verify against services/Idle.qml (caffeine/idle-inhibit)
            onClicked: Idle.inhibited = !Idle.inhibited // TODO
        }
    }
}

// Services/Bluetooth.qml
// Adapter singleton — forwards to qs.modules.services.BluetoothService.
// Same pattern as Services/Network.qml: the control-center components talk to
// `Services.Bluetooth.*` and share ONE bluetoothctl-backed source of truth with
// the dashboard BluetoothPanel instead of running their own polling.
//
// BluetoothDevice objects already expose address/name/paired/connected/trusted/
// battery/busy/busyLabel/lastError plus connect()/disconnect()/pair()/forget(),
// so devices are handed to the UI directly — no shape translation needed.
pragma Singleton
import QtQuick
import qs.modules.services as Backend

QtObject {
    id: root

    readonly property bool powered:     Backend.BluetoothService.enabled
    readonly property bool discovering: Backend.BluetoothService.discovering
    readonly property bool connected:   Backend.BluetoothService.connected
    readonly property int  connectedCount: Backend.BluetoothService.connectedDevices

    // Sorted (connected > paired > name), anonymous beacons filtered out.
    readonly property var devices: Backend.BluetoothService.friendlyDeviceList

    readonly property string deviceName: {
        const list = root.devices
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected) return list[i].name
        }
        return ""
    }

    // Any device mid pair/connect/disconnect/remove.
    readonly property var busyDevice: {
        const list = root.devices
        for (let i = 0; i < list.length; i++) {
            if (list[i].busy) return list[i]
        }
        return null
    }
    readonly property bool isProcessing: busyDevice !== null
    readonly property string processingAddress: busyDevice ? busyDevice.address : ""
    readonly property string busyLabel: busyDevice ? busyDevice.busyLabel : ""

    // ── Power / discovery ────────────────────────────────────────────────
    function togglePower()    { Backend.BluetoothService.toggle() }
    function startDiscovery() { Backend.BluetoothService.startDiscovery() }
    function stopDiscovery()  { Backend.BluetoothService.stopDiscovery() }

    // ── UI lifecycle ─────────────────────────────────────────────────────
    // Call with true while a Bluetooth surface (control center) is visible so
    // the backend keeps polling; false when it closes.
    function setUiActive(active) { Backend.BluetoothService.setUiActive(active) }
    function refreshForUI()      { Backend.BluetoothService.refreshForUI() }
    function openSettings()      { Backend.BluetoothService.openBluetoothSettings() }

    // ── Devices ──────────────────────────────────────────────────────────
    function getSortedDevices() { return root.devices }

    function connectDevice(device)    { device.connect() }
    function disconnectDevice(device) { device.disconnect() }
    // connect() = pair (if needed) → trust (if needed) → connect
    function pairDevice(device)       { device.connect() }
    function forgetDevice(device)     { device.forget() }

    function getDeviceIcon(device) {
        const raw = (device?.icon || "").toLowerCase()
        if (raw.includes("headset") || raw.includes("headphone")) return "headphones"
        if (raw.includes("phone"))                                return "smartphone"
        if (raw.includes("keyboard"))                             return "keyboard"
        if (raw.includes("mouse"))                                return "mouse"
        if (raw.includes("computer") || raw.includes("laptop"))   return "computer"
        if (raw.includes("watch"))                                return "watch"
        if (raw.includes("speaker") || raw.includes("audio"))     return "speaker"
        if (raw.includes("gamepad") || raw.includes("joystick"))  return "sports_esports"
        return "bluetooth"
    }
}

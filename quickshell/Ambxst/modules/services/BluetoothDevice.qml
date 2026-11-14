// modules/services/BluetoothDevice.qml
// Thin, null-safe wrapper around a nativeDev Quickshell.Bluetooth device.
// No Process / bluetoothctl: every property is a live binding to BlueZ over
// D-Bus, and every access tolerates `nativeDev` going null (adapter powered off,
// device removed). Same property/method surface as the old Process-based
// version, so BluetoothDeviceItem / BluetoothPopupInline keep working.
import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBt

QtObject {
    id: root

    // The nativeDev QsBt.BluetoothDevice. Becomes null when BlueZ drops it.
    property var nativeDev: null

    readonly property bool valid: nativeDev !== null && nativeDev !== undefined

    readonly property string address: nativeDev?.address ?? ""
    readonly property string name: {
        const n = nativeDev?.name ?? nativeDev?.deviceName ?? "";
        return n !== "" ? n : (address !== "" ? address : "Unknown");
    }
    readonly property string icon: nativeDev?.icon || "bluetooth"
    readonly property bool paired: nativeDev ? (nativeDev.paired === true || nativeDev.bonded === true) : false
    readonly property bool connected: nativeDev?.connected ?? false
    readonly property bool trusted: nativeDev?.trusted ?? false

    // Native battery is 0..1; the UI expects 0..100.
    readonly property bool batteryAvailable: nativeDev?.batteryAvailable ?? false
    readonly property int battery: batteryAvailable ? Math.round((nativeDev.battery ?? 0) * 100) : -1

    // Native state: Disconnected / Connected / Disconnecting / Connecting.
    readonly property int _state: nativeDev?.state ?? 0
    readonly property bool _connectingNow: nativeDev ? (nativeDev.state === QsBt.BluetoothDeviceState.Connecting) : false
    readonly property bool _disconnectingNow: nativeDev ? (nativeDev.state === QsBt.BluetoothDeviceState.Disconnecting) : false
    readonly property bool _pairingNow: nativeDev?.pairing ?? false

    property string _localLabel: ""      // set while we are forgetting
    readonly property string busyLabel: _localLabel !== "" ? _localLabel
        : _pairingNow ? "Pairing"
        : _connectingNow ? "Connecting"
        : _disconnectingNow ? "Disconnecting" : ""
    readonly property bool busy: busyLabel !== ""
    readonly property bool connecting: _pairingNow || _connectingNow

    // Always "loaded": data is live, there is no async info fetch any more.
    readonly property bool infoLoaded: valid
    property string lastError: ""

    readonly property bool isUnnamed: {
        const n = (nativeDev?.name ?? "").replace(/-/g, ":").toUpperCase();
        return n === "" || n === address.toUpperCase();
    }

    signal infoUpdated()

    function connect() {
        if (!nativeDev || busy) return;
        lastError = "";
        try {
            if (!paired && typeof nativeDev.pair === "function") nativeDev.pair();
            if (!trusted) nativeDev.trusted = true;
            nativeDev.connect();
        } catch (e) {
            lastError = String(e);
        }
    }

    function disconnect() {
        if (!nativeDev || busy) return;
        lastError = "";
        try { nativeDev.disconnect(); } catch (e) { lastError = String(e); }
    }

    function pair() {
        if (!nativeDev || busy) return;
        lastError = "";
        try {
            if (typeof nativeDev.pair === "function") nativeDev.pair();
            nativeDev.trusted = true;
        } catch (e) { lastError = String(e); }
    }

    function trust() {
        if (nativeDev) nativeDev.trusted = true;
    }

    function forget() {
        if (!nativeDev || busy) return;
        lastError = "";
        _localLabel = "Removing";
        try { nativeDev.forget(); } catch (e) { lastError = String(e); }
        clearBusy.restart();
    }

    // Kept so old callers don't break; data is live now.
    function updateInfo() { infoUpdated(); }

    property var _clearBusy: Timer {
        id: clearBusy
        interval: 1500
        onTriggered: root._localLabel = ""
    }
}

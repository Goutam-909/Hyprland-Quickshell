// modules/services/BluetoothService.qml
// Native BlueZ (D-Bus) backend via Quickshell.Bluetooth.
//
// Why this replaces the bluetoothctl version: that one spawned a new
// `bluetoothctl` Process for every poll / device / action and destroy()ed
// them from their own onExited. Powering the adapter off at the wrong moment
// left Qt notifying on already-closed pipes (the endless
// "QSocketNotifier: Invalid socket N" flood) and, together with PipeWire
// dropping the Bluetooth audio nodes, took the shell down. Here there are no
// processes, no polling and no timers fighting the power transition: the
// adapter state is a live binding.
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBt

Singleton {
    id: root

    // ── Adapter state (all null-safe) ────────────────────────────────────
    readonly property var adapter: QsBt.Bluetooth.defaultAdapter ?? null
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false

    // True while a power change is in flight (kept for API compatibility).
    property bool isUpdating: false
    property bool uiActive: false
    property bool scanAfterPower: false

    // ── Devices ──────────────────────────────────────────────────────────
    // One wrapper per native device; the Instantiator adds/removes them as
    // BlueZ reports devices, so nothing is ever destroy()ed by hand.
    property var devices: []

    // Sorted, anonymous beacons hidden — what the UI binds to.
    property list<var> friendlyDeviceList: []

    readonly property int connectedDevices: {
        let n = 0;
        for (const d of devices) if (d && d.connected) n++;
        return n;
    }
    readonly property bool connected: connectedDevices > 0

    function _rebuild() {
        const sorted = [...devices]
            .filter(d => d && d.valid && (d.paired || d.connected || !d.isUnnamed))
            .sort((a, b) => {
                if (a.connected !== b.connected) return a.connected ? -1 : 1;
                if (a.paired !== b.paired) return a.paired ? -1 : 1;
                return (a.name || "").localeCompare(b.name || "");
            });

        let same = sorted.length === friendlyDeviceList.length;
        for (let i = 0; same && i < sorted.length; i++)
            if (sorted[i] !== friendlyDeviceList[i]) same = false;
        if (!same) friendlyDeviceList = sorted;
    }

    Timer {
        id: rebuildDebounce
        interval: 150
        onTriggered: root._rebuild()
    }

    // Re-sort when anything that affects ordering changes.
    readonly property string _orderKey: {
        let k = "";
        for (const d of devices)
            if (d) k += d.address + (d.connected ? "c" : "") + (d.paired ? "p" : "") + d.name + "|";
        return k;
    }
    on_OrderKeyChanged: rebuildDebounce.restart()

    Instantiator {
        // ObjectModel of native devices (all adapters)
        model: QsBt.Bluetooth.devices

        delegate: BluetoothDevice {
            required property var modelData
            nativeDev: modelData
        }

        onObjectAdded: (index, object) => {
            root.devices = [...root.devices, object];
            rebuildDebounce.restart();
        }
        onObjectRemoved: (index, object) => {
            root.devices = root.devices.filter(d => d !== object);
            rebuildDebounce.restart();
        }
    }

    // ── Power ────────────────────────────────────────────────────────────
    function setEnabled(value: bool): void {
        const a = root.adapter;
        if (!a) return;

        if (!value) {
            // Stop scanning BEFORE powering off so BlueZ isn't mid-discovery.
            root.scanAfterPower = false;
            if (a.discovering) a.discovering = false;
        }
        a.enabled = value;
    }

    function toggle(): void { setEnabled(!enabled); }

    // Run a queued scan request once the adapter finishes powering on.
    onEnabledChanged: {
        if (enabled && scanAfterPower) {
            scanAfterPower = false;
            startDiscovery();
        }
        rebuildDebounce.restart();
    }

    // ── Discovery ────────────────────────────────────────────────────────
    function startDiscovery(): void {
        const a = root.adapter;
        if (!a) return;
        if (!a.enabled) { scanAfterPower = true; return; }
        scanAfterPower = false;
        a.discovering = true;
        scanTimeout.restart();
    }

    function stopDiscovery(): void {
        scanAfterPower = false;
        scanTimeout.stop();
        const a = root.adapter;
        if (a && a.discovering) a.discovering = false;
    }

    Timer {
        id: scanTimeout
        interval: 20000
        onTriggered: root.stopDiscovery()
    }

    // ── Per-address helpers (old API; delegate to wrappers) ──────────────
    function _find(address: string) {
        for (const d of devices) if (d && d.address === address) return d;
        return null;
    }
    function connectDevice(address: string): void    { _find(address)?.connect(); }
    function disconnectDevice(address: string): void { _find(address)?.disconnect(); }
    function pairDevice(address: string): void       { _find(address)?.pair(); }
    function trustDevice(address: string): void      { _find(address)?.trust(); }
    function removeDevice(address: string): void     { _find(address)?.forget(); }

    // ── UI lifecycle (nothing to poll — kept for API compatibility) ──────
    function setUiActive(active: bool): void { uiActive = active; }
    function refreshForUI(): void { rebuildDebounce.restart(); }
    function updateStatus(): void { rebuildDebounce.restart(); }
    function updateDevices(): void { rebuildDebounce.restart(); }

    function openBluetoothSettings(): void {
        Quickshell.execDetached(["kcmshell6", "kcm_bluetooth"]);
    }
}

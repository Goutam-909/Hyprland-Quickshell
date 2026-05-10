pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.globals

Singleton {
    id: root

    property bool enabled: false
    property bool discovering: false
    property bool connected: false
    property int connectedDevices: 0

    readonly property list<BluetoothDevice> devices: []

    // Cached sorted device list - only updates when devices change
    property list<var> friendlyDeviceList: []

    // Queue for batching updateInfo calls
    property var pendingInfoUpdates: []
    property bool isProcessingInfoQueue: false
    property bool isUpdating: false
    property bool wasEnabledBeforeSleep: false

    property var suspendConnections: Connections {
        target: SuspendManager
        function onPreparingForSleep() {
            root.wasEnabledBeforeSleep = root.enabled;
            if (discovering) {
                root.stopDiscovery();
            }
            scanTimer.stop();
            infoQueueTimer.stop();
        }
        function onWakingUp() {
            // Re-sync status after wake
            wakeSyncTimer.restart();

            // Restore state if it was enabled
            if (root.wasEnabledBeforeSleep) {
                root.setEnabled(true);
            }
        }
    }

    property var wakeSyncTimer: Timer {
        id: wakeSyncTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.updateStatus();
            if (root.enabled) {
                root.updateDevices();
            }
        }
    }

    function updateFriendlyList() {
        friendlyDeviceList = [...devices].sort((a, b) => {
            // Connected devices first
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            // Then paired devices
            if (a.paired && !b.paired) return -1;
            if (!a.paired && b.paired) return 1;
            // Then by name
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    // Batch process info updates with delay between each
    function queueInfoUpdate(device: BluetoothDevice) {
        if (pendingInfoUpdates.indexOf(device) === -1) {
            pendingInfoUpdates.push(device);
        }
        if (!isProcessingInfoQueue) {
            processNextInfoUpdate();
        }
    }

    function processNextInfoUpdate() {
        if (pendingInfoUpdates.length === 0) {
            isProcessingInfoQueue = false;
            updateFriendlyList();
            return;
        }

        isProcessingInfoQueue = true;
        const device = pendingInfoUpdates.shift();
        if (device) {
            device.updateInfo();
        }
        // Process next after a small delay
        infoQueueTimer.restart();
    }

    Timer {
        id: infoQueueTimer
        interval: 200  // 200ms between each info request — gives PipeWire room to finish registering BT audio nodes
        running: false
        repeat: false
        onTriggered: {
            if (!SuspendManager.isSuspending) {
                root.processNextInfoUpdate();
            }
        }
    }

    Component {
        id: asyncProcessComp
        Process {
            id: internalProc
            property var resolve
            property var reject
            property string buffer: ""
            property string errorBuffer: ""

            stdout: SplitParser {
                onRead: data => internalProc.buffer += data + "\n"
            }

            stderr: SplitParser {
                onRead: data => internalProc.errorBuffer += data + "\n"
            }

            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) resolve(buffer.trim());
                else reject(errorBuffer.trim() || `Process exited with code ${exitCode}`);
                destroy();
            }
        }
    }

    function runAsync(command, environment = {}) {
        return new Promise((resolve, reject) => {
            const proc = asyncProcessComp.createObject(root, {
                command: command,
                environment: environment,
                resolve: resolve,
                reject: reject
            });
            proc.running = true;
        });
    }

    // Control functions
    function setEnabled(value: bool): void {
        if (SuspendManager.isSuspending) return;
        isUpdating = true;
        runAsync(["bluetoothctl", "power", value ? "on" : "off"]).then(() => {
            updateStatus();
            if (value) updateDevices();
            isUpdating = false;
        }).catch(e => {
            isUpdating = false;
        });
    }

    function toggle(): void {
        setEnabled(!enabled);
    }

    function startDiscovery(): void {
        if (enabled && !SuspendManager.isSuspending) {
            discovering = true;
            runAsync(["bluetoothctl", "scan", "on"]).then(() => {
                scanTimer.restart();
            }).catch(e => {
                discovering = false;
            });
        }
    }

    function stopDiscovery(): void {
        discovering = false;
        runAsync(["bluetoothctl", "scan", "off"]).then(() => {
            scanTimer.stop();
        }).catch(e => {});
    }

    function connectDevice(address: string): void {
        isUpdating = true;
        runAsync(["bluetoothctl", "connect", address]).then(() => {
            updateDevices();
            isUpdating = false;
        }).catch(e => {
            isUpdating = false;
        });
    }

    function disconnectDevice(address: string): void {
        isUpdating = true;
        runAsync(["bluetoothctl", "disconnect", address]).then(() => {
            updateDevices();
            isUpdating = false;
        }).catch(e => {
            isUpdating = false;
        });
    }

    function pairDevice(address: string): void {
        isUpdating = true;
        runAsync(["bluetoothctl", "pair", address]).then(() => {
            updateDevices();
            isUpdating = false;
        }).catch(e => {
            isUpdating = false;
        });
    }

    function trustDevice(address: string): void {
        runAsync(["bluetoothctl", "trust", address]).catch(e => {});
    }

    function removeDevice(address: string): void {
        isUpdating = true;
        runAsync(["bluetoothctl", "remove", address]).then(() => {
            updateDevices();
            isUpdating = false;
        }).catch(e => {
            isUpdating = false;
        });
    }

    function openBluetoothSettings(): void {
        Quickshell.execDetached(["kcmshell6", "kcm_bluetooth"]);
    }

    // Cooldown guard: prevents rapid-fire refreshes (e.g. quick dashboard open/close)
    // from spawning overlapping bluetoothctl processes while PipeWire is registering
    // BT audio nodes, which triggers a pw_proxy_add_object_listener segfault.
    property bool isRefreshOnCooldown: false

    Timer {
        id: refreshCooldownTimer
        interval: 1500  // 1.5s cooldown between UI-triggered refreshes
        repeat: false
        onTriggered: root.isRefreshOnCooldown = false
    }

    // Refresh state and device list when the UI becomes visible
    function refreshForUI(): void {
        if (SuspendManager.isSuspending) return;
        if (isRefreshOnCooldown) return;
        isRefreshOnCooldown = true;
        refreshCooldownTimer.restart();
        updateStatus();
        // Delay device update slightly to avoid collision with PipeWire
        // registering BT audio nodes at the same moment BT power state changes
        refreshDevicesTimer.restart();
    }

    Timer {
        id: refreshDevicesTimer
        interval: 800  // give PipeWire time to finish registering audio nodes
        repeat: false
        onTriggered: {
            if (!SuspendManager.isSuspending && root.enabled && !root.isUpdating && !root.isProcessingInfoQueue) {
                root.updateDevices();
            }
        }
    }

    Timer {
        id: updateDebouncer
        interval: 200
        repeat: false
        onTriggered: root.performUpdate()
    }

    function updateStatus() {
        updateDebouncer.restart();
    }

    function performUpdate() {
        if (isUpdating) return;
        isUpdating = true;
        checkPowerProcess.running = true;
    }

    // Timers
    Timer {
        id: updateTimer
        interval: 5000
        // Only poll when interface is visible and not already processing
        running: root.enabled && !SuspendManager.isSuspending && !root.isProcessingInfoQueue && (GlobalStates.dashboardOpen || GlobalStates.launcherOpen || GlobalStates.overviewOpen)
        repeat: true
        onTriggered: {
            if (!root.isUpdating && !root.isProcessingInfoQueue) {
                root.updateDevices();
            }
        }
    }

    Timer {
        id: scanTimer
        interval: 15000
        running: false
        repeat: false
        onTriggered: root.stopDiscovery()
    }

    // Processes
    Process {
        id: checkPowerProcess
        command: ["bash", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : "";
                root.enabled = output === "yes";

                if (root.enabled) {
                    checkConnectedProcess.running = true;
                } else {
                    root.connected = false;
                    root.connectedDevices = 0;
                    root.discovering = false;
                    root.isUpdating = false;
                }
            }
        }
    }

    Process {
        id: checkConnectedProcess
        command: ["bash", "-c", "bluetoothctl devices Connected | wc -l"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const output = data ? data.trim() : "0";
                root.connectedDevices = parseInt(output) || 0;
                root.connected = root.connectedDevices > 0;
                root.isUpdating = false;
            }
        }
    }

    function updateDevices() {
        // Don't start a new device scan if one is already running or info queue is active
        if (getDevicesProcess.running || isProcessingInfoQueue) return;
        getDevicesProcess.running = true;
    }

    Process {
        id: getDevicesProcess
        command: ["bash", "-c", "bluetoothctl devices"]
        running: false
        property string buffer: ""
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: data => {
                getDevicesProcess.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const text = getDevicesProcess.buffer;
            getDevicesProcess.buffer = "";

            Qt.callLater(() => {
                const deviceLines = text.trim().split("\n").filter(l => l.startsWith("Device "));
                const deviceDataList = [];
                for (let i = 0; i < deviceLines.length; i++) {
                    const line = deviceLines[i];
                    const parts = line.split(" ");
                    if (parts.length < 2) continue;
                    deviceDataList.push({
                        address: parts[1],
                        name: parts.slice(2).join(" ") || "Unknown"
                    });
                }

                const rDevices = root.devices;

                // 1. Remove gone devices
                for (let i = rDevices.length - 1; i >= 0; i--) {
                    const rd = rDevices[i];
                    if (!deviceDataList.find(d => d.address === rd.address)) {
                        rDevices.splice(i, 1);
                        rd.destroy();
                    }
                }

                // 2. Add or update devices
                for (let i = 0; i < deviceDataList.length; i++) {
                    const data = deviceDataList[i];
                    const existing = rDevices.find(d => d.address === data.address);
                    if (existing) {
                        if (existing.name !== data.name) {
                            existing.name = data.name;
                        }
                        root.queueInfoUpdate(existing);
                    } else {
                        const newDevice = deviceComp.createObject(root, {
                            address: data.address,
                            name: data.name
                        });
                        rDevices.push(newDevice);
                        root.queueInfoUpdate(newDevice);
                    }
                }

                if (deviceDataList.length === 0) {
                    root.updateFriendlyList();
                }
            });
        }
    }

    Component {
        id: deviceComp
        BluetoothDevice {}
    }

    Component.onCompleted: {
        updateStatus();
    }

    // Refresh when dashboard or settings window opens
    Connections {
        target: GlobalStates
        function onDashboardOpenChanged() {
            if (GlobalStates.dashboardOpen) {
                root.refreshForUI();
            }
        }
        function onSettingsWindowVisibleChanged() {
            if (GlobalStates.settingsWindowVisible) {
                root.refreshForUI();
            }
        }
    }
}

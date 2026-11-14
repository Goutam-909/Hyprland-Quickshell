pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.globals
import qs.modules.theme

Singleton {
    id: root

    // ── Public state (consumed by NetworkPill, dashboard WifiPanel, control center…) ──
    property bool wifi: true                 // connected with full connectivity
    property bool ethernet: false
    property bool wifiEnabled: false
    property bool wifiScanning: false
    property var lastScanTime: 0
    property bool wasEnabledBeforeSleep: false
    property list<string> savedNetworks: []  // wifi profile NAMES (== SSID for profiles NM creates)

    // "disabled" | "disconnected" | "connecting" | "connected" | "limited"
    property string wifiStatus: "disconnected"
    property string wifiDevice: ""           // e.g. wlan0 — used for device-level disconnect

    // `isUpdating` is kept for existing consumers (dashboard spinner). It is now the OR of
    // two independent things: a background status poll, and user actions in flight. Before,
    // both shared one flag, so a long `connect` made every status poll get skipped and a
    // finishing poll could clear the flag in the middle of a user action.
    property bool pollBusy: false
    property int actionCount: 0
    readonly property bool actionBusy: actionCount > 0
    readonly property bool isUpdating: pollBusy || actionBusy

    // ── Connect / error feedback (per SSID) ──
    property string connectingSsid: ""
    property string errorSsid: ""
    property string errorText: ""
    property string passwordRequiredSsid: ""
    readonly property bool wifiConnecting: connectingSsid !== "" || wifiStatus === "connecting"

    property WifiAccessPoint wifiConnectTarget: null
    readonly property list<WifiAccessPoint> wifiNetworks: []
    property WifiAccessPoint active: null
    property list<var> friendlyWifiNetworks: []

    // Derived from the scan list instead of separate nmcli calls. The old versions had bugs:
    //  • networkName came from `nmcli c show --active | head -1` — the first active *connection*
    //    of ANY type (ethernet/VPN/…), and it was never cleared when Wi-Fi disconnected.
    //  • networkStrength only refreshed while dashboard/launcher/overview was open, so the
    //    control-center tile and bar icon were stale.
    readonly property string networkName: active ? active.ssid : ""
    readonly property int networkStrength: active ? active.strength : 0

    // ── Helpers ──────────────────────────────────────────────────────────
    // nmcli -t escapes ':' and '\' with a backslash. Split on unescaped ':' and unescape.
    function splitEscaped(line: string): var {
        const fields = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length && (line[i + 1] === ":" || line[i + 1] === "\\")) {
                cur += line[i + 1];
                i++;
            } else if (c === ":") {
                fields.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        fields.push(cur);
        return fields;
    }

    function isSaved(ssid: string): bool {
        return savedNetworks.indexOf(ssid) !== -1;
    }

    function clearError(): void {
        errorSsid = "";
        errorText = "";
    }

    function clearPasswordRequest(): void {
        passwordRequiredSsid = "";
    }

    property var suspendConnections: Connections {
        target: SuspendManager
        function onPreparingForSleep() {
            root.wasEnabledBeforeSleep = root.wifiEnabled;
        }
        function onWakingUp() {
            if (root.wasEnabledBeforeSleep) {
                root.enableWifi(true);
            }
        }
    }

    // ── Async process helper ─────────────────────────────────────────────
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
                else reject(errorBuffer.trim() || buffer.trim() || `Process exited with code ${exitCode}`);
                destroy();
            }
        }
    }

    // LANG=C so nmcli messages/values are English regardless of the user's locale.
    function runAsync(command, environment = { LANG: "C", LC_ALL: "C" }) {
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

    function beginAction(): void { actionCount++; }
    function endAction(): void { actionCount = Math.max(0, actionCount - 1); }

    // ── Network list ─────────────────────────────────────────────────────
    function updateActive() {
        for (let i = 0; i < wifiNetworks.length; i++) {
            if (wifiNetworks[i].active) {
                active = wifiNetworks[i];
                return;
            }
        }
        active = null;
    }

    function updateFriendlyList() {
        // Sort: connected first, then by signal in 10% buckets, then name. Bucketing stops rows
        // from swapping places every poll when two networks sit within a few % of each other.
        const sorted = [...wifiNetworks].sort((a, b) => {
            if (a.active !== b.active) return a.active ? -1 : 1;
            const ba = Math.round(a.strength / 10), bb = Math.round(b.strength / 10);
            if (ba !== bb) return bb - ba;
            return a.ssid.localeCompare(b.ssid);
        });

        // Only reassign when membership/order actually changed. Reassigning resets every
        // ListView delegate (collapses expanded rows, loses scroll position).
        let same = sorted.length === friendlyWifiNetworks.length;
        for (let i = 0; same && i < sorted.length; i++) {
            if (sorted[i] !== friendlyWifiNetworks[i]) same = false;
        }
        if (!same) friendlyWifiNetworks = sorted;
        updateActive();
    }

    function clearNetworks() {
        const rNetworks = wifiNetworks;
        const removed = [];
        for (let i = rNetworks.length - 1; i >= 0; i--) {
            removed.push(rNetworks[i]);
            rNetworks.splice(i, 1);
        }
        updateFriendlyList();               // drop UI references first…
        for (const ap of removed) ap.destroy();   // …then destroy
    }

    function refreshNetworks(): void {
        if (!getNetworks.running) getNetworks.running = true;
    }

    onWifiEnabledChanged: {
        if (!wifiEnabled) {
            wifiScanning = false;
            clearNetworks();
        }
    }

    // ── Actions ──────────────────────────────────────────────────────────
    function enableWifi(enabled = true): void {
        beginAction();
        wifiEnabled = enabled;   // optimistic; corrected by the next poll if it didn't take
        if (!enabled) {
            connectingSsid = "";
            clearError();
        }
        runAsync(["nmcli", "radio", "wifi", enabled ? "on" : "off"]).then(() => {
            endAction();
            update();
            // The radio needs a moment before it can see anything; then do a real scan.
            if (enabled) postEnableScan.restart();
        }).catch(e => {
            console.warn(`Wi-Fi radio ${enabled ? "on" : "off"} failed: ${e}`);
            endAction();
            update();
        });
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    Timer {
        id: postEnableScan
        interval: 1500
        repeat: false
        onTriggered: root.rescanWifi(true)
    }

    // `force` = user pressed the refresh button: allow a shorter gap between scans.
    function rescanWifi(force = false): void {
        if (!wifiEnabled) return;
        if (wifiScanning) return;
        const now = Date.now();
        if (now - lastScanTime < (force ? 4000 : 10000)) {
            refreshNetworks();   // too soon for a radio scan — just re-read the cache
            return;
        }

        lastScanTime = now;
        wifiScanning = true;
        runAsync(["nmcli", "dev", "wifi", "list", "--rescan", "yes"]).then(() => {
            wifiScanning = false;
            refreshNetworks();
            updateSavedNetworks();
        }).catch(e => {
            wifiScanning = false;
            refreshNetworks();   // "scanning not allowed yet" etc. — still show what we have
        });
    }

    function findAccessPoint(ssid: string): var {
        for (let i = 0; i < wifiNetworks.length; i++) {
            if (wifiNetworks[i].ssid === ssid) return wifiNetworks[i];
        }
        return null;
    }

    // Single connect path. password === "" → known/open network.
    function connectToSsid(ssid: string, password: string): void {
        if (!ssid) return;
        if (connectingSsid !== "") return;   // one connect at a time

        const ap = findAccessPoint(ssid);
        const hadProfile = isSaved(ssid);
        if (ap) {
            ap.askingPassword = false;
            root.wifiConnectTarget = ap;
        }
        connectingSsid = ssid;
        clearError();
        clearPasswordRequest();
        beginAction();

        const cmd = ["nmcli", "--wait", "45", "device", "wifi", "connect", ssid];
        if (password && password.length > 0) cmd.push("password", password);

        runAsync(cmd).then(() => {
            finishConnect(ssid, null, ap, hadProfile, false);
        }).catch(e => {
            finishConnect(ssid, e, ap, hadProfile, !!(password && password.length > 0));
        });
    }

    function finishConnect(ssid: string, err, ap, hadProfile: bool, hadPassword: bool): void {
        endAction();
        if (connectingSsid === ssid) connectingSsid = "";
        root.wifiConnectTarget = null;

        if (err) {
            const msg = String(err);
            if (/No network with SSID|not found/i.test(msg)) {
                errorText = "Network not found";
            } else if (/Timeout expired|timed out/i.test(msg)) {
                errorText = "Timed out";
            } else if (/Secrets were required|no secrets|\(7\)|\(53\)|802-1X|4-way|handshake/i.test(msg)) {
                // With a password supplied this means the password was rejected.
                errorText = hadPassword ? "Wrong password" : "Password required";
                passwordRequiredSsid = ssid;
                if (ap) ap.askingPassword = true;
            } else {
                errorText = "Couldn't connect";
            }
            errorSsid = ssid;
            errorClearTimer.restart();
            console.warn(`Wi-Fi connect to "${ssid}" failed: ${msg.split("\n")[0]}`);

            // nmcli leaves a half-made profile behind after a failed first attempt with a bad
            // password, which then shows up as "Saved" but can never connect. Remove it — but only
            // if WE just created it (it wasn't in the saved list before).
            if (!hadProfile) {
                runAsync(["nmcli", "connection", "delete", "id", ssid]).catch(e => {}).then(() => root.updateSavedNetworks());
            }
        }

        update();
        refreshNetworks();
        updateSavedNetworks();
    }

    Timer {
        id: errorClearTimer
        interval: 8000
        repeat: false
        onTriggered: root.clearError()
    }

    // Kept for callers that hold a WifiAccessPoint (dashboard).
    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        connectToSsid(accessPoint.ssid, "");
    }

    function changePassword(network: WifiAccessPoint, password: string): void {
        connectToSsid(network.ssid, password);
    }

    function disconnectWifiNetwork(): void {
        if (!active) return;
        const name = active.ssid;
        beginAction();
        // Disconnect the device (not `connection down <ssid>`): profile names don't have to
        // equal the SSID, and this also stops NM from instantly auto-reconnecting.
        const p = wifiDevice !== ""
            ? runAsync(["nmcli", "device", "disconnect", wifiDevice])
            : runAsync(["nmcli", "connection", "down", "id", name]);
        p.then(() => {
            endAction();
            update();
            refreshNetworks();
        }).catch(e => {
            console.warn(`Wi-Fi disconnect failed: ${e}`);
            endAction();
            update();
        });
    }

    function forgetNetwork(ssid: string): void {
        beginAction();
        runAsync(["nmcli", "connection", "delete", "id", ssid]).then(() => {
            endAction();
            updateSavedNetworks();
            update();
            refreshNetworks();
        }).catch(e => {
            console.warn(`Wi-Fi forget "${ssid}" failed: ${e}`);
            endAction();
            updateSavedNetworks();
        });
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    function openNetworkSettings() {
        Quickshell.execDetached(["plasmawindowed", "org.kde.plasma.networkmanagement"]);
    }

    // Refresh state and networks when a UI becomes visible
    function refreshForUI() {
        update();
        refreshNetworks();
        if (wifiEnabled) {
            rescanWifi();
        }
    }

    // WiFi icon by strength
    function wifiIconForStrength(strength: int): string {
        if (strength > 80) return Icons.wifiHigh;
        if (strength > 55) return Icons.wifiMedium;
        if (strength > 30) return Icons.wifiLow;
        if (strength > 0) return Icons.wifiNone;
        return Icons.wifiOff;
    }

    // ── Background poll ──────────────────────────────────────────────────
    // ONE poll for every consumer. It only re-reads NetworkManager's cached scan list (cheap);
    // it no longer forces a radio rescan every ~16s like the old refreshForUI() poll did — active
    // scans cause latency spikes and drain battery. Real rescans happen only when a Wi-Fi UI opens
    // or the user presses refresh (NM also scans by itself in the background).
    Timer {
        id: strengthPoll
        // Signal strength drifts slowly and nmcli monitor already pushes every
        // real state change, so poll rarely (and much more rarely on battery).
        interval: (Battery.available && !Battery.isPluggedIn) ? 120000 : 30000
        running: root.wifiEnabled && !SuspendManager.isSuspending
        repeat: true
        onTriggered: root.refreshNetworks()
    }

    Timer {
        id: updateDebouncer
        interval: 200
        repeat: false
        onTriggered: root.performUpdate()
    }

    function update() {
        updateDebouncer.restart();
    }

    property bool updatePending: false

    function performUpdate() {
        if (SuspendManager.isSuspending) return;
        if (pollBusy) {
            // Don't lose the event (the old code just dropped it) — run again when this poll ends.
            updatePending = true;
            return;
        }
        pollBusy = true;
        updatePending = false;
        pollWatchdog.restart();
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true;
        refreshNetworks();
    }

    function finishPoll() {
        pollWatchdog.stop();
        pollBusy = false;
        if (updatePending) update();
    }

    // If a poll process dies without reporting, never leave pollBusy stuck true.
    Timer {
        id: pollWatchdog
        interval: 6000
        repeat: false
        onTriggered: root.finishPoll()
    }

    // nmcli monitor is event-based: every NM change re-triggers update()
    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
        onExited: monitorRestart.restart()
    }

    Timer {
        id: monitorRestart
        interval: 3000
        repeat: false
        onTriggered: subscriber.running = true
    }

    // ── Status ───────────────────────────────────────────────────────────
    Process {
        id: updateConnectionType
        property string buffer: ""
        command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: false
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop();
            let hasEthernet = false;
            let status = "disconnected";
            let device = "";

            for (const line of lines) {
                const f = root.splitEscaped(line);
                if (f.length < 3) continue;
                const type = f[1];
                const state = f.slice(2).join(":");

                if (type === "ethernet") {
                    // startsWith, not includes: "disconnected" also contains "connected"
                    // (the old check reported ethernet as up whenever a cable was merely present).
                    if (state.startsWith("connected")) hasEthernet = true;
                } else if (type === "wifi") {
                    if (device === "") device = f[0];
                    if (state.startsWith("connected")) {
                        status = (connectivity === "limited" || connectivity === "portal") ? "limited" : "connected";
                    } else if (state.startsWith("connecting")) {
                        status = "connecting";
                    } else if (state === "unavailable") {
                        status = "disabled";
                    } else {
                        status = "disconnected";
                    }
                }
            }
            root.wifiStatus = status;
            root.wifiDevice = device;
            root.ethernet = hasEthernet;
            root.wifi = status === "connected";
            root.finishPoll();
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        running: false
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = data.trim() === "enabled";
            }
        }
    }

    // ── Saved networks ───────────────────────────────────────────────────
    function updateSavedNetworks() {
        if (!updateSavedNetworksProcess.running) updateSavedNetworksProcess.running = true;
    }

    Process {
        id: updateSavedNetworksProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                updateSavedNetworksProcess.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const text = updateSavedNetworksProcess.buffer;
            updateSavedNetworksProcess.buffer = "";
            if (exitCode !== 0) return;
            const names = [];
            for (const line of text.trim().split("\n")) {
                if (!line) continue;
                // Profile names may contain escaped colons — parse properly instead of split(":")
                const f = root.splitEscaped(line);
                if (f.length < 2) continue;
                if (f[f.length - 1] === "802-11-wireless") names.push(f.slice(0, -1).join(":"));
            }
            root.savedNetworks = names;
        }
    }

    // ── Scan list ────────────────────────────────────────────────────────
    Process {
        id: getNetworks
        running: true
        // --rescan no: only read NM's cached results. Real scans go through rescanWifi().
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                getNetworks.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const text = getNetworks.buffer;
            getNetworks.buffer = "";

            Qt.callLater(() => {
                // Transient nmcli failure (NM restarting…): keep what we have.
                if (exitCode !== 0 && text.trim().length === 0) return;

                // NOTE: an empty result with exit 0 now clears the list. Before, it returned early,
                // so after turning Wi-Fi off the old networks (and "Connected") stayed on screen.
                const networkMap = new Map();
                for (const line of text.trim().split("\n")) {
                    if (!line) continue;
                    const net = root.splitEscaped(line);
                    if (net.length < 6) continue;

                    const ssid = net[3] || "";
                    if (!ssid) continue;   // hidden network

                    const network = {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]) || 0,
                        frequency: parseInt(net[2]) || 0,
                        ssid: ssid,
                        bssid: net[4] || "",
                        security: net[5] || ""
                    };

                    // One entry per SSID: prefer the connected AP, else the strongest
                    const existing = networkMap.get(ssid);
                    if (!existing || (network.active && !existing.active) || (!network.active && !existing.active && network.strength > existing.strength)) {
                        networkMap.set(ssid, network);
                    }
                }

                const data = Array.from(networkMap.values());
                const rNetworks = root.wifiNetworks;

                // 1. Remove gone networks. Keyed by SSID (we already collapse to one AP per SSID);
                //    the old ssid+bssid+frequency key destroyed and recreated the object whenever
                //    the "strongest AP" flipped, wiping askingPassword state and resetting the list.
                const removed = [];
                for (let i = rNetworks.length - 1; i >= 0; i--) {
                    const rn = rNetworks[i];
                    if (!data.find(n => n.ssid === rn.ssid)) {
                        rNetworks.splice(i, 1);
                        removed.push(rn);
                    }
                }

                // 2. Add/update
                for (const d of data) {
                    const existing = rNetworks.find(n => n.ssid === d.ssid);
                    if (existing) {
                        existing.lastIpcObject = d;
                    } else {
                        rNetworks.push(apComp.createObject(root, { lastIpcObject: d }));
                    }
                }

                // Update the UI list BEFORE destroying removed objects, so no delegate is left
                // pointing at a dead object.
                root.updateFriendlyList();
                for (const rn of removed) rn.destroy();
            });
        }
    }

    Component {
        id: apComp
        WifiAccessPoint {}
    }

    Component.onCompleted: {
        update();
        updateSavedNetworks();
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

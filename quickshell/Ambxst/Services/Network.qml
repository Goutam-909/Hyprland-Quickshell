// Services/Network.qml
// Adapter singleton — NOT a new backend. Everything here forwards straight
// to qs.modules.services.NetworkService (your real nmcli-backed service), so the
// control-center components (written against `Services.Network.*`) share ONE
// source of truth with the NetworkPill / dashboard WifiPanel.
pragma Singleton
import QtQuick
import qs.modules.services as Backend

QtObject {
    id: root

    // ── State ────────────────────────────────────────────────────────────
    readonly property bool wifiEnabled: Backend.NetworkService.wifiEnabled
    readonly property bool scanning:    Backend.NetworkService.wifiScanning
    readonly property int  signalStrength: Backend.NetworkService.networkStrength
    readonly property string connectedSsid: Backend.NetworkService.networkName
    // "disabled" | "disconnected" | "connecting" | "connected" | "limited"
    readonly property string status: Backend.NetworkService.wifiStatus
    readonly property bool connected: status === "connected" || status === "limited"
    readonly property bool limited: status === "limited"
    readonly property bool connecting: Backend.NetworkService.wifiConnecting
    readonly property bool ethernet: Backend.NetworkService.ethernet

    // Connect feedback (per SSID)
    readonly property string connectingSsid: Backend.NetworkService.connectingSsid
    readonly property string errorSsid: Backend.NetworkService.errorSsid
    readonly property string errorText: Backend.NetworkService.errorText
    // Set when a connect failed because a password is missing/wrong — the popup opens its dialog.
    readonly property string passwordRequiredSsid: Backend.NetworkService.passwordRequiredSsid

    // Saved Wi-Fi profile names (nmcli).
    readonly property var savedNetworks: Backend.NetworkService.savedNetworks ?? []

    // Sorted list of live WifiAccessPoint objects (ssid/strength/active/isSecure/security/is5GHz…).
    // The backend only reassigns this when membership/order changes, so a ListView bound to it
    // keeps its rows (and expanded state) while signal strengths update in place.
    readonly property var networks: Backend.NetworkService.friendlyWifiNetworks

    // ── Actions ──────────────────────────────────────────────────────────
    function toggleWifi()          { Backend.NetworkService.toggleWifi() }
    function rescanWifi(force)     { Backend.NetworkService.rescanWifi(force === true) }
    function refreshForUI()        { Backend.NetworkService.refreshForUI() }
    function disconnectFromNetwork() { Backend.NetworkService.disconnectWifiNetwork() }
    function forgetNetwork(ssid)   { Backend.NetworkService.forgetNetwork(ssid) }
    function openSettings()        { Backend.NetworkService.openNetworkSettings() }
    function clearPasswordRequest() { Backend.NetworkService.clearPasswordRequest() }
    function isSaved(ssid)         { return Backend.NetworkService.isSaved(ssid) }

    // password === "" means "connect to an already-known/open network".
    function connectToNetwork(ssid, password) {
        Backend.NetworkService.connectToSsid(ssid, password ?? "")
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) return null;
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    // ---- Debounced refresh (the important part) ----
    Timer {
        id: refreshDebounce
        interval: 100
        onTriggered: {
            getClients.running = true
            getMonitors.running = true
            getWorkspaces.running = true
        }
    }

    function updateAll() {
        if (WM.compositor !== "hyprland") return;
        refreshDebounce.restart()
    }
    function updateWindowList() { updateAll() }
    function updateMonitors()   { updateAll() }
    function updateWorkspaces() { updateAll() }

    // Only call this when RegionSelection opens
    function updateLayers() {
        if (WM.compositor !== "hyprland") return;
        getLayers.running = true
    }

    Component.onCompleted: updateAll()

    Connections {
        target: Hyprland
        enabled: WM.compositor === "hyprland"

        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast",
                "activewindow", "activewindowv2",
                "windowtitle", "windowtitlev2"].includes(event.name)) return;
            root.updateAll()
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text)
                let tmp = {};
                for (var i = 0; i < root.windowList.length; ++i)
                    tmp[root.windowList[i].address] = root.windowList[i];
                root.windowByAddress = tmp;
                root.addresses = root.windowList.map(w => w.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: root.monitors = JSON.parse(monitorsCollector.text)
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: root.layers = JSON.parse(layersCollector.text)
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                var raw = JSON.parse(workspacesCollector.text);
                root.workspaces = raw.filter(ws => ws.id >= 1 && ws.id <= 100);
                let tmp = {};
                for (var i = 0; i < root.workspaces.length; ++i)
                    tmp[root.workspaces[i].id] = root.workspaces[i];
                root.workspaceById = tmp;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }
}

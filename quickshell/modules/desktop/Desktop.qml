import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.desktop
import qs.modules.services
import qs.modules.theme
import qs.config
import "."
import qs.modules.globals

PanelWindow {
    id: desktop

    property int barSize: Config.showBackground ? 44 : 40
    property int bottomTextMargin: 32
    property string barPosition: ["top", "bottom", "left", "right"].includes(Config.bar.position) ? Config.bar.position : "top"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "ambxst:desktop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Show if icons OR cava OR clock is active
    visible: (Config.desktop.iconsEnabled ?? false)
    || (Config.desktop.cavaEnabled ?? false)
    || (Config.desktop.clockEnabled ?? false)

    Component.onCompleted: {
        DesktopService.maxRowsHint = Qt.binding(() => iconContainer.maxRows);
        DesktopService.maxColumnsHint = Qt.binding(() => iconContainer.maxColumns);
    }

    Item {
        id: iconContainer
        anchors.fill: parent
        anchors.margins: 16
        anchors.bottomMargin: desktop.barPosition === "bottom" ? desktop.barSize + 16 : 16
        anchors.topMargin: desktop.barPosition === "top" ? desktop.barSize + 16 : 16
        anchors.leftMargin: desktop.barPosition === "left" ? desktop.barSize + 16 : 16
        anchors.rightMargin: desktop.barPosition === "right" ? desktop.barSize + 16 : 16
        visible: Config.desktop.iconsEnabled ?? false

        property int cellHeight: Config.desktop.iconSize + 40 + Config.desktop.spacingVertical
        property int cellWidth: cellHeight
        property int maxRows: Math.floor(height / cellHeight)
        property int maxColumns: Math.floor(width / cellWidth)

        Repeater {
            model: DesktopService.items

            delegate: Item {
                id: delegateRoot
                required property string name
                required property string path
                required property string type
                required property string icon
                required property bool isDesktopFile
                required property bool isPlaceholder
                required property int index

                width: iconContainer.cellWidth
                height: iconContainer.cellHeight

                x: Math.floor(index / iconContainer.maxRows) * iconContainer.cellWidth
                y: (index % iconContainer.maxRows) * iconContainer.cellHeight

                visible: !isPlaceholder

                Behavior on x {
                    enabled: !dragHandler.active && Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    enabled: !dragHandler.active && Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                DesktopIcon {
                    id: iconItem
                    anchors.fill: parent

                    itemName: delegateRoot.name
                    itemPath: delegateRoot.path
                    itemType: delegateRoot.type
                    itemIcon: delegateRoot.icon
                    isDesktopFile: delegateRoot.isDesktopFile

                    onActivated: {
                        console.log("Activated:", itemName);
                    }

                    onContextMenuRequested: {
                        console.log("Context menu requested for:", itemName);
                        Visibilities.contextMenu.openCustomMenu([
                            {
                                text: "Open",
                                icon: Icons.launch,
                                isSeparator: false,
                                onTriggered: function () {
                                    if (delegateRoot.isDesktopFile) {
                                        DesktopService.executeDesktopFile(delegateRoot.path);
                                    } else {
                                        DesktopService.openFile(delegateRoot.path);
                                    }
                                }
                            },
                            {
                                isSeparator: true,
                                text: ""
                            },
                            {
                                text: "Delete",
                                icon: Icons.trash,
                                textColor: Colors.overError,
                                highlightColor: Colors.error,
                                isSeparator: false,
                                onTriggered: function () {
                                    DesktopService.trashFile(delegateRoot.path);
                                }
                            }
                        ], 160, 32, "desktop");
                    }

                    opacity: dragHandler.active ? 0.3 : 1.0

                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }

                    DragHandler {
                        id: dragHandler
                        target: dragPreview
                        onActiveChanged: {
                            if (!active) {
                                var targetIndex = delegateRoot.index;

                                console.log("Drop - Drag.target:", dragPreview.Drag.target);

                                if (dragPreview.Drag.target && dragPreview.Drag.target.visualIndex !== undefined) {
                                    targetIndex = dragPreview.Drag.target.visualIndex;
                                    console.log("Using Drag.target visualIndex:", targetIndex);
                                } else {
                                    var gridPos = iconContainer.mapFromItem(dragPreview.parent, dragPreview.x, dragPreview.y);
                                    var dropX = gridPos.x + dragPreview.width / 2;
                                    var dropY = gridPos.y + dragPreview.height / 2;

                                    if (dropX >= 0 && dropY >= 0 && dropX < iconContainer.width && dropY < iconContainer.height) {
                                        var col = Math.floor(dropX / iconContainer.cellWidth);
                                        var row = Math.floor(dropY / iconContainer.cellHeight);

                                        col = Math.max(0, Math.min(col, iconContainer.maxColumns - 1));
                                        row = Math.max(0, Math.min(row, iconContainer.maxRows - 1));

                                        targetIndex = col * iconContainer.maxRows + row;
                                        console.log("Calculated targetIndex:", targetIndex, "col:", col, "row:", row);
                                    }
                                }

                                if (targetIndex !== delegateRoot.index) {
                                    console.log("Moving from", delegateRoot.index, "to", targetIndex);
                                    DesktopService.moveItem(delegateRoot.index, targetIndex);
                                }

                                dragPreview.Drag.drop();
                            }
                        }
                    }
                }

                Item {
                    id: dragPreview
                    parent: iconContainer
                    width: delegateRoot.width
                    height: delegateRoot.height
                    visible: dragHandler.active
                    z: 999

                    DesktopIcon {
                        anchors.fill: parent
                        itemName: delegateRoot.name
                        itemPath: delegateRoot.path
                        itemType: delegateRoot.type
                        itemIcon: delegateRoot.icon
                        isDesktopFile: delegateRoot.isDesktopFile
                        opacity: 0.7
                        scale: 1.05
                    }

                    Drag.active: dragHandler.active
                    Drag.source: delegateRoot
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    Drag.keys: ["desktopIcon"]
                }

                DropArea {
                    anchors.fill: parent
                    keys: ["desktopIcon"]

                    property int visualIndex: delegateRoot.index

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: Styling.srItem("overprimary")
                        border.width: 2
                        radius: Styling.radius(0) / 2
                        visible: parent.containsDrag
                        opacity: 0.5
                    }
                }
            }
        }
    }

    // ── Cava visualizer instances ─────────────────────────────────────────────
    Repeater {
        model: (Config.desktop.cavaEnabled ?? false)
        ? (Config.desktop.cavaInstances ?? [])
        : []

        delegate: DesktopCavaWidget {
            id: cavaDelegate
            required property var modelData
            required property int index

            instanceIndex: index
            instanceConfig: modelData

            readonly property real instW: (modelData.w ?? 0) <= 0 ? desktop.width : modelData.w
            readonly property real instH: modelData.h ?? 160
            readonly property real baseX: modelData.x ?? 0
            readonly property real baseY: {
                if (modelData.fromBottom ?? true) {
                    let barOffset = desktop.barPosition === "bottom" ? desktop.barSize + 8 : 8;
                    return desktop.height - instH - barOffset - (modelData.y ?? 8);
                }
                return modelData.y ?? 0;
            }

            x:      baseX + dragDeltaX
            y:      baseY + dragDeltaY
            width:  instW
            height: instH

            onMoved: (idx, nx, ny, fb) => {
                let arr = JSON.parse(JSON.stringify(Config.desktop.cavaInstances ?? []));
                if (arr[idx]) {
                    arr[idx].x = Math.round(nx);
                    arr[idx].y = Math.round(ny);
                    arr[idx].fromBottom = false;
                    Config.desktop.cavaInstances = arr;
                    GlobalStates.markShellChanged();
                }
            }

            onResized: (idx, nw, nh) => {
                let arr = JSON.parse(JSON.stringify(Config.desktop.cavaInstances ?? []));
                if (arr[idx]) {
                    arr[idx].w = Math.round(nw);
                    arr[idx].h = Math.round(nh);
                    Config.desktop.cavaInstances = arr;
                    GlobalStates.markShellChanged();
                }
            }

            onInstanceSettingsChanged: (idx, settings) => {
                let arr = JSON.parse(JSON.stringify(Config.desktop.cavaInstances ?? []));
                if (idx >= 0 && idx < arr.length) {
                    arr[idx] = settings;
                    Config.desktop.cavaInstances = arr;
                    GlobalStates.markShellChanged();
                }
            }

            onDuplicateRequested: (idx) => {
                let arr = JSON.parse(JSON.stringify(Config.desktop.cavaInstances ?? []));
                let src = arr[idx] ?? {};
                let newInst = JSON.parse(JSON.stringify(src));
                newInst.x = (src.x ?? 0) + 40;
                newInst.y = (src.y ?? 0) + 40;
                newInst.fromBottom = false;
                arr.push(newInst);
                Config.desktop.cavaInstances = arr;
                GlobalStates.markShellChanged();
            }

            onDeleteRequested: (idx) => {
                let arr = JSON.parse(JSON.stringify(Config.desktop.cavaInstances ?? []));
                arr.splice(idx, 1);
                Config.desktop.cavaInstances = arr;
                GlobalStates.markShellChanged();
            }
        }
    }

    // ── Clock widget ──────────────────────────────────────────────────────────
    // Position is read from Config.desktop.clockX / clockY (desktop.json).
    // Auto-positioning is handled externally from the wallpaper manager.
    // REMOVED: clockAutoPositionProc Process + onClockEnabledChanged Connections

    DesktopClockWidget {
        id: clockWidget
        visible: Config.desktop.clockEnabled ?? false

        // Base position comes from saved config; drag delta is the widget's own
        // property updated by its internal DragHandler — same pattern as cava.
        readonly property real baseX: Config.desktop.clockX ?? 0
        readonly property real baseY: Config.desktop.clockY ?? 0

        x: baseX + dragDeltaX
        y: baseY + dragDeltaY

        // Smooth glide when the script updates clockX/clockY.
        // Disabled during drag so the widget tracks the cursor instantly.
        Behavior on x {
            enabled: !clockWidget.isDragging && Config.animDuration > 0
            NumberAnimation {
                duration: 700
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            enabled: !clockWidget.isDragging && Config.animDuration > 0
            NumberAnimation {
                duration: 700
                easing.type: Easing.OutCubic
            }
        }

        instanceConfig: ({
            color: Config.desktop.clockColor ?? "auto"
        })

        onMoved: (nx, ny) => {
            Config.desktop.clockX = Math.round(nx)
            Config.desktop.clockY = Math.round(ny)
            Config.saveDesktop()
            GlobalStates.markShellChanged()
        }

        onInstanceSettingsChanged: settings => {
            if (settings.color !== undefined)
                Config.desktop.clockColor = settings.color
                Config.saveDesktop()
                GlobalStates.markShellChanged()
        }

        onDeleteRequested: {
            Config.desktop.clockEnabled = false
            Config.saveDesktop()
            GlobalStates.markShellChanged()
        }
    }

    // ── Loading indicator ─────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width: 200
        height: 60
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: Styling.radius(0)
        visible: !DesktopService.initialLoadComplete

        Text {
            anchors.centerIn: parent
            text: "Loading desktop..."
            color: "white"
            font.family: Config.defaultFont
            font.pixelSize: Styling.fontSize(0)
        }
    }
}

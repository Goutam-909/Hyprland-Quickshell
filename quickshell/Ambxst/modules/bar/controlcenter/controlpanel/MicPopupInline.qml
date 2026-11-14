// Widgets/controlpanel/MicPopupInline.qml
// Mirrors VolumeMixerPopupInline.qml exactly, swapped for the microphone
// (input) instead of speakers (output). Uses Services.Audio.source +
// Pipewire per-app input-stream nodes. Input device switching is inline —
// chevron on the master row expands a device list, same pattern.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Services as Services
import qs.modules.services as Backend
import qs.common
import qs.modules.theme

Item {
    id: root

    property bool open: false
    signal requestClose()

    // ── State ─────────────────────────────────────────────────────────────────
    property bool devicePickerOpen: false

    function safeVol(audio) {
        if (!audio) return 0.5
            const v = audio.volume
            return (v === undefined || v === null || isNaN(v) || v < 0) ? 0.5 : v
    }

    function clamp(n, lo, hi) { return Math.max(lo, Math.min(hi, n)) }

    // Strips verbose driver prefixes that pollute device names (e.g. "Alder Lake PCH-P …")
    function nodeLabel(n) {
        if (!n) return "Unknown"
            let label = String(n.description || n.nick || n.name || "Unknown")
            const prefixes = [
                "Alder Lake PCH-P High Definition Audio Controller ",
                "High Definition Audio Controller ",
                "Audio Controller ",
            ]
            for (const p of prefixes) {
                if (label.startsWith(p)) { label = label.substring(p.length); break }
            }
            return label
    }

    // Physical input devices (sources, not per-app streams)
    readonly property list<PwNode> sourceDevices: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream)

    // App input streams only (apps actively capturing the mic)
    readonly property list<PwNode> appNodes: Pipewire.nodes.values.filter(n => !n.isSink && n.isStream)

    // ── Whole popup fades in/out ──────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 14
        opacity: root.open ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 150 } }

        // ── ONE big card — master row + device picker + divider + app rows ────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Styling.radius(8)  // matches the outer BarPopup's own radius
            color: Appearance.colors.colSurfaceContainerHigh
            clip: true

            // Details button - bottom left (opens Plasma's sound settings module — covers mic/input too)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: 12
                anchors.leftMargin: 12
                width: 36
                height: 36
                radius: 18
                z: 100
                color: detailsArea.containsMouse
                ? (detailsArea.pressed ? Appearance.colors.colLayer3Active : Appearance.colors.colLayer3Hover)
                : Appearance.colors.colLayer3

                Behavior on color { ColorAnimation { duration: 150 } }

                MaterialSymbol {
                    anchors.centerIn: parent
                    icon: "open_in_new"
                    iconSize: 18
                    color: Appearance.colors.colOnSurfaceVariant
                }

                MouseArea {
                    id: detailsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Plasma 6 binary is "systemsettings" (Plasma 5 used
                    // "systemsettings5") — change if you're on Plasma 5.
                    onClicked: Quickshell.execDetached(["systemsettings", "kcm_pulseaudio"])
                }
            }

            // Done button - bottom right (pill with label, bigger tap target)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: 12
                anchors.rightMargin: 12
                implicitWidth: doneRow.implicitWidth + 24
                implicitHeight: 36
                width: implicitWidth
                height: implicitHeight
                radius: height / 2
                z: 100
                color: doneArea.containsMouse
                ? (doneArea.pressed ? Appearance.colors.colLayer3Active : Appearance.colors.colLayer3Hover)
                : Appearance.colors.colLayer3

                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: doneRow
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "done"
                        iconSize: 18
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Done"
                        font.family: Appearance.font.family.main
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                MouseArea {
                    id: doneArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestClose()
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // ── Master output row ─────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: 30
                    color: masterHover.containsMouse
                    ? (masterHover.pressed ? Appearance.colors.colLayer2Active
                    : Appearance.colors.colLayer2Hover)
                    : "transparent"
                    scale: masterHover.pressed ? 0.98 : 1

                    Behavior on color { ColorAnimation  { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Icon circle — click = mute toggle
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 40; implicitHeight: 40
                            radius: 20
                            color: (Services.Audio.micReady && Services.Audio.sourceMuted)
                            ? Appearance.colors.colSurfaceContainerHighest
                            : Appearance.colors.colPrimary

                            Behavior on color { ColorAnimation { duration: 200 } }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                icon: (Services.Audio.micReady && Services.Audio.sourceMuted)
                                ? "mic_off"
                                : "mic"
                                iconSize: 22
                                color: (Services.Audio.micReady && Services.Audio.sourceMuted)
                                ? Appearance.colors.colOnSurfaceVariant
                                : Appearance.colors.colOnPrimary
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Services.Audio.toggleMicMute()
                            }
                        }

                        // Name + subtitle
                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: Services.Audio.micReady
                                ? root.nodeLabel(Services.Audio.source)
                                : "System Input"
                                font.family: Appearance.font.family.main
                                font.pixelSize: 14; font.weight: Font.Medium
                                color: Appearance.colors.colOnSurface
                                elide: Text.ElideRight
                            }
                            Text {
                                text: Services.Audio.micReady
                                ? (Services.Audio.sourceMuted
                                ? "Muted"
                                : Math.round(Services.Audio.sourceVolume * 100) + "%")
                                : "–"
                                font.family: Appearance.font.family.main; font.pixelSize: 11
                                color: (Services.Audio.micReady && Services.Audio.sourceMuted)
                                ? Appearance.colors.colError
                                : Appearance.colors.colPrimary
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        // ── Chevron — toggles the device picker ───────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 36; implicitHeight: 36
                            radius: 18
                            color: chevronArea.pressed
                            ? Appearance.colors.colLayer3Active
                            : (chevronArea.containsMouse ? Appearance.colors.colLayer3Hover
                            : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                icon: "expand_more"
                                iconSize: 22
                                color: root.devicePickerOpen
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnSurfaceVariant
                                rotation: root.devicePickerOpen ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color    { ColorAnimation  { duration: 200 } }
                            }

                            MouseArea {
                                id: chevronArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.devicePickerOpen = !root.devicePickerOpen
                            }
                        }
                    }

                    // Full-row hover area (behind icon / chevron clicks)
                    MouseArea {
                        id: masterHover; anchors.fill: parent
                        hoverEnabled: true; z: -1
                        propagateComposedEvents: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => mouse.accepted = false
                    }
                }

                // ── Device picker (collapsible) ───────────────────────────────
                Item {
                    width: parent.width
                    height: root.devicePickerOpen ? devicePickerContent.implicitHeight : 0
                    clip: true
                    visible: root.sourceDevices.length > 0

                    Behavior on height {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    Column {
                        id: devicePickerContent
                        width: parent.width
                        spacing: 2

                        // Small section label
                        Text {
                            leftPadding: 14
                            topPadding: 4
                            text: "Input Device"
                            font.family: Appearance.font.family.main
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurfaceVariant
                            opacity: 0.7
                        }

                        Repeater {
                            model: root.sourceDevices

                            delegate: Item {
                                id: deviceItem
                                width: devicePickerContent.width
                                height: 46

                                required property var modelData
                                property PwNode node: modelData

                                PwObjectTracker { objects: [deviceItem.node] }

                                readonly property bool isCurrent:
                                Pipewire.defaultAudioSource !== null &&
                                deviceItem.node !== null &&
                                Pipewire.defaultAudioSource === deviceItem.node

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 23
                                    color: deviceRowArea.containsMouse
                                    ? (deviceRowArea.pressed ? Appearance.colors.colLayer2Active
                                    : Appearance.colors.colLayer2Hover)
                                    : (deviceItem.isCurrent
                                    ? Qt.rgba(
                                        Appearance.colors.colPrimary.r,
                                        Appearance.colors.colPrimary.g,
                                        Appearance.colors.colPrimary.b,
                                        0.1)
                                    : "transparent")

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        spacing: 10

                                        // Active dot
                                        Rectangle {
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitWidth: 8; implicitHeight: 8
                                            radius: 4
                                            color: deviceItem.isCurrent
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colOnSurfaceVariant
                                            opacity: deviceItem.isCurrent ? 1.0 : 0.4
                                            scale: deviceItem.isCurrent ? 1.0 : 0.75

                                            Behavior on color   { ColorAnimation  { duration: 200 } }
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        }

                                        // Device label
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.nodeLabel(deviceItem.node)
                                            font.family: Appearance.font.family.main
                                            font.pixelSize: 13
                                            font.weight: deviceItem.isCurrent ? Font.Medium : Font.Normal
                                            color: deviceItem.isCurrent
                                            ? Appearance.colors.colOnSurface
                                            : Appearance.colors.colOnSurfaceVariant
                                            elide: Text.ElideRight
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }

                                        // Checkmark (active device)
                                        MaterialSymbol {
                                            icon: "check"
                                            iconSize: 18
                                            color: Appearance.colors.colPrimary
                                            opacity: deviceItem.isCurrent ? 1 : 0
                                            scale: deviceItem.isCurrent ? 1 : 0.6
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                            Behavior on scale   {
                                                NumberAnimation {
                                                    duration: 250
                                                    easing.type: Easing.OutBack
                                                    easing.overshoot: 1.2
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: deviceRowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (deviceItem.node && !deviceItem.isCurrent) {
                                                Quickshell.execDetached(["wpctl", "set-default", String(deviceItem.node.id)])
                                            }
                                            root.devicePickerOpen = false
                                        }
                                    }
                                }
                            }
                        }

                        // Breathing room below list
                        Item { width: 1; height: 4 }
                    }
                }

                // ── Divider ───────────────────────────────────────────────────
                Rectangle {
                    width: parent.width - 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 1
                    color: Appearance.colors.colOutlineVariant
                    opacity: 0.5
                    visible: root.appNodes.length > 0
                }

                // ── App stream rows (scrollable if many) ──────────────────────
                Flickable {
                    width: parent.width
                    height: Math.min(root.appNodes.length * 80, 260)
                    contentHeight: appCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    visible: root.appNodes.length > 0

                    Column {
                        id: appCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.appNodes

                            delegate: Item {
                                id: streamItem
                                width: appCol.width
                                implicitHeight: 80

                                required property var modelData
                                property PwNode node: modelData

                                PwObjectTracker { objects: [streamItem.node] }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 30
                                    color: rowHover.containsMouse
                                    ? (rowHover.pressed ? Appearance.colors.colLayer2Active
                                    : Appearance.colors.colLayer2Hover)
                                    : "transparent"
                                    scale: rowHover.pressed ? 0.98 : 1

                                    Behavior on color { ColorAnimation  { duration: 200 } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 12

                                        // App icon circle
                                        Rectangle {
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitWidth: 40; implicitHeight: 40
                                            radius: 20
                                            color: Appearance.colors.colSecondaryContainer

                                            Image {
                                                id: appIcon
                                                anchors.centerIn: parent
                                                width: 24; height: 24
                                                sourceSize.width: 24; sourceSize.height: 24
                                                visible: status === Image.Ready
                                                cache: false
                                                source: {
                                                    const n = streamItem.node
                                                    if (!n || !n.properties) return Quickshell.iconPath("audio-x-generic", "")
                                                        const name = n.properties["application.icon-name"]
                                                        ?? n.properties["application.name"]
                                                        ?? n.properties["node.name"]
                                                        ?? ""
                                                        return Quickshell.iconPath(Backend.AppSearch.guessIcon(name), "audio-x-generic")
                                                }
                                                onStatusChanged: {
                                                    if (status === Image.Error)
                                                        source = Quickshell.iconPath("audio-x-generic", "")
                                                }
                                            }

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                icon: "mic"; iconSize: 20
                                                color: Appearance.colors.colOnSecondaryContainer
                                                visible: appIcon.status !== Image.Ready
                                            }
                                        }

                                        // App name + volume slider
                                        Column {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 5

                                            Text {
                                                width: parent.width
                                                text: {
                                                    const n = streamItem.node
                                                    if (!n || !n.properties) return "Unknown"
                                                        const app   = n.properties["application.name"]
                                                        const media = n.properties["media.name"]
                                                        const label = app || n.description || n.name || "Unknown"
                                                        return media ? label + " · " + media : label
                                                }
                                                font.family: Appearance.font.family.main
                                                font.pixelSize: 13; font.weight: Font.Medium
                                                color: Appearance.colors.colOnSurface
                                                elide: Text.ElideRight
                                            }

                                            // Volume slider
                                            Item {
                                                width: parent.width
                                                height: 20

                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width
                                                    height: 14
                                                    radius: 7
                                                    color: Appearance.colors.colSurfaceContainerHighest
                                                }

                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width * root.safeVol(streamItem.node.audio)
                                                    height: 14
                                                    radius: 7
                                                    color: Appearance.colors.colPrimary

                                                    Behavior on width {
                                                        NumberAnimation { duration: sliderArea.pressed ? 0 : 200 }
                                                    }
                                                }

                                                MouseArea {
                                                    id: sliderArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor

                                                    onPressed:  function(mouse) { updateVolume(mouse.x) }
                                                    onPositionChanged: function(mouse) {
                                                        if (pressed) updateVolume(mouse.x)
                                                    }

                                                    function updateVolume(x) {
                                                        if (!streamItem.node || !streamItem.node.audio) return
                                                            streamItem.node.audio.volume = root.clamp(x / width, 0, 1)
                                                    }
                                                }
                                            }

                                            Text {
                                                text: (streamItem.node.audio && streamItem.node.audio.muted)
                                                ? "Muted"
                                                : Math.round(root.safeVol(streamItem.node.audio) * 100) + "%"
                                                font.family: Appearance.font.family.main; font.pixelSize: 11
                                                color: (streamItem.node.audio && streamItem.node.audio.muted)
                                                ? Appearance.colors.colError
                                                : Appearance.colors.colOnSurfaceVariant
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                        }

                                        // Mute toggle button
                                        Rectangle {
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitWidth: 36; implicitHeight: 36
                                            radius: 18
                                            color: appMuteArea.pressed
                                            ? Appearance.colors.colLayer3Active
                                            : (appMuteArea.containsMouse ? Appearance.colors.colLayer3Hover
                                            : Appearance.colors.colLayer3)
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                icon: (streamItem.node.audio && streamItem.node.audio.muted)
                                                ? "mic_off" : "mic"
                                                iconSize: 20
                                                color: (streamItem.node.audio && streamItem.node.audio.muted)
                                                ? Appearance.colors.colError
                                                : Appearance.colors.colOnSurfaceVariant
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            MouseArea {
                                                id: appMuteArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (streamItem.node.audio)
                                                        streamItem.node.audio.muted = !streamItem.node.audio.muted
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: rowHover; anchors.fill: parent
                                        hoverEnabled: true; z: -1
                                        propagateComposedEvents: true
                                        onClicked: mouse => mouse.accepted = false
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Empty state (no apps) ─────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 10
                    visible: root.appNodes.length === 0
                    topPadding: 24; bottomPadding: 24

                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: "mic_off"; iconSize: 44
                        color: Appearance.colors.colOnSurfaceVariant; opacity: 0.4
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No apps using the microphone"
                        font.family: Appearance.font.family.main; font.pixelSize: 13
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }
    }
}

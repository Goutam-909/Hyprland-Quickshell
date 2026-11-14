import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config
import qs.modules.widgets.dashboard.controls
// MediaControlsPill – Volume, Mic, and Brightness in a single pill.
// Drop-in replacement for the inline audioControlsPill block in BarContent.qml.
//
// Required properties:
//   bar        – reference to the root BarContent item (for screen, shadowsEnabled, innerRadius)
//
// Usage in BarContent.qml horizontal layout (replace the old audioControlsPill StyledRect):
//   MediaControlsPill {
//       bar: root
//       startRadius: root.innerRadius
//       endRadius:   root.innerRadius
//       enableShadow: root.shadowsEnabled
//   }

Item {
    id: root

    // Provided by BarContent
    required property var bar

    property real startRadius: Styling.radius(0)
    property real endRadius:   Styling.radius(0)
    property bool enableShadow: false

    // Convenience alias so callers can bind Layout properties directly
    implicitWidth:  pill.implicitWidth
    implicitHeight: pill.implicitHeight

    // ── Outer pill ────────────────────────────────────────────────────────────
    StyledRect {
        id: pill
        variant: "bg"
        anchors.fill: parent
        implicitWidth:  pillInner.implicitWidth +4
        implicitHeight: 36
        radius: Styling.radius(4)
        enableBorder: true
        enableShadow: root.enableShadow

        topLeftRadius:     root.startRadius
        bottomLeftRadius:  root.startRadius
        topRightRadius:    root.endRadius
        bottomRightRadius: root.endRadius

        // ── Pill-level right-click → open volume mixer ──────────────────
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: mixerPopup.toggle()
            propagateComposedEvents: true
        }

        // ── Volume Mixer Popup ───────────────────────────────────────────
        BarPopup {
            id: mixerPopup
            anchorItem: pill
            bar: root.bar
            contentWidth: 340
            contentHeight: 420
            popupPadding: 12

            AudioMixerPanel {
                anchors.fill: parent
            }
        }

        // ── Inner tinted background ───────────────────────────────────────────
        StyledRect {
            id: pillInner
            variant: "bg"
            anchors.centerIn: parent
            implicitWidth:  pillRow.implicitWidth + 8
            implicitHeight: 32
            radius: Styling.radius(0)

            RowLayout {
                id: pillRow
                anchors.centerIn: parent
                spacing: 4

                // ── Volume ────────────────────────────────────────────────────
                Item {
                    id: volumeControl
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth:  28
                    Layout.preferredHeight: 28
                    width:  28
                    height: 28

                    property bool isHovered: false

                    HoverHandler {
                        onHoveredChanged: volumeControl.isHovered = hovered
                    }

                    Item {
                        id: volumeArc
                        anchors.centerIn: parent
                        width:  36
                        height: 36

                        property real angle: (Audio.sink?.audio?.volume ?? 0) * (360 - 2 * gapAngle)
                        property real arcRadius: 12
                        property real lineWidth: 3
                        property real gapAngle:  45
                        property bool muted: Audio.sink?.audio?.muted ?? false

                        Canvas {
                            id: volumeCanvas
                            anchors.fill: parent
                            antialiasing: true

                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.reset();
                                let cx = width / 2, cy = height / 2;
                                let r  = volumeArc.arcRadius;
                                let lw = volumeArc.lineWidth;
                                let baseStart     = (Math.PI / 2) + (volumeArc.gapAngle * Math.PI / 180);
                                let totalAngle    = (360 - 2 * volumeArc.gapAngle) * Math.PI / 180;
                                let progressAngle = volumeArc.angle * Math.PI / 180;
                                ctx.lineCap     = "round";
                                // normal:  filled=primary,        track=outlineVariant
                                // muted:   filled=outlineVariant,  track=outline  (swapped, dimmed)
                                ctx.strokeStyle = volumeArc.muted ? Colors.outlineVariant        : Colors.outlineVariant;
                                ctx.lineWidth   = lw;
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, baseStart + progressAngle, baseStart + totalAngle, false);
                                ctx.stroke();
                                if (progressAngle > 0) {
                                    ctx.strokeStyle = volumeArc.muted ? Colors.outline : Colors.primary;
                                    ctx.lineWidth   = lw;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, baseStart, baseStart + progressAngle, false);
                                    ctx.stroke();
                                }
                            }

                            Connections {
                                target: volumeArc
                                function onAngleChanged()  { volumeCanvas.requestPaint(); }
                                function onMutedChanged()  { volumeCanvas.requestPaint(); }
                            }

                            Connections {
                                target: Colors
                                function onPrimaryChanged()        { volumeCanvas.requestPaint(); }
                                function onOutlineVariantChanged() { volumeCanvas.requestPaint(); }
                            }
                        }

                        Behavior on angle {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (Audio.sink?.audio?.muted) return Icons.speakerSlash;
                            const vol = Audio.sink?.audio?.volume ?? 0;
                            if (vol < 0.01) return Icons.speakerX;
                            if (vol < 0.19) return Icons.speakerNone;
                            if (vol < 0.49) return Icons.speakerLow;
                            return Icons.speakerHigh;
                        }
                        font.family:    Icons.font
                        font.pixelSize: 16
                        color: Audio.sink?.audio?.muted ? Colors.outline : Colors.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Audio.sink?.audio)
                                Audio.sink.audio.muted = !Audio.sink.audio.muted;
                        }
                        onWheel: wheel => {
                            if (Audio.sink?.audio) {
                                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                Audio.sink.audio.volume = Math.max(0, Math.min(1, (Audio.sink.audio.volume ?? 0) + delta));
                            }
                        }
                    }

                    StyledToolTip {
                        show: volumeControl.isHovered
                        tooltipText: "Volume: " + Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%" +
                        (Audio.sink?.audio?.muted ? " (Muted)" : "")
                    }
                }

                // ── Mic ───────────────────────────────────────────────────────
                Item {
                    id: micControl
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth:  28
                    Layout.preferredHeight: 28
                    width:  28
                    height: 28

                    property bool isHovered: false

                    HoverHandler {
                        onHoveredChanged: micControl.isHovered = hovered
                    }

                    Item {
                        id: micArc
                        anchors.centerIn: parent
                        width:  36
                        height: 36

                        property real angle: (Audio.source?.audio?.volume ?? 0) * (360 - 2 * gapAngle)
                        property real arcRadius: 12
                        property real lineWidth: 3
                        property real gapAngle:  45
                        property bool muted: Audio.source?.audio?.muted ?? false

                        Canvas {
                            id: micCanvas
                            anchors.fill: parent
                            antialiasing: true

                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.reset();
                                let cx = width / 2, cy = height / 2;
                                let r  = micArc.arcRadius;
                                let lw = micArc.lineWidth;
                                let baseStart     = (Math.PI / 2) + (micArc.gapAngle * Math.PI / 180);
                                let totalAngle    = (360 - 2 * micArc.gapAngle) * Math.PI / 180;
                                let progressAngle = micArc.angle * Math.PI / 180;
                                ctx.lineCap     = "round";
                                // normal:  filled=primary,        track=outlineVariant
                                // muted:   filled=outlineVariant,  track=outline  (swapped, dimmed)
                                ctx.strokeStyle = micArc.muted ? Colors.outlineVariant        : Colors.outlineVariant;
                                ctx.lineWidth   = lw;
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, baseStart + progressAngle, baseStart + totalAngle, false);
                                ctx.stroke();
                                if (progressAngle > 0) {
                                    ctx.strokeStyle = micArc.muted ? Colors.outline : Colors.primary;
                                    ctx.lineWidth   = lw;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, baseStart, baseStart + progressAngle, false);
                                    ctx.stroke();
                                }
                            }

                            Connections {
                                target: micArc
                                function onAngleChanged() { micCanvas.requestPaint(); }
                                function onMutedChanged() { micCanvas.requestPaint(); }
                            }

                            Connections {
                                target: Colors
                                function onPrimaryChanged()        { micCanvas.requestPaint(); }
                                function onOutlineVariantChanged() { micCanvas.requestPaint(); }
                            }
                        }

                        Behavior on angle {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Audio.source?.audio?.muted ? Icons.micSlash : Icons.mic
                        font.family:    Icons.font
                        font.pixelSize: 16
                        color: Audio.source?.audio?.muted ? Colors.outline : Colors.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Audio.source?.audio)
                                Audio.source.audio.muted = !Audio.source.audio.muted;
                        }
                        onWheel: wheel => {
                            if (Audio.source?.audio) {
                                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                Audio.source.audio.volume = Math.max(0, Math.min(1, (Audio.source.audio.volume ?? 0) + delta));
                            }
                        }
                    }

                    StyledToolTip {
                        show: micControl.isHovered
                        tooltipText: "Mic: " + Math.round((Audio.source?.audio?.volume ?? 0) * 100) + "%" +
                        (Audio.source?.audio?.muted ? " (Muted)" : "")
                    }
                }

                // ── Brightness ────────────────────────────────────────────────
                Item {
                    id: brightnessControl
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth:  28
                    Layout.preferredHeight: 28
                    width:  28
                    height: 28

                    property bool isHovered: false
                    property var currentMonitor: Brightness.getMonitorForScreen(root.bar.screen)

                    HoverHandler {
                        onHoveredChanged: brightnessControl.isHovered = hovered
                    }

                    Item {
                        id: brightnessArc
                        anchors.centerIn: parent
                        width:  36
                        height: 36

                        property real brightnessValue: brightnessControl.currentMonitor?.brightness ?? 0
                        property real angle: brightnessValue * (360 - 2 * gapAngle)
                        property real arcRadius: 12
                        property real lineWidth: 3
                        property real gapAngle:  45

                        Canvas {
                            id: brightnessCanvas
                            anchors.fill: parent
                            antialiasing: true

                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.reset();
                                let cx = width / 2, cy = height / 2;
                                let r  = brightnessArc.arcRadius;
                                let lw = brightnessArc.lineWidth;
                                let baseStart     = (Math.PI / 2) + (brightnessArc.gapAngle * Math.PI / 180);
                                let totalAngle    = (360 - 2 * brightnessArc.gapAngle) * Math.PI / 180;
                                let progressAngle = brightnessArc.angle * Math.PI / 180;
                                ctx.lineCap      = "round";
                                ctx.strokeStyle  = Colors.outlineVariant;
                                ctx.lineWidth    = lw;
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, baseStart + progressAngle, baseStart + totalAngle, false);
                                ctx.stroke();
                                if (progressAngle > 0) {
                                    ctx.strokeStyle = Colors.primary;
                                    ctx.lineWidth   = lw;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, baseStart, baseStart + progressAngle, false);
                                    ctx.stroke();
                                }
                            }

                            Connections {
                                target: brightnessArc
                                function onAngleChanged()           { brightnessCanvas.requestPaint(); }
                                function onBrightnessValueChanged() { brightnessCanvas.requestPaint(); }
                            }

                            Connections {
                                target: Colors
                                function onPrimaryChanged()        { brightnessCanvas.requestPaint(); }
                                function onOutlineVariantChanged() { brightnessCanvas.requestPaint(); }
                            }
                        }

                        Behavior on angle {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Icons.sun
                        font.family:    Icons.font
                        font.pixelSize: 16
                        color: Colors.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onWheel: wheel => {
                            const monitor = brightnessControl.currentMonitor;
                            if (monitor && monitor.ready) {
                                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                monitor.setBrightness(Math.max(0, Math.min(1, (monitor.brightness ?? 0) + delta)));
                            }
                        }
                    }

                    StyledToolTip {
                        show: brightnessControl.isHovered
                        tooltipText: "Brightness: " + Math.round((brightnessControl.currentMonitor?.brightness ?? 0) * 100) + "%"
                    }
                }
            }
        }
    }
}

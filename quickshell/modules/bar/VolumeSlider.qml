import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.config

Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool isExpanded: false
    property bool externalVolumeChange: false
    property bool layerEnabled: true

    // Guard: true while we are syncing the slider FROM PipeWire.
    // Prevents onValueChanged from writing back and creating a feedback loop.
    property bool syncingFromPipewire: false

    // ── Layout ──────────────────────────────────────────────────────────────
    Layout.preferredWidth:  root.vertical ? 36 : 36
    Layout.preferredHeight: root.vertical ? 36 : 36
    Layout.fillWidth:  root.vertical
    Layout.fillHeight: !root.vertical

    states: State {
        name: "expanded"
        when: root.isExpanded || volumeSlider.isDragging || root.externalVolumeChange
        PropertyChanges {
            target: root
            Layout.preferredWidth:  root.vertical ? 36  : 150
            Layout.preferredHeight: root.vertical ? 150 : 36
        }
    }

    transitions: Transition {
        NumberAnimation {
            properties: "Layout.preferredWidth,Layout.preferredHeight"
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    // ── Hover ────────────────────────────────────────────────────────────────
    HoverHandler {
        onHoveredChanged: {
            root.isHovered = hovered;
            if (!hovered && root.isExpanded && !volumeSlider.isDragging) {
                root.isExpanded = false;
            }
        }
    }

    // ── Initialise slider value once sink is available ───────────────────────
    Component.onCompleted: {
        volumeSlider.value = Audio.sink?.audio?.volume ?? 0;
    }

    // ── Sync slider ← PipeWire ───────────────────────────────────────────────
    // Fires when volume changes externally (wpctl, pavucontrol, keybind, etc.)
    // We raise the guard so onValueChanged does NOT echo the value back.
    Connections {
        target: Audio.sink?.audio ?? null
        ignoreUnknownSignals: true

        function onVolumeChanged() {
            if (!Audio.sink?.audio) return;
            root.syncingFromPipewire = true;
            volumeSlider.value = Audio.sink.audio.volume;
            root.syncingFromPipewire = false;

            root.externalVolumeChange = true;
            externalChangeTimer.restart();
        }
    }

    Timer {
        id: externalChangeTimer
        interval: 1000
        onTriggered: root.externalVolumeChange = false
    }

    // ── UI ───────────────────────────────────────────────────────────────────
    StyledRect {
        variant: "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.isHovered && !root.isExpanded ? 0.25 : 0
            radius: parent.radius ?? 0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration / 2 }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false

            onClicked: {
                root.isExpanded = !root.isExpanded;
            }

            onWheel: wheel => {
                if (!root.isExpanded) return;
                // User action → guard is false → onValueChanged will forward to PipeWire
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                volumeSlider.value = Math.max(0, Math.min(1, volumeSlider.value + delta));
            }
        }

        StyledSlider {
            id: volumeSlider

            anchors.fill: parent
            anchors.margins: 8
            anchors.rightMargin: root.vertical ? 8  : 16
            anchors.topMargin:   root.vertical ? 16 : 8

            vertical:      root.vertical
            smoothDrag:    true
            value:         0
            resizeParent:  false
            wavy:          true
            scroll:        root.isExpanded
            iconClickable: root.isExpanded

            sliderVisible: root.isExpanded || volumeSlider.isDragging || root.externalVolumeChange

            wavyAmplitude: (root.isExpanded || volumeSlider.isDragging || root.externalVolumeChange)
            ? (Audio.sink?.audio?.muted ? 0.5 : 1.5 * value) : 0
            wavyFrequency: (root.isExpanded || volumeSlider.isDragging || root.externalVolumeChange)
            ? (Audio.sink?.audio?.muted ? 1.0 : 8.0 * value) : 0

            iconPos: root.vertical ? "end" : "start"

            icon: {
                if (Audio.sink?.audio?.muted) return Icons.speakerSlash;
                const vol = Audio.sink?.audio?.volume ?? 0;
                if (vol < 0.01) return Icons.speakerX;
                if (vol < 0.19) return Icons.speakerNone;
                if (vol < 0.49) return Icons.speakerLow;
                return Icons.speakerHigh;
            }

            progressColor: Audio.sink?.audio?.muted
            ? Colors.outline
            : Styling.srItem("overprimary")

            // Sync PipeWire ← slider (only for real user interactions)
            onValueChanged: {
                if (root.syncingFromPipewire) return;
                if (Audio.sink?.audio) {
                    Audio.sink.audio.volume = value;
                }
            }

            onIconClicked: {
                if (Audio.sink?.audio) {
                    Audio.sink.audio.muted = !Audio.sink.audio.muted;
                }
            }
        }
    }
}

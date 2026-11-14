import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.theme

// macOS slider. Mirrors the StyledSlider API used by the settings panels:
// value (0‥1), progressColor, tooltipText, scroll, stepSize, snapMode, isDragging.
Item {
    id: root

    property real value: 0
    property color progressColor: MacStyle.accent
    property string tooltipText: `${Math.round(value * 100)}%`
    property bool tooltip: true
    property bool scroll: false
    property real stepSize: 0
    property string snapMode: "none"        // "none" | "always" | "release"
    property bool updateOnRelease: false
    property bool isDragging: false
    property real dragPosition: 0
    // accepted for StyledSlider compatibility (ignored)
    property bool smoothDrag: true
    property bool vertical: false
    property bool resizeParent: true
    property real thickness: 5
    property string icon: ""
    property string iconPos: "start"
    property color iconColor: MacStyle.labelSecondary
    property color backgroundColor: MacStyle.sliderTrack
    property bool wavy: false
    property bool playing: false
    property bool sliderVisible: true
    property bool iconClickable: true

    signal iconClicked
    signal released(real finalValue)

    readonly property real knob: 24
    readonly property real progress: isDragging ? dragPosition : Math.max(0, Math.min(1, value))

    implicitHeight: 28
    implicitWidth: 140
    Layout.fillWidth: true
    opacity: enabled ? 1 : 0.5

    function applyStep(v) {
        const c = Math.max(0, Math.min(1, v));
        return stepSize > 0 ? Math.max(0, Math.min(1, Math.round(c / stepSize) * stepSize)) : c;
    }

    // track
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: root.icon !== "" && root.iconPos === "start" ? iconText.width + 8 : 0
        width: parent.width - x - (root.icon !== "" && root.iconPos === "end" ? iconText.width + 8 : 0)
        height: root.thickness
        radius: height / 2
        color: root.backgroundColor

        Rectangle {
            width: Math.max(0, root.progress * (track.width - root.knob) + root.knob / 2)
            height: parent.height
            radius: height / 2
            color: root.progressColor
        }

        // knob
        Rectangle {
            id: handle
            x: root.progress * (track.width - width)
            anchors.verticalCenter: parent.verticalCenter
            width: root.knob
            height: root.knob
            radius: width / 2
            color: "#FFFFFF"
            border.width: 0.5
            border.color: "#33000000"

            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.topMargin: 1
                radius: width / 2
                color: "#40000000"
            }

            Behavior on x {
                enabled: !root.isDragging && Config.animDuration > 0
                NumberAnimation {
                    duration: MacStyle.fast
                    easing.type: Easing.OutCubic
                }
            }
        }

        // value bubble while dragging
        Rectangle {
            visible: root.tooltip && root.tooltipText !== "" && root.isDragging
            x: handle.x + handle.width / 2 - width / 2
            y: -height - 8
            width: bubble.implicitWidth + 14
            height: 26
            radius: 7
            color: MacStyle.dark ? "#3A3A3C" : "#2C2C2E"
            Text {
                id: bubble
                anchors.centerIn: parent
                text: root.tooltipText
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsSmall
                color: "#FFFFFF"
            }
        }
    }

    Text {
        id: iconText
        visible: root.icon !== ""
        anchors.verticalCenter: parent.verticalCenter
        x: root.iconPos === "start" ? 0 : parent.width - width
        text: root.icon
        font.family: Icons.font
        font.pixelSize: 19
        color: root.iconColor
        MouseArea {
            anchors.fill: parent
            enabled: root.iconClickable
            onClicked: root.iconClicked()
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.leftMargin: track.x
        anchors.rightMargin: root.width - track.x - track.width
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function posToValue(mx) {
            return Math.max(0, Math.min(1, (mx - root.knob / 2) / Math.max(1, track.width - root.knob)));
        }
        function begin(mx) {
            root.isDragging = true;
            move(mx);
        }
        function move(mx) {
            let v = posToValue(mx);
            if (root.snapMode === "always")
                v = root.applyStep(v);
            root.dragPosition = v;
            if (!root.updateOnRelease)
                root.value = v;
        }

        onPressed: mouse => begin(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                move(mouse.x);
        }
        onReleased: {
            let v = root.dragPosition;
            if (root.snapMode !== "none")
                v = root.applyStep(v);
            root.value = v;
            root.isDragging = false;
            root.released(v);
        }
        onWheel: wheel => {
            if (!root.scroll) {
                wheel.accepted = false;
                return;
            }
            const step = root.stepSize > 0 ? root.stepSize : 0.05;
            root.value = root.applyStep(root.value + (wheel.angleDelta.y > 0 ? step : -step));
        }
    }
}

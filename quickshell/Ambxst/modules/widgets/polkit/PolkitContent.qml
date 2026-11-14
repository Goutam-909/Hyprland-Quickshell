pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Item {
    id: root

    required property bool shown
    readonly property bool usePasswordChars: !PolkitService.flow?.responseVisible ?? true
    readonly property string accountName: Quickshell.env("USER") ?? ""

    property bool showError: false
    property real shakeOffset: 0

    // Theme tokens (matugen/pywal-generated schemes especially) can't be trusted
    // to always give readable contrast — e.g. a pastel "primary" with a barely-
    // different "overPrimary". Pick real black/white based on measured luminance
    // instead, so text/icons are never invisible-on-invisible.
    function contrastColor(bg) {
        const luminance = 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b;
        return luminance > 0.55 ? "#1c1c1e" : "#f5f5f7";
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            PolkitService.cancel();
            event.accepted = true;
        }
    }

    function submit() {
        if (!PolkitService.interactionAvailable) return;
        PolkitService.submit(inputField.text);
    }

    onShownChanged: {
        if (shown) {
            root.showError = false;
            Qt.callLater(() => inputField.forceActiveFocus());
        }
    }

    Connections {
        target: PolkitService
        function onInteractionAvailableChanged() {
            if (!PolkitService.interactionAvailable || !root.shown) return;
            inputField.text = "";
            Qt.callLater(() => inputField.forceActiveFocus());
        }
        function onAuthFailed() {
            root.showError = true;
            shakeAnim.restart();
        }
    }

    // Dimmed backdrop behind the card, like macOS's authentication scrim.
    // If your Hyprland config blurs the "quickshell:polkit" layer namespace
    // you'll get a proper vibrancy/blur look behind this automatically.
    Rectangle {
        anchors.fill: parent
        color: Colors.scrim
        opacity: root.shown ? 0.45 : 0

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }
    }

    // The auth card
    Item {
        id: card
        anchors.centerIn: parent
        width: 360
        height: cardBg.implicitHeight

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92

        transform: [
            Translate {
                x: root.shakeOffset
            },
            Translate {
                y: root.shown ? 0 : -16
                Behavior on y {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }
            }
        ]

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }

        Behavior on scale {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }

        // Classic macOS "wrong password" shake
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: root; property: "shakeOffset"; to: -9; duration: 55; easing.type: Easing.OutSine }
            NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: 55; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "shakeOffset"; to: -6; duration: 55; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "shakeOffset"; to: 4; duration: 55; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 55; easing.type: Easing.InOutSine }
        }

        StyledRect {
            id: cardBg
            variant: "bg"
            anchors.fill: parent
            radius: Styling.radius(8)

            implicitHeight: contentColumn.implicitHeight + 56

            layer.enabled: true
            layer.effect: Shadow {}

            ColumnLayout {
                id: contentColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 28
                }
                spacing: 0

                // Icon: padlock with a small badge, like the app-icon badge
                // macOS overlays on its own lock glyph.
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 16
                    width: 60
                    height: 60

                    Text {
                        anchors.centerIn: parent
                        text: Icons.lock
                        font.family: Icons.font
                        font.pixelSize: 48
                        color: "#e3a940"
                    }

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: Colors.primary
                        border.width: 2
                        border.color: Colors.background
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -2
                        anchors.bottomMargin: -2

                        Text {
                            anchors.centerIn: parent
                            text: Icons.shieldCheck
                            font.family: Icons.font
                            font.pixelSize: 11
                            color: root.contrastColor(Colors.primary)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    text: "Authentication Required"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize + 1
                    font.weight: Font.DemiBold
                    color: Colors.overBackground
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: PolkitService.cleanMessage
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 1
                    color: Colors.outline
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 18
                    text: "Enter your password to allow this."
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 1
                    color: Colors.outline
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                // Account name, display-only — matches the read-only "name"
                // field macOS shows above the password box.
                StyledRect {
                    variant: "pane"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Styling.radius(-6)

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        text: root.accountName
                        color: root.contrastColor(Colors.surface)
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize - 1
                    }
                }

                // Password field, with a soft blue focus ring like macOS
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    Layout.topMargin: 6

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: fieldBg.radius + 3
                        color: "transparent"
                        border.width: 3
                        border.color: Colors.primary
                        opacity: inputField.activeFocus ? 0.45 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    StyledRect {
                        id: fieldBg
                        variant: "pane"
                        anchors.fill: parent
                        radius: Styling.radius(-6)

                        // srPane resolves to a solid "surface" fill, so this is a
                        // reliable reference for picking readable field text.
                        readonly property color safeTextColor: root.contrastColor(Colors.surface)

                        TextInput {
                            id: inputField
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            selectByMouse: true
                            enabled: PolkitService.interactionAvailable
                            echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                            color: fieldBg.safeTextColor
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize - 1

                            onTextChanged: {
                                if (root.showError) root.showError = false;
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    PolkitService.cancel();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.submit();
                                    event.accepted = true;
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: PolkitService.cleanPrompt
                                font: inputField.font
                                color: Qt.rgba(fieldBg.safeTextColor.r, fieldBg.safeTextColor.g, fieldBg.safeTextColor.b, 0.55)
                                visible: inputField.text.length === 0 && !inputField.activeFocus
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    text: "Sorry, try again."
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 2
                    color: Colors.error
                    horizontalAlignment: Text.AlignHCenter
                    visible: opacity > 0
                    opacity: root.showError ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // Buttons, stacked full-width — Authenticate on top, Cancel
                // below, matching the modern macOS auth panel layout rather
                // than a side-by-side pair.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 22
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        scale: authArea.pressed ? 0.98 : 1.0
                        opacity: PolkitService.interactionAvailable ? 1 : 0.5

                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        StyledRect {
                            variant: "primary"
                            anchors.fill: parent
                            radius: Styling.radius(-4)

                            Text {
                                anchors.centerIn: parent
                                text: "Authenticate"
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize - 1
                                font.weight: Font.Medium
                                color: root.contrastColor(Colors.primary)
                            }
                        }

                        MouseArea {
                            id: authArea
                            anchors.fill: parent
                            enabled: PolkitService.interactionAvailable
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submit()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        scale: cancelArea.pressed ? 0.98 : 1.0

                        Behavior on scale { NumberAnimation { duration: 100 } }

                        StyledRect {
                            variant: "pane"
                            anchors.fill: parent
                            radius: Styling.radius(-4)

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize - 1
                                color: root.contrastColor(Colors.surface)
                            }
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PolkitService.cancel()
                        }
                    }
                }
            }
        }
    }
}

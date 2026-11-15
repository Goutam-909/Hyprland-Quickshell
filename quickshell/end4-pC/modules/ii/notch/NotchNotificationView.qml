import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets
import qs.modules.common.functions

// Stacked toast-style popups for incoming notifications.
// Simplified from the donor's 867-line version: keeps urgency coloring,
// dismiss button, auto-timeout and stacking, drops the per-card hover-expand
// text reflow (summary/body just wrap normally instead).
Column {
    id: root
    property bool notchHovered: false
    width: 320
    spacing: 8

    Repeater {
        model: Notifications.popupList
        delegate: cardDelegate
    }

    Component {
        id: cardDelegate

        StyledRectangle {
            id: card
            required property var modelData
            readonly property var notification: modelData
            readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical

            contentLayer: StyledRectangle.ContentLayer.Group
            width: root.width
            implicitHeight: contentCol.implicitHeight + 20
            radius: C.Appearance.rounding.normal
            color: critical ? C.Appearance.m3colors.m3errorContainer : C.Appearance.colors.colLayer2

            HoverHandler { id: cardHover }

            RowLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                CustomIcon {
                    visible: notification && notification.appIcon !== ""
                    source: notification ? notification.appIcon : ""
                    width: 28
                    height: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            text: notification ? notification.summary : ""
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            color: card.critical ? C.Appearance.m3colors.m3onErrorContainer : C.Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            text: notification ? NotificationUtils.getFriendlyNotifTimeString(notification.time) : ""
                            font.pixelSize: 11
                            color: C.Appearance.colors.colSubtext
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: notification ? notification.body : ""
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        color: card.critical ? C.Appearance.m3colors.m3onErrorContainer : C.Appearance.colors.colSubtext
                    }
                }

                RippleButtonWithIcon {
                    visible: cardHover.hovered
                    materialIcon: "close"
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: Notifications.discardNotification(notification.id)
                }
            }

            // Auto-dismiss the popup (not the notification history entry)
            Timer {
                running: !root.notchHovered && !cardHover.hovered
                interval: card.critical ? 8000 : 5000
                onTriggered: {
                    if (notification) notification.popup = false;
                }
            }
        }
    }
}

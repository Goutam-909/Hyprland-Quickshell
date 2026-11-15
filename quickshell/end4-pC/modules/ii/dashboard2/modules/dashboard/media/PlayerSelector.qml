pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import qs.modules.ii.dashboard2.utils
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import qs.modules.common
import qs.services

Item {
    id: root

    property bool expanded

    implicitWidth: currentPlayer.implicitWidth + Appearance.dashboard.padding.large * 2
    implicitHeight: currentPlayer.implicitHeight + Appearance.dashboard.padding.small * 2

    MouseArea {
        anchors.fill: parent
        cursorShape: MprisController.players.length > 1 ? Qt.PointingHandCursor : undefined
        onClicked: if (MprisController.players.length > 1)
        root.expanded = !root.expanded
    }

    StyledRect {
        id: bg

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitHeight: wrapper.implicitHeight + Appearance.dashboard.padding.small * 2

        color: Appearance.m3colors.m3primaryContainer
        radius: Appearance.rounding.normal

        Item {
            id: wrapper

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Appearance.dashboard.padding.small

            clip: true
            implicitHeight: root.expanded && MprisController.players.length > 1 ? players.implicitHeight : currentPlayer.implicitHeight

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.dashboard.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasized
                }
            }

            Column {
                id: players

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                spacing: Appearance.dashboard.spacing.small

                Repeater {
                    model: MprisController.players.filter(p => p !== MprisController.activePlayer)

                    Row {
                        id: player

                        required property MprisPlayer modelData

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Appearance.dashboard.spacing.small

                        IconImage {
                            id: playerIcon
                            source: Quickshell.iconPath(AppSearch.guessIcon(player.modelData?.identity ?? ""), "image-missing")
                            implicitSize: Math.round(identity.implicitHeight * 0.9)
                        }

                        StyledText {
                            id: identity
                            text: identityMetrics.elidedText
                            color: Appearance.m3colors.m3secondary

                            TextMetrics {
                                id: identityMetrics
                                text: player.modelData?.identity ?? ""
                                font.family: identity.font.family
                                font.pointSize: identity.font.pointSize
                                elide: Text.ElideRight
                                elideWidth: root.implicitWidth - playerIcon.implicitWidth - player.spacing - Appearance.dashboard.padding.smaller * 2
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (player.modelData)
                                        MprisController.setActivePlayer(player.modelData);
                                    root.expanded = false;
                                }
                            }
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: 1
                    visible: MprisController.players.length > 1

                    StyledRect {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: -Appearance.dashboard.padding.normal
                        color: Appearance.m3colors.m3tertiary
                        implicitHeight: 1
                    }
                }

                Row {
                    id: currentPlayer

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Appearance.dashboard.spacing.small

                    IconImage {
                        id: currentIcon
                        source: Quickshell.iconPath(AppSearch.guessIcon(MprisController.activePlayer?.identity ?? ""), "multimedia-player")
                        implicitSize: Math.round(currentIdentity.implicitHeight * 0.9)
                    }

                    StyledText {
                        id: currentIdentity

                        animate: true
                        text: currentIdentityMetrics.elidedText
                        color: Appearance.m3colors.m3secondary

                        TextMetrics {
                            id: currentIdentityMetrics
                            text: MprisController.activePlayer?.identity ?? qsTr("No players")
                            font.family: currentIdentity.font.family
                            font.pointSize: currentIdentity.font.pointSize
                            elide: Text.ElideRight
                            elideWidth: root.implicitWidth - currentIcon.implicitWidth - currentPlayer.spacing - Appearance.dashboard.padding.smaller * 2
                        }
                    }
                }
            }
        }
    }
}

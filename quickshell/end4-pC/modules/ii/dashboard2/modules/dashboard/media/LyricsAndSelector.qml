pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import qs.modules.ii.dashboard2.utils
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets as CommonWidgets
import qs.services

Item {
    id: root

    property bool selectorOpen
    readonly property alias layout: layout

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Appearance.dashboard.padding.normal
        spacing: Appearance.dashboard.spacing.normal

        RowLayout {
            id: header

            Layout.fillWidth: true
            Layout.bottomMargin: -Appearance.dashboard.spacing.normal
            z: 1
            spacing: Appearance.dashboard.spacing.normal

            MaterialIcon {
                text: "lyrics"
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.larger
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Lyrics")
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            LyricsInfo {}
        }

        CommonWidgets.Lyrics {
            Layout.fillWidth: true
            Layout.fillHeight: true

            textAlignment: Text.AlignHCenter
            textColor: Appearance.m3colors.m3onSurface
            activeColor: Appearance.m3colors.m3primary
            dimColor: Appearance.m3colors.m3onSurfaceVariant
            indicatorColor: Appearance.m3colors.m3primaryContainer
            indicatorShapeColor: Appearance.m3colors.m3onPrimaryContainer
        }

        // Player switcher, styled like a small pill "split button": tap to
        // expand the other active players above it, tap one to switch.
        Item {
            id: selector

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.dashboard.spacing.small

            implicitWidth: pill.implicitWidth
            implicitHeight: pill.implicitHeight

            MouseArea {
                anchors.fill: parent
                cursorShape: MprisController.players.length > 1 ? Qt.PointingHandCursor : undefined
                onClicked: if (MprisController.players.length > 1)
                root.selectorOpen = !root.selectorOpen
            }

            StyledRect {
                id: pill

                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                implicitWidth: Math.max(wrapper.implicitWidth, currentRow.implicitWidth) + Appearance.dashboard.padding.large * 2
                implicitHeight: wrapper.implicitHeight + Appearance.dashboard.padding.normal * 2

                color: Appearance.m3colors.m3primaryContainer
                radius: Appearance.rounding.full

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }

                Item {
                    id: wrapper

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.margins: Appearance.dashboard.padding.normal

                    clip: true
                    implicitWidth: Math.max(others.implicitWidth, currentRow.implicitWidth)
                    implicitHeight: root.selectorOpen && MprisController.players.length > 1 ? others.implicitHeight + currentRow.implicitHeight + Appearance.dashboard.spacing.small : currentRow.implicitHeight

                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: Appearance.dashboard.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        spacing: Appearance.dashboard.spacing.small

                        Column {
                            id: others

                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Appearance.dashboard.spacing.small

                            Repeater {
                                model: MprisController.players.filter(p => p !== MprisController.activePlayer)

                                Row {
                                    id: otherPlayer

                                    required property MprisPlayer modelData

                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Appearance.dashboard.spacing.small

                                    IconImage {
                                        id: otherIcon
                                        source: Quickshell.iconPath(AppSearch.guessIcon(otherPlayer.modelData?.identity ?? ""), "image-missing")
                                        implicitSize: Math.round(otherLabel.implicitHeight * 0.9)
                                    }

                                    StyledText {
                                        id: otherLabel
                                        text: otherLabelMetrics.elidedText
                                        color: Appearance.m3colors.m3secondary

                                        TextMetrics {
                                            id: otherLabelMetrics
                                            text: otherPlayer.modelData?.identity ?? ""
                                            font.family: otherLabel.font.family
                                            font.pointSize: otherLabel.font.pointSize
                                            elide: Text.ElideRight
                                            elideWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaTabWidth / 6
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (otherPlayer.modelData)
                                                    MprisController.setActivePlayer(otherPlayer.modelData);
                                                root.selectorOpen = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            id: currentRow

                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Appearance.dashboard.spacing.small

                            IconImage {
                                id: currentIcon
                                source: Quickshell.iconPath(AppSearch.guessIcon(MprisController.activePlayer?.identity ?? ""), "multimedia-player")
                                implicitSize: Math.round(currentLabel.implicitHeight * 0.9)
                            }

                            StyledText {
                                id: currentLabel

                                animate: true
                                text: currentLabelMetrics.elidedText
                                color: Appearance.m3colors.m3primary

                                TextMetrics {
                                    id: currentLabelMetrics
                                    text: MprisController.activePlayer?.identity ?? qsTr("No players")
                                    font.family: currentLabel.font.family
                                    font.pointSize: currentLabel.font.pointSize
                                    elide: Text.ElideRight
                                    elideWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaTabWidth / 6
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

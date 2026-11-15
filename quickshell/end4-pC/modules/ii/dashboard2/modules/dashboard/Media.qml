pragma ComponentBehavior: Bound

import "media"
import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import Quickshell
import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.modules.common
import qs.services

Item {
    id: root

    required property PersistentProperties visibilities

    Component.onCompleted: Cava.active = true
    Component.onDestruction: Cava.active = false

    implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaTabWidth
    implicitHeight: Config.options.caelestiaDashboard.dashboard.sizes.mediaTabHeight

    BackgroundShapes {
        anchors.fill: parent
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.dashboard.padding.large
        spacing: Appearance.dashboard.spacing.large

        CoverVisualiser {
            Layout.fillHeight: true
            implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaSectionWidth
        }

        Item {
            id: stateWrapper

            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool hasMedia: MprisController.activePlayer !== null

            // Ignore transient nulls from MPRIS metadata bursts (common
            // right when a track changes) - only actually switch to
            // "no media" if it stays null for a beat. This is what was
            // tearing down the Loaders below mid-build and crashing.
            onHasMediaChanged: {
                if (hasMedia) {
                    noMediaDebounce.stop();
                    stateWrapper.state = "";
                } else {
                    noMediaDebounce.restart();
                }
            }

            Timer {
                id: noMediaDebounce
                interval: 300
                onTriggered: stateWrapper.state = "noMedia"
            }

            states: State {
                name: "noMedia"

                PropertyChanges {
                    noMedia.opacity: 1
                    content.opacity: 0
                }
            }

            transitions: Transition {
                NumberAnimation {
                    properties: "opacity"
                    duration: Appearance.dashboard.durations.large
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }

            Loader {
                id: noMedia

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -Appearance.dashboard.padding.large * 2
                active: opacity > 0
                opacity: 0
                // synchronous (default) - no incubation window to race

                sourceComponent: ColumnLayout {
                    spacing: Appearance.dashboard.spacing.small

                    MaterialShape {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: (pathBounds().height - implicitSize) / 2
                        Layout.bottomMargin: (pathBounds().height - implicitSize) / 2 + Appearance.dashboard.spacing.small
                        implicitSize: icon.implicitHeight + Appearance.dashboard.padding.large * 2
                        shape: MaterialShape.ClamShell
                        color: Appearance.m3colors.m3primaryContainer

                        MaterialIcon {
                            id: icon
                            anchors.centerIn: parent
                            text: "queue_music"
                            color: Appearance.m3colors.m3secondary
                            font.pointSize: Appearance.dashboard.fontSize.extraLarge
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Nothing playing")
                        color: Appearance.m3colors.m3primary
                        font.pointSize: Appearance.dashboard.fontSize.large
                    }

                    StyledText {
                        text: qsTr("Play something for it to show up here!")
                        color: Appearance.m3colors.m3secondary
                    }
                }
            }

            Loader {
                id: content

                anchors.fill: parent
                active: opacity > 0
                // synchronous (default) - no incubation window to race

                sourceComponent: RowLayout {
                    spacing: Appearance.dashboard.spacing.large

                    Details {
                        Layout.fillWidth: true
                    }

                    LyricsAndSelector {
                        Layout.fillHeight: true
                        implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.mediaSectionWidth
                    }
                }
            }
        }
    }
}

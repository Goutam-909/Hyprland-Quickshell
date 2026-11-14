import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    implicitWidth: 400
    implicitHeight: 430

    // ── Tab state (0 = Browse, 1 = Library) ───────────────────────────────────
    property int tabIndex: 0

    // ── Navigation stacks (0 = list, 1 = detail) ──────────────────────────────
    property int browseStack:  0
    property int libraryStack: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Main content ──────────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.tabIndex

            // ── Browse tab ────────────────────────────────────────────────────
            Item {
                BrowseView {
                    anchors.fill: parent
                    visible: root.browseStack === 0
                    opacity: visible ? 1 : 0
                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
                    }
                    onAnimeSelected: function(show) {
                        Anime.fetchAnimeDetail(show)
                        root.browseStack = 1
                    }
                }

                DetailView {
                    anchors.fill: parent
                    visible: root.browseStack === 1
                    opacity: visible ? 1 : 0
                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
                    }
                    onBackRequested: {
                        root.browseStack = 0
                        Anime.clearDetail()
                    }
                }
            }

            // ── Library tab ───────────────────────────────────────────────────
            Item {
                LibraryView {
                    anchors.fill: parent
                    visible: root.libraryStack === 0
                    opacity: visible ? 1 : 0
                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
                    }
                    onAnimeSelected: function(show) {
                        Anime.fetchAnimeDetail(show)
                        root.libraryStack = 1
                    }
                }

                DetailView {
                    anchors.fill: parent
                    visible: root.libraryStack === 1
                    opacity: visible ? 1 : 0
                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic }
                    }
                    onBackRequested: {
                        root.libraryStack = 0
                        Anime.clearDetail()
                    }
                }
            }
        }

        // ── Bottom tab bar ────────────────────────────────────────────────────
        Separator {
            Layout.fillWidth: true
            height: 2
        }

        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: "transparent"

            // Sliding active-tab underline
            Rectangle {
                id: tabIndicator
                height: 2; radius: 1
                width: parent.width / 2
                color: Styling.srItem("primary")
                y: 0

                x: root.tabIndex === 0 ? 0 : parent.width / 2
                Behavior on x {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration / 1.5; easing.type: Easing.OutCubic }
                }
            }

            Row {
                anchors.fill: parent

                Repeater {
                    model: [
                        { label: "Browse",  icon: Icons.player },
                        { label: "Library", icon: Icons.heart  }
                    ]

                    delegate: Item {
                        width: root.width / 2
                        height: parent.height

                        readonly property bool active: root.tabIndex === index

                        Rectangle {
                            anchors.fill: parent
                            color: Styling.srItem("primary")
                            opacity: tabBtnArea.containsMouse && !active ? 0.05 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                font.family: Icons.font
                                font.pixelSize: 14
                                color: active ? Styling.srItem("primary") : Colors.overSurface
                                opacity: active ? 1 : 0.5
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                font.family: Config.theme.font
                                font.pixelSize: 11; font.letterSpacing: 0.5
                                color: active ? Styling.srItem("primary") : Colors.overSurface
                                opacity: active ? 1 : 0.5
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        MouseArea {
                            id: tabBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.tabIndex = index
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: libraryView

    signal animeSelected(var show)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 52
            color: "transparent"; z: 2

            Separator {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 2
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 14 }

                Row {
                    spacing: 0; Layout.fillWidth: true

                    Text {
                        text: "A"
                        font.family: Config.theme.font
                        font.pixelSize: 20; font.letterSpacing: 1
                        color: Styling.srItem("primary")
                    }
                    Text {
                        text: "nime Library"
                        font.family: Config.theme.font
                        font.pixelSize: 20; font.letterSpacing: 1
                        color: Colors.overBackground; opacity: 0.85
                    }
                }

                // Count badge
                Rectangle {
                    visible: Anime.libraryList.length > 0
                    height: 22; width: libCountText.implicitWidth + 14; radius: 11
                    color: "transparent"
                    border.color: Colors.outline; border.width: 1

                    Text {
                        id: libCountText; anchors.centerIn: parent
                        text: Anime.libraryList.length
                        font.family: Config.theme.font
                        font.pixelSize: 10; font.letterSpacing: 0.4
                        color: Colors.overSurface
                    }
                }
            }
        }

        // ── Loading state ─────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: !Anime.libraryLoaded

            Rectangle {
                width: 26; height: 26; radius: 13
                anchors.centerIn: parent
                color: "transparent"
                border.color: Styling.srItem("primary"); border.width: 2
                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 800
                    loops: Animation.Infinite; running: parent.visible
                    easing.type: Easing.Linear
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: Anime.libraryList.length === 0 && Anime.libraryLoaded

            Column {
                anchors.centerIn: parent; spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Icons.heart
                    font.family: Icons.font
                    font.pixelSize: 40
                    color: Colors.outline; opacity: 0.3
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Your library is empty"
                    font.family: Config.theme.font
                    font.pixelSize: 14; color: Colors.overBackground; opacity: 0.45
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Open any anime and tap  + Library"
                    font.family: Config.theme.font
                    font.pixelSize: 11; color: Colors.overSurface
                    opacity: 0.38; font.letterSpacing: 0.2
                }
            }
        }

        // ── Library grid ──────────────────────────────────────────────────────
        GridView {
            id: libGrid
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: Anime.libraryList.length > 0 && Anime.libraryLoaded
            topMargin: 8; leftMargin: 8; rightMargin: 8; bottomMargin: 8
            cellWidth:  Math.floor((width - leftMargin - rightMargin) / 4)
            cellHeight: cellWidth * 1.78
            clip: true; boundsBehavior: Flickable.StopAtBounds
            model: Anime.libraryList

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 3
                    color: Styling.srItem("primary")
                    opacity: 0.45; radius: 2
                }
            }

            delegate: Item {
                width: libGrid.cellWidth
                height: libGrid.cellHeight

                readonly property var entry: modelData

                StyledRect {
                    id: libCard
                    anchors { fill: parent; margins: 5 }
                    radius: Styling.radius(8)
                    variant: "common"
                    clip: true

                    // Cover
                    Image {
                        id: libCover
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: parent.height - libTitleBar.height - libEpBar.height
                        source: entry.thumbnail || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        Rectangle {
                            anchors.fill: parent; color: "transparent"
                            visible: libCover.status !== Image.Ready
                            Text {
                                anchors.centerIn: parent
                                text: Icons.image
                                font.family: Icons.font
                                font.pixelSize: 28; color: Colors.outline; opacity: 0.25
                            }
                        }

                        // Score badge
                        Rectangle {
                            visible: entry.score !== null && entry.score !== undefined
                            anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                            height: 18; radius: 9; width: libScoreText.implicitWidth + 10
                            color: Qt.rgba(0, 0, 0, 0.72)
                            Text {
                                id: libScoreText; anchors.centerIn: parent
                                text: entry.score ? "★ " + (entry.score).toFixed(1) : ""
                                font.family: Config.theme.font
                                font.pixelSize: 8; font.bold: true
                                color: "#f5c518"
                            }
                        }

                        // Bookmark heart
                        Rectangle {
                            visible: entry.bookmarked
                            anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
                            width: 20; height: 20; radius: 10
                            color: Qt.rgba(0, 0, 0, 0.65)
                            Text {
                                anchors.centerIn: parent; text: "♥"
                                font.pixelSize: 9; color: Styling.srItem("primary")
                            }
                        }

                        // Bottom gradient
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 40
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: libCard.color }
                            }
                        }
                    }

                    // Title bar
                    Rectangle {
                        id: libTitleBar
                        anchors { bottom: libEpBar.top; left: parent.left; right: parent.right }
                        height: libTitleText.implicitHeight + 10
                        color: libCard.color

                        Text {
                            id: libTitleText
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8; rightMargin: 8
                            }
                            text: entry.englishName || entry.name || ""
                            font.family: Config.theme.font
                            font.pixelSize: 10; font.letterSpacing: 0.2
                            color: Colors.overBackground
                            wrapMode: Text.Wrap; maximumLineCount: 2
                            elide: Text.ElideRight; lineHeight: 1.3
                        }
                    }

                    // Last-watched bar
                    Rectangle {
                        id: libEpBar
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 26; radius: libCard.radius

                        // Flatten top corners
                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.radius; color: parent.color
                        }

                        color: Qt.rgba(0, 0, 0, 0.25)

                        Row {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left; leftMargin: 8
                            }
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Icons.play
                                font.family: Icons.font
                                font.pixelSize: 7
                                color: entry.lastWatchedEpNum
                                    ? Styling.srItem("primary") : Colors.outline
                                opacity: entry.lastWatchedEpNum ? 1 : 0.4
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.lastWatchedEpNum
                                    ? "Ep. " + entry.lastWatchedEpNum
                                    : "Not started"
                                font.family: Config.theme.font
                                font.pixelSize: 9; font.letterSpacing: 0.3
                                color: entry.lastWatchedEpNum
                                    ? Colors.overBackground : Colors.overSurface
                                opacity: entry.lastWatchedEpNum ? 0.85 : 0.45
                            }
                        }
                    }

                    // Press / hover ripple
                    Rectangle {
                        anchors.fill: parent; radius: libCard.radius
                        color: Styling.srItem("primary")
                        opacity: libCardArea.pressed ? 0.16 : (libCardArea.containsMouse ? 0.06 : 0)
                        Behavior on opacity { NumberAnimation { duration: 130 } }
                    }

                    transform: Scale {
                        origin.x: libCard.width / 2; origin.y: libCard.height / 2
                        xScale: libCardArea.pressed ? 0.97 : 1.0
                        yScale: libCardArea.pressed ? 0.97 : 1.0
                        Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: libCardArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            libraryView.animeSelected({
                                id:               entry.id,
                                name:             entry.name,
                                englishName:      entry.englishName,
                                nativeName:       entry.nativeName       || "",
                                thumbnail:        entry.thumbnail,
                                score:            entry.score,
                                type:             entry.type             || "",
                                episodeCount:     entry.episodeCount     || "",
                                availableEpisodes: entry.availableEpisodes || { sub: 0, dub: 0, raw: 0 },
                                season:           entry.season           || null
                            })
                        }
                    }
                }
            }
        }
    }
}

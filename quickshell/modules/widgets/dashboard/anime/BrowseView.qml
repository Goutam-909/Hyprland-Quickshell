import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: browseView

    signal animeSelected(var show)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "transparent"
            z: 2

            Separator {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 2
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 8 }
                spacing: 8

                // Wordmark — hidden when search open
                Row {
                    spacing: 0
                    visible: !searchBar.visible
                    Layout.fillWidth: true

                    Text {
                        text: "A"
                        font.family: Config.theme.font
                        font.pixelSize: 20; font.letterSpacing: 1
                        color: Styling.srItem("primary")
                    }
                    Text {
                        text: "nime"
                        font.family: Config.theme.font
                        font.pixelSize: 20; font.letterSpacing: 1
                        color: Colors.overBackground; opacity: 0.85
                    }
                }

                // Search bar
                StyledRect {
                    id: searchBar
                    Layout.fillWidth: true
                    height: 32; radius: Styling.radius(8)
                    variant: "common"
                    visible: false

                    TextInput {
                        id: searchField
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left; right: clearBtn.left
                            leftMargin: 12; rightMargin: 6
                        }
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: 13
                        clip: true
                        onTextChanged: searchDebounce.restart()
                        Keys.onEscapePressed: {
                            searchBar.visible = false
                            text = ""
                            Anime.fetchPopular(true)
                        }
                    }

                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                        text: "Search anime…"
                        color: Colors.outline
                        font.family: Config.theme.font
                        font.pixelSize: 13
                        visible: searchField.text.length === 0
                    }

                    Item {
                        id: clearBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 8 }
                        width: 20; height: 20
                        visible: searchField.text.length > 0
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"; font.pixelSize: 9; font.bold: true
                            color: Colors.outline
                        }
                        MouseArea { anchors.fill: parent; onClicked: searchField.text = "" }
                    }
                }

                Timer {
                    id: searchDebounce
                    interval: 350
                    onTriggered: {
                        if (searchField.text.trim().length > 0)
                            Anime.searchAnime(searchField.text.trim(), true)
                        else
                            Anime.fetchPopular(true)
                    }
                }

                // Search toggle button
                Button {
                    flat: true
                    width: 34; height: 34

                    background: StyledRect {
                        variant: searchBar.visible ? "primary" : "focus"
                        radius: Styling.radius(8)
                        opacity: searchBar.visible ? 1 : (parent.hovered ? 1 : 0)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    contentItem: Text {
                        text: Icons.glassPlus
                        font.family: Icons.font
                        font.pixelSize: 16
                        color: searchBar.visible ? Styling.srItem("overprimary") : Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    onClicked: {
                        searchBar.visible = !searchBar.visible
                        if (searchBar.visible) searchField.forceActiveFocus()
                        else {
                            searchField.text = ""
                            Anime.fetchPopular(true)
                        }
                    }
                }

                // Sub / Dub toggle
                StyledRect {
                    height: 28
                    width: modeRow.implicitWidth + 8
                    radius: Styling.radius(8)
                    variant: "common"

                    Row {
                        id: modeRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: ["sub", "dub"]

                            delegate: Item {
                                readonly property bool active: Anime.currentMode === modelData
                                width: modeTxt.implicitWidth + 12
                                height: 24

                                StyledRect {
                                    anchors.fill: parent; anchors.margins: 2
                                    radius: Styling.radius(4)
                                    variant: "primary"
                                    opacity: active ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                Text {
                                    id: modeTxt
                                    anchors.centerIn: parent
                                    text: modelData.toUpperCase()
                                    font.family: Config.theme.font
                                    font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8
                                    color: active ? Styling.srItem("overprimary") : Colors.overSurface
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Anime.setMode(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Category row (Popular / Latest) ───────────────────────────────────
        Row {
            Layout.fillWidth: true
            height: 36
            spacing: 6
            leftPadding: 12

            Repeater {
                model: [
                    { label: "Popular", view: "popular" },
                    { label: "Latest",  view: "latest"  }
                ]

                delegate: Button {
                    readonly property bool active: Anime.currentView === modelData.view
                    height: 28
                    flat: true
                    topPadding: 0; bottomPadding: 0
                    leftPadding: 12; rightPadding: 12

                    background: StyledRect {
                        radius: Styling.radius(8)
                        variant: active ? "primary" : "focus"
                        opacity: active ? 1 : (parent.hovered ? 0.7 : 0)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    contentItem: Text {
                        text: modelData.label
                        font.family: Config.theme.font
                        font.pixelSize: 12; font.weight: Font.Medium
                        color: active ? Styling.srItem("overprimary") : Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    onClicked: {
                        if (modelData.view === "popular") Anime.fetchPopular(true)
                        else                             Anime.fetchLatest(true)
                    }
                }
            }
        }

        // ── Loading indicator ─────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            height: 3
            visible: Anime.isFetchingAnime

            Rectangle {
                id: loadBar
                height: parent.height
                radius: 2
                color: Styling.srItem("primary")
                opacity: 0.7

                SequentialAnimation on width {
                    loops: Animation.Infinite
                    running: Anime.isFetchingAnime
                    NumberAnimation { from: 0;               to: browseView.width * 0.6; duration: 800; easing.type: Easing.OutCubic }
                    NumberAnimation { from: browseView.width * 0.6; to: browseView.width;      duration: 400; easing.type: Easing.InCubic }
                    NumberAnimation { from: browseView.width;       to: 0;               duration: 1    }
                }
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: Anime.isFetchingAnime
                    NumberAnimation { from: 0;               to: 0;               duration: 800 }
                    NumberAnimation { from: 0;               to: browseView.width * 0.4; duration: 400; easing.type: Easing.InCubic }
                    NumberAnimation { from: browseView.width * 0.4; to: 0;               duration: 1    }
                }
            }
        }

        // ── Error banner ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: errText.implicitHeight + 12
            color: Qt.rgba(0.9, 0.2, 0.2, 0.15)
            visible: Anime.animeError.length > 0 && !Anime.isFetchingAnime
            radius: 0

            Text {
                id: errText
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
                text: Anime.animeError
                color: Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: 11; elide: Text.ElideRight
            }
        }

        // ── Empty / server not ready ──────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !Anime.isFetchingAnime && Anime.animeList.length === 0 && Anime.animeError.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Icons.player
                    font.family: Icons.font
                    font.pixelSize: 40
                    color: Colors.outline; opacity: 0.3
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Anime.serverReady ? "No results" : "Starting server…"
                    font.family: Config.theme.font
                    font.pixelSize: 13
                    color: Colors.outline; opacity: 0.5
                }
            }
        }

        // ── Anime grid ────────────────────────────────────────────────────────
        GridView {
            id: animeGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Anime.animeList.length > 0
            topMargin: 8; bottomMargin: 8
            leftMargin: 8; rightMargin: 8
            cellWidth:  Math.floor((width - leftMargin - rightMargin) / 4)
            cellHeight: cellWidth * 1.58
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Anime.animeList

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 3
                    color: Styling.srItem("primary")
                    opacity: 0.45; radius: 2
                }
            }

            onContentYChanged: {
                if (contentY + height > contentHeight - cellHeight * 2)
                    Anime.fetchNextPage()
            }

            delegate: Item {
                width: animeGrid.cellWidth
                height: animeGrid.cellHeight

                StyledRect {
                    id: card
                    anchors { fill: parent; margins: 5 }
                    radius: Styling.radius(8)
                    variant: "common"
                    clip: true

                    // Cover image
                    Image {
                        id: coverImg
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: parent.height - titleBar.height
                        source: modelData.thumbnail || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        // Placeholder
                        Rectangle {
                            anchors.fill: parent; color: "transparent"
                            visible: coverImg.status !== Image.Ready
                            Text {
                                anchors.centerIn: parent
                                text: Icons.image
                                font.family: Icons.font
                                font.pixelSize: 28
                                color: Colors.outline; opacity: 0.25
                            }
                        }

                        // Score badge
                        Rectangle {
                            visible: modelData.score !== null && modelData.score !== undefined
                            anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                            height: 18; radius: 9
                            width: scoreText.implicitWidth + 10
                            color: Qt.rgba(0, 0, 0, 0.72)

                            Text {
                                id: scoreText; anchors.centerIn: parent
                                text: modelData.score !== null ? "★ " + (modelData.score || 0).toFixed(1) : ""
                                font.family: Config.theme.font
                                font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.3
                                color: "#f5c518"
                            }
                        }

                        // Type badge
                        Rectangle {
                            visible: modelData.type && modelData.type.length > 0
                            anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
                            height: 18; radius: 9
                            width: typeText.implicitWidth + 10
                            color: Qt.rgba(0, 0, 0, 0.70)

                            Text {
                                id: typeText; anchors.centerIn: parent
                                text: (modelData.type || "").toUpperCase()
                                font.family: Config.theme.font
                                font.pixelSize: 7; font.letterSpacing: 0.8; font.bold: true
                                color: Styling.srItem("primary")
                            }
                        }

                        // Episode count badge
                        Rectangle {
                            visible: modelData.availableEpisodes
                                && (modelData.availableEpisodes.sub > 0 || modelData.availableEpisodes.dub > 0)
                            anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 6; rightMargin: 6 }
                            height: 18; radius: 9
                            width: epText.implicitWidth + 10
                            color: Qt.rgba(0, 0, 0, 0.72)

                            Text {
                                id: epText; anchors.centerIn: parent
                                text: {
                                    var avail = modelData.availableEpisodes
                                    var n = Anime.currentMode === "dub" ? avail.dub : avail.sub
                                    return n + " ep"
                                }
                                font.family: Config.theme.font
                                font.pixelSize: 8; font.letterSpacing: 0.3
                                color: "white"; opacity: 0.85
                            }
                        }

                        // Bottom gradient fade
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 40
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: card.color }
                            }
                        }
                    }

                    // Library dot
                    Rectangle {
                        visible: Anime.isInLibrary(modelData.id)
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 5 }
                        width: 6; height: 6; radius: 3
                        color: Styling.srItem("primary"); opacity: 0.9
                    }

                    // Title bar
                    Rectangle {
                        id: titleBar
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: titleText.implicitHeight + 14
                        color: card.color

                        Text {
                            id: titleText
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8; rightMargin: 8
                            }
                            text: modelData.englishName || modelData.name || ""
                            font.family: Config.theme.font
                            font.pixelSize: 10; font.letterSpacing: 0.2
                            color: Colors.overBackground
                            wrapMode: Text.Wrap; maximumLineCount: 2
                            elide: Text.ElideRight; lineHeight: 1.3
                        }
                    }

                    // Press / hover ripple
                    Rectangle {
                        anchors.fill: parent
                        radius: card.radius
                        color: Styling.srItem("primary")
                        opacity: cardArea.pressed ? 0.16 : (cardArea.containsMouse ? 0.06 : 0)
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    transform: Scale {
                        origin.x: card.width / 2; origin.y: card.height / 2
                        xScale: cardArea.pressed ? 0.97 : 1.0
                        yScale: cardArea.pressed ? 0.97 : 1.0
                        Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: browseView.animeSelected(modelData)
                    }
                }
            }
        }
    }
}

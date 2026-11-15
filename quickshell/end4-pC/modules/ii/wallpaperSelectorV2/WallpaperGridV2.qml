import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell

// Grid style ported from the source: a fixed-size page of 240x159 tile
// cards (not an infinite scroll) with Anim's exact "bloom" spring -
// fromScale 0.4, fromY 14, duration 400 OutBack(2.2), fadeDuration 180,
// 35ms/slot stagger - reproduced as plain QML animations against
// `walls`/`currentIndex`, which come from the existing Wallpapers service.
// No video/gif tiles, per request.
Item {
    id: root

    property var walls: []
    property int currentIndex: 0

    signal wallpaperPreviewed(string path)
    signal wallpaperActivated(string path)

    readonly property int tileW: 240
    readonly property int thumbH: 135
    readonly property int tileH: 159
    readonly property int colSpacing: 24
    readonly property int rowSpacing: 24

    readonly property int cols: Math.max(1, Math.floor((width + colSpacing) / (tileW + colSpacing)))
    readonly property int rows: Math.max(1, Math.floor((height + rowSpacing) / (tileH + rowSpacing)))
    readonly property int pageSize: cols * rows
    readonly property int columns: cols

    property int page: currentIndex >= 0 && pageSize > 0 ? Math.floor(currentIndex / pageSize) : 0
    readonly property int pageCount: pageSize > 0 ? Math.max(1, Math.ceil(walls.length / pageSize)) : 1

    // Anim.qml, "bloom" (the default style)
    readonly property real animFromScale: 0.4
    readonly property int animFromY: 14
    readonly property int animDuration: 400
    readonly property int animFadeDuration: 180
    readonly property int animStagger: 35
    readonly property int animOutDuration: 320

    function moveSelection(delta) {
        if (root.walls.length === 0) return;
        root.currentIndex = Math.max(0, Math.min(root.walls.length - 1, root.currentIndex + delta));
        const w = root.walls[root.currentIndex];
        if (w) root.wallpaperPreviewed(w.filePath);
    }

    function activateCurrent() {
        const w = root.walls[root.currentIndex];
        if (w) root.wallpaperActivated(w.filePath);
    }

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: root.cols
        rowSpacing: root.rowSpacing
        columnSpacing: root.colSpacing

        Repeater {
            id: repeater
            model: root.pageSize

            Item {
                id: cell
                required property int index
                readonly property int wallIndex: root.page * root.pageSize + index
                readonly property var wall: wallIndex < root.walls.length ? root.walls[wallIndex] : null
                readonly property bool isSelected: wallIndex === root.currentIndex

                width: root.tileW
                height: root.tileH
                visible: wall !== null

                scale: root.animFromScale
                opacity: 0
                transform: Translate { id: entranceTranslate; y: root.animFromY }

                function springIn() {
                    entranceSeq.stop();
                    entranceSeq.start();
                }
                function springOut() {
                    entranceSeq.stop();
                    exitAnim.start();
                }

                SequentialAnimation {
                    id: entranceSeq
                    PauseAnimation { duration: cell.index * root.animStagger }
                    ParallelAnimation {
                        NumberAnimation { target: cell; property: "opacity"; to: 1; duration: root.animFadeDuration; easing.type: Easing.OutCubic }
                        NumberAnimation { target: cell; property: "scale"; to: 1; duration: root.animDuration; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                        NumberAnimation { target: entranceTranslate; property: "y"; to: 0; duration: root.animDuration; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                    }
                }
                ParallelAnimation {
                    id: exitAnim
                    NumberAnimation { target: cell; property: "opacity"; to: 0; duration: root.animOutDuration; easing.type: Easing.InQuad }
                    NumberAnimation { target: cell; property: "scale"; to: root.animFromScale; duration: root.animOutDuration; easing.type: Easing.InQuad }
                    NumberAnimation { target: entranceTranslate; property: "y"; to: root.animFromY; duration: root.animOutDuration; easing.type: Easing.InQuad }
                }

                Component.onCompleted: if (wall) springIn()
                onWallChanged: if (wall) springIn()

                // selection ring, framing the thumbnail with a fixed margin
                Rectangle {
                    visible: cell.isSelected
                    anchors.fill: thumb
                    anchors.margins: -5
                    radius: 19
                    color: "transparent"
                    border.width: 3
                    border.color: Qt.alpha(Appearance.colors.colPrimary, 0.33)
                }

                Rectangle {
                    id: thumb
                    width: root.tileW
                    height: root.thumbH
                    radius: 14
                    clip: true
                    color: Qt.alpha(Appearance.colors.colPrimary, cell.isSelected ? 0.22 : 0.11)

                    Loader {
                        anchors.fill: parent
                        active: cell.wall && Images.isValidImageByName(cell.wall.fileName)
                        sourceComponent: ThumbnailImage {
                            generateThumbnail: false
                            sourcePath: cell.wall ? cell.wall.filePath : ""
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                            sourceSize.width: root.tileW
                            sourceSize.height: root.thumbH
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: cell.wall !== null
                        onClicked: {
                            if (cell.isSelected)
                                root.wallpaperActivated(cell.wall.filePath);
                            else {
                                root.currentIndex = cell.wallIndex;
                                root.wallpaperPreviewed(cell.wall.filePath);
                            }
                        }
                        onDoubleClicked: root.wallpaperActivated(cell.wall.filePath)
                    }
                }

                // stroke drawn above the image, not a `border` on `thumb`
                // itself, so the clip mask doesn't eat the edge pixel
                Rectangle {
                    anchors.fill: thumb
                    radius: 14
                    color: "transparent"
                    border.width: 1
                    border.color: cell.isSelected ? Appearance.colors.colPrimary : Qt.alpha(Appearance.colors.colPrimary, 0.33)
                }

                StyledText {
                    anchors.top: thumb.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, root.tileW - 8)
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    text: cell.wall ? cell.wall.fileName : ""
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
        }
    }

    // page dots, mirroring the source's own page indicator convention
    Row {
        visible: root.pageCount > 1
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
        }
        spacing: 8
        Repeater {
            model: root.pageCount
            Rectangle {
                required property int index
                width: 6; height: 6; radius: 3
                color: index === root.page ? Appearance.colors.colPrimary : Qt.alpha(Appearance.colors.colOnLayer0, 0.3)
            }
        }
    }
}

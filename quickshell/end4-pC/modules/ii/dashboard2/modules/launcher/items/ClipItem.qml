import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.ii.dashboard2.widgets
import qs.modules.common
import qs.modules.common.functions
// Cliphist is the root-level clipboard-history singleton (services/Cliphist.qml).
import qs.services

Item {
    id: root

    required property string modelData
    required property PersistentProperties visibilities
    // Passed down explicitly by ClipboardList's delegate binding (see
    // AppItem.qml for why this is a plain compile-time-bound property
    // instead of something derived from `parent`/`ListView.view`).
    required property real rowWidth
    // Row heights for the two entry kinds - see ClipboardList.qml.
    required property real itemHeight
    required property real imageItemHeight

    readonly property bool isImage: Cliphist.entryIsImage(modelData)
    readonly property string previewText: modelData.replace(/^\s*\S+\s+/, "")
    // cliphist entries are "<id>\t<preview>" - the id is stable for the
    // lifetime of the db and doubles as a cheap on-disk cache key so we
    // only ever decode a given image once.
    readonly property string entryId: modelData.split("\t")[0]
    readonly property string dimensionsLabel: {
        const m = modelData.match(/(\d+x\d+)/);
        return m ? m[1] : qsTr("Image");
    }

    property string imagePath: ""

    implicitHeight: isImage ? imageItemHeight : itemHeight
    width: rowWidth

    // Left click: copy to clipboard and paste it (Cliphist.paste already
    // handles both the classic-cliphist and stash binary cases).
    StateLayer {
        radius: Appearance.rounding.large

        function onClicked(): void {
            Cliphist.paste(root.modelData);
            root.visibilities.launcher = false;
            root.visibilities.clipboard = false;
        }
    }

    // Right click: delete this entry from history. Separate MouseArea
    // stacked above the StateLayer's own (left-button-only) MouseArea -
    // since it only claims the right button, left clicks fall through to
    // StateLayer underneath untouched.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: Cliphist.deleteEntry(root.modelData)
    }

    // Decodes this entry to a cached PNG on disk so it can be shown as a
    // real thumbnail. Only ever runs for image entries, and only once
    // per entryId (subsequent opens just hit the cache file).
    Process {
        id: decodeProc

        readonly property string cacheDir: "~/.cache/quickshell/clipimg"
        readonly property string outPath: `${cacheDir}/${root.entryId}.png`
        readonly property string decodeCmd: Cliphist.cliphistBinary.includes("cliphist") ? `printf '${StringUtils.shellSingleQuoteEscape(root.modelData)}' | ${Cliphist.cliphistBinary} decode` : `${Cliphist.cliphistBinary} decode ${root.entryId}`

        command: ["bash", "-c", `mkdir -p ${cacheDir}; test -s ${outPath} || (${decodeCmd} > ${outPath}); echo ${outPath}`]

        stdout: SplitParser {
            onRead: data => root.imagePath = data
        }
    }

    Component.onCompleted: {
        if (root.isImage)
            decodeProc.running = true;
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.dashboard.padding.normal
        anchors.rightMargin: Appearance.dashboard.padding.normal
        anchors.topMargin: Appearance.dashboard.padding.small
        anchors.bottomMargin: Appearance.dashboard.padding.small

        // Thumbnail - only present for image entries. Deliberately not
        // clipped: fillMode is PreserveAspectFit (not Crop) and there's
        // no ClippingRectangle/radius mask, so the whole image is shown
        // letterboxed instead of having its corners cropped off.
        Item {
            id: thumb

            visible: root.isImage
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: parent.height * 1.6
            implicitHeight: parent.height

            StyledRect {
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainerHigh
            }

            Image {
                anchors.fill: parent
                source: root.imagePath ? `file://${root.imagePath}` : ""
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                sourceSize.width: width
                sourceSize.height: height
            }

            // Only visible while the decode is still in flight.
            MaterialIcon {
                anchors.centerIn: parent
                visible: !root.imagePath
                text: "hourglass_empty"
                color: Appearance.m3colors.m3onSurfaceVariant
                font.pointSize: Appearance.dashboard.fontSize.normal
            }
        }

        StyledText {
            anchors.left: root.isImage ? thumb.right : parent.left
            anchors.leftMargin: root.isImage ? Appearance.dashboard.spacing.normal : 0
            anchors.right: parent.right
            anchors.top: root.isImage ? thumb.top : undefined
            anchors.verticalCenter: root.isImage ? undefined : parent.verticalCenter

            text: root.isImage ? root.dimensionsLabel : root.previewText
            color: Appearance.m3colors.m3onSurface
            font.pointSize: Appearance.dashboard.fontSize.normal
            elide: Text.ElideRight
        }
    }
}

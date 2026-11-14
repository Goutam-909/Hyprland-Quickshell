import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.theme

// Pick screens (empty = all). Replaces the old ScreenListRow.
MacRow {
    id: root

    property var selectedScreens: []
    signal screensChanged(var newList)

    label: "Screens"
    description: "Empty = all screens"

    Row {
        spacing: 6
        Repeater {
            model: Quickshell.screens
            delegate: MacTabButton {
                required property var modelData
                readonly property string screenName: modelData.name
                label: screenName
                isSelected: {
                    const list = root.selectedScreens;
                    return list && list.length > 0 && list.includes(screenName);
                }
                onClicked: {
                    let currentList = root.selectedScreens ? [...root.selectedScreens] : [];
                    const idx = currentList.indexOf(screenName);
                    if (idx >= 0)
                        currentList.splice(idx, 1);
                    else
                        currentList.push(screenName);
                    root.screensChanged(currentList);
                }
            }
        }
    }
}

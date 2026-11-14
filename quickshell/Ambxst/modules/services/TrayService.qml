pragma Singleton

import qs.modules.theme
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.config

Singleton {
    id: root

    // Safe fallback: filter passive items by default (no Config.options.tray needed)
    property bool smartTray: Config.bar?.tray?.filterPassive ?? false
    property list<var> itemsInUserList: SystemTray.items.values.filter(
        i => (pinnedItemIds.includes(i.id) && (!smartTray || i.status !== SystemTrayStatus.Passive))
    )
    property list<var> itemsNotInUserList: SystemTray.items.values.filter(
        i => (!pinnedItemIds.includes(i.id) && (!smartTray || i.status !== SystemTrayStatus.Passive))
    )

    // Internal persisted pin list — stored in Config if available, else in-memory
    property list<string> pinnedItemIds: Config.bar?.tray?.pinnedItems ?? []

    property bool invertPins: Config.bar?.tray?.invertPinnedItems ?? false
    property list<var> pinnedItems: invertPins ? itemsNotInUserList : itemsInUserList
    property list<var> unpinnedItems: invertPins ? itemsInUserList : itemsNotInUserList

    function getTooltipForItem(item) {
        var result = item.tooltipTitle.length > 0 ? item.tooltipTitle
            : (item.title.length > 0 ? item.title : item.id);
        if (item.tooltipDescription.length > 0)
            result += " • " + item.tooltipDescription;
        return result;
    }

    function pin(itemId) {
        if (pinnedItemIds.includes(itemId)) return;
        var pins = pinnedItemIds;
        pins.push(itemId);
        pinnedItemIds = pins;
    }

    function unpin(itemId) {
        pinnedItemIds = pinnedItemIds.filter(id => id !== itemId);
    }

    function isPinned(itemId) {
        for (var i = 0; i < root.pinnedItems.length; i++) {
            if (root.pinnedItems[i].id === itemId)
                return true;
        }
        return false;
    }

    function togglePin(itemId) {
        if (pinnedItemIds.includes(itemId))
            unpin(itemId);
        else
            pin(itemId);
    }
}

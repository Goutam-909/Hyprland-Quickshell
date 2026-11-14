import QtQuick
import qs.modules.theme

// A row that navigates somewhere (label … >). Used for sub-section menus.
// `text` is an alias of `label` so it can replace the old SectionButton API.
MacRow {
    id: root

    property string text: ""
    label: text
    hoverable: true
    chevron: true
}

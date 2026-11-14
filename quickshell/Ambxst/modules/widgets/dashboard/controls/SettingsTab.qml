pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config
import "SettingsCrawler.js" as SettingsCrawler

// macOS "System Settings" shell: floating sidebar (traffic lights, search,
// profile, coloured icon tiles) + toolbar (back/forward history, title) + page.
Item {
    id: root
    implicitWidth: 900
    implicitHeight: 650

    // 0: Network, 1: Bluetooth, 2: Mixer, 3: Effects, 4: Theme, 5: Binds,
    // 6: System, 7: Compositor, 8: Ambxst, 9: GNOME Settings
    property int currentSection: 0
    property int selectedIndex: 0
    property string searchQuery: ""
    // search is hidden until you press the magnifier next to your name
    property bool searchOpen: false

    function setSearchOpen(open) {
        searchOpen = open;
        if (open) {
            Qt.callLater(() => searchInput.focusInput());
        } else {
            searchInput.clear();
            root.forceActiveFocus();
        }
    }

    // User page (section 11) is opened from the profile row, not from the list
    function openUser() {
        selectedIndex = -1;
        currentSection = 11;
    }

    signal closeRequested
    signal zoomRequested

    // The sidebar uses your ORIGINAL theme variants again (same as the old config):
    //   box        -> StyledRect "common"
    //   highlight  -> soft primary tint (22%), slides between rows
    //   active     -> Styling.srItem("overprimary"), inactive -> Styling.srItem("common")
    // so it follows Config.theme (srCommon / srFocus / srOverPrimary) exactly like before.

    onFilteredSectionsChanged: selectedIndex = 0

    Timer {
        id: focusRestoreTimer
        interval: 50
        onTriggered: {
            if (root.searchOpen)
                searchInput.focusInput();
        }
    }

    onSelectedIndexChanged: {
        if (filteredSections && selectedIndex >= 0 && selectedIndex < filteredSections.length) {
            const item = filteredSections[selectedIndex];
            root.currentSection = item.section;
            root.dispatchSubSection(item.section, item.subSection);
            root.scrollSidebarToSelection();
            focusRestoreTimer.restart();
        }
    }

    // Focus the search input (called from parent)
    function focusSearchInput() {
        // never grab the keyboard on its own; only when the search is open
        if (root.searchOpen)
            searchInput.focusInput();
    }

    // Toolbar title mirrors the selected section (PanelTitlebar uses it)
    readonly property string currentLabel: {
        if (currentSection === 11)
            return "User";
        for (let i = 0; i < sectionModel.length; i++) {
            if (sectionModel[i].section === currentSection)
                return sectionModel[i].label;
        }
        return "";
    }
    Binding {
        target: MacStyle
        property: "pageTitle"
        value: root.currentLabel
    }

    // ── Back / forward history (like System Settings' toolbar) ──────────────
    property var navHistory: [0]
    property int navPos: 0
    property bool navBusy: false
    readonly property bool canGoBack: navPos > 0
    readonly property bool canGoForward: navPos < navHistory.length - 1

    onCurrentSectionChanged: {
        if (navBusy || navHistory[navPos] === currentSection)
            return;
        navHistory = navHistory.slice(0, navPos + 1).concat([currentSection]);
        navPos = navHistory.length - 1;
    }

    function goToSection(sec) {
        if (searchQuery.length > 0)
            searchInput.clear();
        const idx = getFilteredIndex(sec);
        if (idx >= 0)
            selectedIndex = idx;
    }
    function navBack() {
        if (!canGoBack)
            return;
        navBusy = true;
        navPos--;
        goToSection(navHistory[navPos]);
        navBusy = false;
    }
    function navForward() {
        if (!canGoForward)
            return;
        navBusy = true;
        navPos++;
        goToSection(navHistory[navPos]);
        navBusy = false;
    }

    // Maps your Colors theme onto the macOS palette
    MacThemeBridge {}

    SettingsIndex {
        id: searchIndex
    }

    // Dynamic Settings Indexer
    Item {
        id: settingsIndexer
        visible: false // Headless

        property int currentPanelIndex: 0
        property var aggregatedItems: []
        property bool isIndexing: false

        // Helper to load panels one by one
        Loader {
            id: indexerLoader
            active: settingsIndexer.isIndexing
            // Synchronous creation avoids back-to-back async incubation races
            // that could crash Quickshell.
            asynchronous: false
            source: settingsIndexer.isIndexing && settingsIndexer.currentPanelIndex < contentArea.panelComponents.length ? contentArea.panelComponents[settingsIndexer.currentPanelIndex].component : ""

            onStatusChanged: {
                if (status === Loader.Ready && item) {
                    // Scrape
                    const sectionId = contentArea.panelComponents[settingsIndexer.currentPanelIndex].section;
                    const newItems = SettingsCrawler.crawl(item, sectionId);
                    settingsIndexer.aggregatedItems = settingsIndexer.aggregatedItems.concat(newItems);

                    // Advance after a short delay so the current item is fully
                    // torn down before the next panel starts loading.
                    indexAdvanceTimer.restart();
                } else if (status === Loader.Error) {
                    console.warn("Failed to load panel for indexing:", source);
                    indexAdvanceTimer.restart();
                }
            }
        }

        // Debounces advancing to the next panel (see indexerLoader above).
        Timer {
            id: indexAdvanceTimer
            interval: 50
            onTriggered: settingsIndexer.currentPanelIndex++
        }

        onCurrentPanelIndexChanged: {
            if (currentPanelIndex >= contentArea.panelComponents.length) {
                // Done
                if (isIndexing) {
                    isIndexing = false;
                    searchIndex.addDynamicItems(aggregatedItems);
                }
            }
        }

        Component.onCompleted: {
            // Start indexing after a short delay to allow UI to settle
            indexingTimer.start();
        }

        Timer {
            id: indexingTimer
            interval: 500
            onTriggered: {
                settingsIndexer.isIndexing = true;
            }
        }
    }

    // Store pending subsection to apply when panel loads
    property string pendingSubSection: ""

    function dispatchSubSection(sectionId, subSectionId) {
        if (!subSectionId || subSectionId === "")
            return;
        // Panels that support subsections: Theme(4), System(6), Compositor(7), Shell(8)
        if ([4, 6, 7, 8].includes(sectionId)) {
            if (panelLoader.item && panelLoader.status === Loader.Ready) {
                panelLoader.item.currentSection = subSectionId;
            } else {
                pendingSubSection = subSectionId;
            }
        }
    }

    function scrollSidebarToSelection() {
        if (sidebarList && sidebarList.count > 0 && selectedIndex >= 0)
            sidebarList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    // Fuzzy match: checks if all characters of query appear in order in target
    function fuzzyMatch(query, target) {
        if (query.length === 0)
            return true;
        if (target.length === 0)
            return false;
        const lowerQuery = query.toLowerCase();
        const lowerTarget = target.toLowerCase();
        let queryIndex = 0;
        for (let i = 0; i < lowerTarget.length && queryIndex < lowerQuery.length; i++) {
            if (lowerTarget[i] === lowerQuery[queryIndex]) {
                queryIndex++;
            }
        }
        return queryIndex === lowerQuery.length;
    }

    // Score a fuzzy match (higher is better)
    function fuzzyScore(query, target) {
        if (query.length === 0)
            return 0;
        if (target.length === 0)
            return -1;
        const lowerQuery = query.toLowerCase();
        const lowerTarget = target.toLowerCase();

        // Exact match gets highest score
        if (lowerTarget.includes(lowerQuery))
            return 1000 + (100 - target.length);

        // Fuzzy scoring
        let queryIndex = 0, score = 0, consecutive = 0, maxConsecutive = 0;
        for (let i = 0; i < lowerTarget.length && queryIndex < lowerQuery.length; i++) {
            if (lowerTarget[i] === lowerQuery[queryIndex]) {
                queryIndex++;
                consecutive++;
                maxConsecutive = Math.max(maxConsecutive, consecutive);
                if (i === 0 || " -_".includes(lowerTarget[i - 1]))
                    score += 10;
            } else {
                consecutive = 0;
            }
        }
        return queryIndex === lowerQuery.length ? score + maxConsecutive * 5 : -1;
    }

    // Sidebar entries. `group` draws the gaps between blocks, `tile` is the
    // coloured square behind the icon (macOS style).
    readonly property var sectionModel: [
        {
            icon: Icons.wifiHigh,
            label: "Network",
            section: 0,
            isIcon: true,
            group: 1,
            tile: MacStyle.tileBlue
        },
        {
            icon: Icons.bluetooth,
            label: "Bluetooth",
            section: 1,
            isIcon: true,
            group: 1,
            tile: MacStyle.tileBlue
        },
        {
            icon: Icons.speakerHigh,
            label: "Mixer",
            section: 2,
            isIcon: true,
            group: 2,
            tile: MacStyle.tilePink
        },
        {
            icon: Icons.waveform,
            label: "Effects",
            section: 3,
            isIcon: true,
            group: 2,
            tile: MacStyle.tilePurple
        },
        {
            icon: Icons.circleHalf,
            label: "Theme",
            section: 4,
            isIcon: true,
            group: 3,
            tile: MacStyle.tileBlack
        },
        {
            icon: Icons.keyboard,
            label: "Binds",
            section: 5,
            isIcon: true,
            group: 3,
            tile: MacStyle.tileGray
        },
        {
            icon: Icons.faders,
            label: "Interface",
            section: 10,
            isIcon: true,
            group: 3,
            tile: MacStyle.tileLightBlue
        },
        {
            icon: Icons.circuitry,
            label: "System",
            section: 6,
            isIcon: true,
            group: 4,
            tile: MacStyle.tileGraphite
        },
        {
            icon: Icons.compositor,
            label: "Compositor",
            section: 7,
            isIcon: true,
            group: 4,
            tile: MacStyle.tileIndigo
        },
        {
            icon: Qt.resolvedUrl("../../../../assets/ambxst/ambxst-icon.svg"),
            label: "Ambxst",
            section: 8,
            isIcon: false,
            group: 4,
            tile: MacStyle.tileOrange
        },
        {
            icon: Icons.gear,
            label: "GNOME Settings",
            section: 9,
            isIcon: true,
            group: 4,
            tile: MacStyle.tileTeal
        }
    ]

    // Filtered sections based on search query
    readonly property var filteredSections: {
        if (searchQuery.length === 0)
            return sectionModel;

        const query = searchQuery.toLowerCase();
        return searchIndex.items.filter(item => {
            return fuzzyMatch(query, item.label) || (item.keywords && item.keywords.includes(query));
        }).map(item => {
            const sectionMeta = sectionModel.find(s => s.section === item.section) || {};
            return {
                label: item.label,
                section: item.section,
                subSection: item.subSection || "",
                subLabel: item.subLabel || "",
                icon: sectionMeta.icon || item.icon,
                isIcon: sectionMeta.isIcon !== undefined ? sectionMeta.isIcon : (item.isIcon !== undefined ? item.isIcon : true),
                group: 0,
                tile: sectionMeta.tile || MacStyle.tileGray,
                score: fuzzyScore(query, item.label)
            };
        }).sort((a, b) => b.score - a.score);
    }

    function getFilteredIndex(sectionId) {
        for (let i = 0; i < filteredSections.length; i++) {
            if (filteredSections[i].section === sectionId)
                return i;
        }
        return -1;
    }

    Process {
        id: hostnameProcess
        command: ["hostname"]
        running: true
        stdout: StdioCollector {
            id: hostnameCollector
            waitForEnd: true
        }
    }

    // ════════════════════════════════════════════════════════════════════
    //  WINDOW SURFACE
    // ════════════════════════════════════════════════════════════════════
    ClippingRectangle {
        id: surface
        anchors.fill: parent
        radius: 0
        color: "transparent"   // the window's own "bg" StyledRect shows through

        // ── Sidebar (floating, inset) ────────────────────────────────────
        StyledRect {
            id: sidebarPanel
            variant: "common"
            x: MacStyle.sidebarInset
            y: MacStyle.sidebarInset
            width: MacStyle.sidebarWidth - MacStyle.sidebarInset
            height: parent.height - MacStyle.sidebarInset * 2
            radius: MacStyle.sidebarRadius

            MacTrafficLights {
                id: lights
                visible: MacStyle.trafficLights
                x: 20
                y: 19
                onCloseClicked: root.closeRequested()
                onZoomClicked: root.zoomRequested()
            }

            MacSearchField {
                id: searchInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.top: profile.bottom
                anchors.topMargin: root.searchOpen ? 10 : 0
                height: root.searchOpen ? 38 : 0
                visible: height > 0
                opacity: root.searchOpen ? 1 : 0
                // no clip: the focus ring is drawn 3px outside the field and was being cut off
                Behavior on height {
                    NumberAnimation {
                        duration: MacStyle.fast
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: MacStyle.fast
                    }
                }
                placeholderText: "Search"
                clearOnEscape: true

                onSearchTextChanged: text => {
                    root.searchQuery = text;
                }
                onEscapePressed: root.setSearchOpen(false)
                onAccepted: {
                    if (root.filteredSections.length > 0) {
                        const item = root.filteredSections[root.selectedIndex];
                        root.currentSection = item.section;
                        root.dispatchSubSection(item.section, item.subSection);
                    }
                }
                onDownPressed: {
                    if (root.selectedIndex < root.filteredSections.length - 1)
                        root.selectedIndex++;
                    else
                        root.selectedIndex = 0;
                }
                onUpPressed: {
                    if (root.selectedIndex > 0)
                        root.selectedIndex--;
                    else
                        root.selectedIndex = root.filteredSections.length - 1;
                }
            }

            // Profile row
            Item {
                id: profile
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.top: parent.top
                anchors.topMargin: MacStyle.trafficLights ? 42 : 14
                height: 64

                // soft highlight while the User page is open (same tint as the sidebar selection)
                Rectangle {
                    anchors.fill: parent
                    radius: Styling.radius(-6)
                    color: root.currentSection === 11 ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22) : (userArea.containsMouse ? MacStyle.sidebarHover : "transparent")
                    Behavior on color {
                        ColorAnimation {
                            duration: MacStyle.fast / 2
                        }
                    }
                }

                MouseArea {
                    id: userArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openUser()
                }

                ClippingRectangle {
                    id: avatar
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46
                    height: 46
                    radius: 23
                    color: MacStyle.tileGray

                    Text {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                        font.family: MacStyle.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        color: "#FFFFFF"
                    }
                    Image {
                        id: face
                        anchors.fill: parent
                        source: `file://${Quickshell.env("HOME")}/.face`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Column {
                    anchors.left: avatar.right
                    anchors.leftMargin: 12
                    anchors.right: searchBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        width: parent.width
                        text: Quickshell.env("USER") || "User"
                        elide: Text.ElideRight
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsBody + 2
                        font.weight: Font.Medium
                        color: MacStyle.label
                    }
                    Text {
                        width: parent.width
                        text: hostnameCollector.text.trim() !== "" ? hostnameCollector.text.trim() : "Ambxst"
                        elide: Text.ElideRight
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsSmall
                        color: MacStyle.labelSecondary
                    }
                }

                // search toggle (right of the name)
                Item {
                    id: searchBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: root.searchOpen ? MacStyle.controlPress : (searchBtnArea.containsMouse ? MacStyle.controlHover : MacStyle.control)
                        Behavior on color {
                            ColorAnimation {
                                duration: MacStyle.fast / 2
                            }
                        }
                    }

                    // magnifier drawn from primitives
                    Item {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        Rectangle {
                            width: 12.5
                            height: 12.5
                            radius: width / 2
                            color: "transparent"
                            border.width: 1.6
                            border.color: root.searchOpen ? MacStyle.accent : MacStyle.label
                        }
                        Rectangle {
                            x: 9.6
                            y: 12
                            width: 6.5
                            height: 1.7
                            radius: 1
                            rotation: 45
                            transformOrigin: Item.Left
                            color: root.searchOpen ? MacStyle.accent : MacStyle.label
                        }
                    }

                    MouseArea {
                        id: searchBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setSearchOpen(!root.searchOpen)
                    }
                }
            }

            ListView {
                id: sidebarList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: searchInput.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: 10
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.bottomMargin: 10
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: root.filteredSections
                currentIndex: root.selectedIndex

                // Original sliding "focus" highlight behind the selected row
                highlightFollowsCurrentItem: true
                highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                highlightMoveVelocity: -1
                highlightResizeDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                highlightResizeVelocity: -1
                highlight: Rectangle {
                    radius: Styling.radius(-6)
                    // subtle primary tint (change 0.22 -> 0.15 quieter / 0.30 stronger)
                    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
                }

                section.property: "group"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    required property string section
                    width: ListView.view.width
                    height: ListView.view.model && ListView.view.model.length > 0 && String(ListView.view.model[0].group) === section ? 0 : 14
                }

                delegate: Item {
                    id: entry
                    required property var modelData
                    required property int index

                    readonly property bool isActive: index === root.selectedIndex
                    readonly property bool searching: root.searchQuery.length > 0
                    readonly property bool twoLine: searching && !!modelData.subLabel

                    width: ListView.view.width
                    height: twoLine ? 54 : 42

                    // hover only; the selected row is drawn by the sliding highlight
                    Rectangle {
                        anchors.fill: parent
                        radius: Styling.radius(-6)
                        color: (!entry.isActive && entryArea.containsMouse) ? MacStyle.sidebarHover : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: MacStyle.fast / 2
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        spacing: 11

                        MacIconTile {
                            size: 29
                            glyph: entry.modelData.isIcon ? entry.modelData.icon : ""
                            source: entry.modelData.isIcon ? "" : entry.modelData.icon
                            tint: entry.modelData.tile
                            sidebar: true
                            // original icon colours (primary when selected) unless you use the multicolour tiles
                            glyphColor: MacStyle.sidebarIconStyle === "color" ? "transparent" : (entry.isActive ? Styling.srItem("overprimary") : Styling.srItem("common"))
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                width: parent.width
                                text: entry.modelData.label
                                elide: Text.ElideRight
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fsBody
                                font.weight: entry.isActive ? Font.Bold : Font.Normal
                                color: entry.isActive ? Styling.srItem("overprimary") : Styling.srItem("common")
                                Behavior on color {
                                    enabled: Config.animDuration > 0
                                    ColorAnimation {
                                        duration: Config.animDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            Text {
                                width: parent.width
                                visible: entry.twoLine
                                text: entry.modelData.subLabel || ""
                                elide: Text.ElideRight
                                font.family: MacStyle.fontFamily
                                font.pixelSize: MacStyle.fsSmall
                                color: Colors.overSurfaceVariant
                            }
                        }
                    }

                    MouseArea {
                        id: entryArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = entry.index;
                            root.dispatchSubSection(entry.modelData.section, entry.modelData.subSection);
                        }
                    }
                }
            }
        }

        // ── Main pane ────────────────────────────────────────────────────
        Item {
            id: mainPane
            anchors.left: sidebarPanel.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // Top spacer (the old toolbar with the back/forward arrows and the
            // page name was removed; the sidebar already shows where you are)
            Item {
                id: toolbar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: MacStyle.sidebarInset + 6
            }

            // Content area with animated transitions
            Item {
                id: contentArea
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: toolbar.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: MacStyle.pagePadding - 4
                anchors.rightMargin: MacStyle.pagePadding - 4
                anchors.bottomMargin: 14
                clip: true

                property int previousSection: 0
                readonly property int maxContentWidth: 720

                onVisibleChanged: {
                    if (visible)
                        contentArea.previousSection = root.currentSection;
                }

                Connections {
                    target: root
                    function onCurrentSectionChanged() {
                        contentArea.previousSection = root.currentSection;
                    }
                }

                // Panel definitions for Loader
                readonly property var panelComponents: [
                    {
                        component: "WifiPanel.qml",
                        section: 0
                    },
                    {
                        component: "BluetoothPanel.qml",
                        section: 1
                    },
                    {
                        component: "AudioMixerPanel.qml",
                        section: 2
                    },
                    {
                        component: "EasyEffectsPanel.qml",
                        section: 3
                    },
                    {
                        component: "ThemePanel.qml",
                        section: 4
                    },
                    {
                        component: "BindsPanel.qml",
                        section: 5
                    },
                    {
                        component: "SystemPanel.qml",
                        section: 6
                    },
                    {
                        component: "CompositorPanel.qml",
                        section: 7
                    },
                    {
                        component: "ShellPanel.qml",
                        section: 8
                    },
                    {
                        component: "GnomeSettingsPanel.qml",
                        section: 9
                    },
                    {
                        component: "InterfacePanel.qml",
                        section: 10
                    },
                    {
                        component: "UserPanel.qml",
                        section: 11
                    }
                ]

                Loader {
                    id: panelLoader
                    anchors.fill: parent
                    asynchronous: true
                    source: contentArea.panelComponents[root.currentSection]?.component ?? ""

                    opacity: status === Loader.Ready ? 1 : 0
                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: MacStyle.medium
                            easing.type: Easing.OutCubic
                        }
                    }

                    onLoaded: {
                        if (item) {
                            item.maxContentWidth = contentArea.maxContentWidth;
                            if (root.pendingSubSection !== "" && item.currentSection !== undefined) {
                                item.currentSection = root.pendingSubSection;
                                root.pendingSubSection = "";
                            }
                        }
                        const section = contentArea.panelComponents[root.currentSection]?.section ?? -1;
                        if (section === 0) {
                            NetworkService.refreshForUI();
                        } else if (section === 1) {
                            BluetoothService.refreshForUI();
                        }
                    }
                }
            }
        }
    }
}

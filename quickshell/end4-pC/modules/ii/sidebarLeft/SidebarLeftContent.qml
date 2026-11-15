import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property bool mediaEnabled: Config.options.sidebar.media.enable
    property bool scheduleEnabled: Config.options.sidebar.schedule.enable

    // Tab and page mapping. Order here is the tab order shown in the toolbar.
    property var tabs: [
        {
            icon: "translate",
            name: Translation.tr("Translator"),
            enabled: root.translatorEnabled,
            component: translator
        },
        {
            icon: "music_note",
            name: Translation.tr("Media"),
            enabled: root.mediaEnabled,
            component: media
        },
        {
            icon: "calendar_month",
            name: Translation.tr("Schedule"),
            enabled: root.scheduleEnabled,
            component: schedule
        },
        {
            icon: "bookmark_heart",
            name: Translation.tr("Anime"),
            enabled: root.animeEnabled && !root.animeCloset,
            component: anime
        }
    ]

    property var activeTabs: tabs.filter(t => t.enabled)
    property var tabButtonList: activeTabs.map(t => ({
        icon: t.icon,
        name: t.name
    }))
    property int tabCount: activeTabs.length
    property int currentIndex: 0
    // Tracks the previously-focused tab index so the bounce-in transition
    // knows which direction to slide from.
    property int _prevTabIndex: 0
    property var visitedTabs: ({})

    onActiveTabsChanged: {
        if (tabCount === 0) {
            root.currentIndex = 0;
        } else if (root.currentIndex >= tabCount) {
            root.currentIndex = tabCount - 1;
        }
    }

    // Push tab-bar-driven index changes into the SwipeView. This is a
    // guarded imperative assignment rather than a persistent binding
    // ("currentIndex: root.currentIndex") because SwipeView continuously
    // rewrites currentIndex internally while the user drags it; a live
    // binding fighting that produces a binding loop. The inequality check
    // also prevents this from firing back when swipeView itself was the
    // source of the change (see swipeView.onCurrentIndexChanged below).
    onCurrentIndexChanged: {
        if (swipeView.currentIndex !== root.currentIndex
            && root.currentIndex >= 0
            && root.currentIndex < swipeView.count) {
            swipeView.currentIndex = root.currentIndex;
            }
    }

    function focusActiveItem() {
        if (swipeView.currentItem && swipeView.currentItem.item) {
            swipeView.currentItem.item.forceActiveFocus();
        }
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    // Slide the toolbar + tabs in from the left whenever the sidebar opens,
    // matching the connect-mode sidebar's entrance animation.
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (!GlobalStates.sidebarLeftOpen) {
                root.visitedTabs = {};
                return;
            }

            toolbarContainer.opacity = 0
            toolbarTrans.x = -80
            tabBar.opacity = 0
            tabBarTrans.x = -30

            toolbarEntranceAnim.stop()
            toolbarEntranceAnim.start()
        }
    }

    ParallelAnimation {
        id: toolbarEntranceAnim

        // Slide-in of the toolbar pill itself.
        SequentialAnimation {
            PauseAnimation { duration: 30 }
            ParallelAnimation {
                NumberAnimation { target: toolbarContainer; property: "opacity"; to: 1.0; duration: 280; easing.type: Easing.OutCubic }
                NumberAnimation { target: toolbarTrans; property: "x"; to: 0; duration: 360; easing.type: Easing.OutCubic }
            }
        }

        // Staggered slide-in of the tab buttons inside it.
        SequentialAnimation {
            PauseAnimation { duration: 90 }
            ParallelAnimation {
                NumberAnimation { target: tabBar; property: "opacity"; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { target: tabBarTrans; property: "x"; to: 0; duration: 320; easing.type: Easing.OutCubic }
            }
        }
    }

    ColumnLayout {
        // Clip to the sidebar bounds. Without this, the centered toolbar can
        // overflow visibly past the sidebar edges while it's animating in,
        // or when the tab count changes at runtime.
        clip: true
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Item {
            id: toolbarContainer
            visible: activeTabs.length > 1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: mainToolbar.implicitHeight
            Layout.maximumWidth: parent.width
            Layout.preferredWidth: Math.min(mainToolbar.implicitWidth, parent.width)

            transform: Translate {
                id: toolbarTrans
                x: 0
            }

            Toolbar {
                id: mainToolbar
                anchors.fill: parent
                enableShadow: false
                colBackground: Appearance.colors.colLayer3

                ToolbarTabBar {
                    id: tabBar
                    Layout.alignment: Qt.AlignHCenter
                    tabButtonList: root.tabButtonList
                    currentIndex: root.currentIndex

                    transform: Translate {
                        id: tabBarTrans
                        x: 0
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < root.tabCount && root.currentIndex !== currentIndex) {
                            root.currentIndex = currentIndex;
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView {
                id: swipeView
                anchors.fill: parent
                spacing: 10
                clip: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                onCountChanged: {
                    if (count > 0 && root.currentIndex >= 0 && root.currentIndex < count) {
                        currentIndex = root.currentIndex;
                    }
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < root.tabCount && root.currentIndex !== currentIndex) {
                        root.currentIndex = currentIndex;
                    }
                    Qt.callLater(() => {
                        root._prevTabIndex = currentIndex;
                    });

                    if (currentIndex >= 0) {
                        var visited = root.visitedTabs;
                        if (!visited[currentIndex]) {
                            visited[currentIndex] = true;
                            root.visitedTabs = visited;
                        }
                    }
                }

                Component.onCompleted: {
                    if (contentItem) {
                        contentItem.highlightMoveDuration = 0;
                    }
                    if (count > 0 && root.currentIndex >= 0 && root.currentIndex < count) {
                        currentIndex = root.currentIndex;
                    }
                    var visited = root.visitedTabs;
                    visited[currentIndex] = true;
                    root.visitedTabs = visited;
                }

                Repeater {
                    model: root.activeTabs
                    Loader {
                        id: tabDelegate
                        required property var modelData
                        required property int index

                        active: GlobalStates.sidebarLeftOpen && (SwipeView.isCurrentItem || !!root.visitedTabs[index])
                        sourceComponent: modelData.component

                        transform: Translate {
                            id: trans
                            x: 0
                        }

                        onLoaded: {
                            if (item) item.anchors.fill = this;
                        }

                        readonly property bool isCurrent: swipeView.currentIndex === index
                        onIsCurrentChanged: {
                            if (isCurrent) {
                                const diff = index - root._prevTabIndex;
                                if (diff !== 0) {
                                    bounceAnim.stop();
                                    opacityAnim.stop();
                                    trans.x = diff > 0 ? 120 : -120;
                                    tabDelegate.opacity = 0;
                                    bounceAnim.start();
                                    opacityAnim.start();
                                }
                            } else {
                                tabDelegate.opacity = 1;
                                trans.x = 0;
                            }
                        }

                        NumberAnimation {
                            id: bounceAnim
                            target: trans
                            property: "x"
                            to: 0
                            duration: 420
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.45
                        }

                        NumberAnimation {
                            id: opacityAnim
                            target: tabDelegate
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Show placeholder if no tabs are active
            Loader {
                anchors.fill: parent
                active: root.activeTabs.length === 0
                sourceComponent: placeholder
            }
        }

        Component {
            id: translator
            Translator {}
        }
        Component {
            id: media
            SidebarPlayerControl {}
        }
        Component {
            id: schedule
            SidebarStudySchedule {}
        }
        Component {
            id: anime
            Anime {}
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}

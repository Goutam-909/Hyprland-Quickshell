pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.common

Item {
    id: root

    required property PersistentProperties visibilities

    readonly property var dashboardTabs: [
        { component: dashComponent, iconName: "dashboard", text: qsTr("Dashboard") },
        { component: mediaComponent, iconName: "queue_music", text: qsTr("Media") },
        { component: performanceComponent, iconName: "speed", text: qsTr("Performance") }
    ]

    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top

    implicitWidth: nonAnimWidth
    implicitHeight: tabs.implicitHeight + tabs.anchors.bottomMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    Tabs {
        id: tabs

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Appearance.dashboard.padding.normal
        anchors.margins: Appearance.dashboard.padding.large

        nonAnimWidth: root.nonAnimWidth

        // Seed from persisted state on every (re)mount of Content, and
        // write back on every change so the next close/reopen resumes
        // here instead of always falling back to Dash.
        currentIndex: root.visibilities.dashboardTab
        onCurrentIndexChanged: root.visibilities.dashboardTab = currentIndex
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.bottom: tabs.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Appearance.dashboard.padding.large

        radius: Appearance.rounding.normal
        color: "transparent"

        Flickable {
            id: view

            readonly property int currentIndex: tabs.currentIndex
            readonly property Item currentItem: {
                repeater.count;
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent
            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving || !currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 2)
                    tabs.bar.incrementCurrentIndex();
                else if (x < -currentItem.implicitWidth / 2)
                    tabs.bar.decrementCurrentIndex();
            }

            onDragEnded: {
                if (!currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 10)
                    tabs.bar.incrementCurrentIndex();
                else if (x < -currentItem.implicitWidth / 10)
                    tabs.bar.decrementCurrentIndex();
                else
                    contentX = Qt.binding(() => currentItem?.x ?? 0);
            }

            RowLayout {
                id: row

                Repeater {
                    id: repeater

                    model: root.dashboardTabs

                    delegate: Loader {
                        id: paneLoader

                        required property int index
                        required property var modelData

                        Layout.alignment: Qt.AlignTop
                        sourceComponent: modelData.component

                        // Active if current tab, or currently within the
                        // flickable's visible viewport (swipe-in-progress
                        // neighbour). Everything else doesn't exist.
                        Component.onCompleted: active = Qt.binding(() => {
                            if (index === view.currentIndex)
                                return true;
                            const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
                            const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
                            return (vx >= x && vx <= x + implicitWidth) || (vex >= x && vex <= x + implicitWidth);
                        })
                    }
                }
            }

            Component {
                id: dashComponent
                Dash {}
            }

            Component {
                id: mediaComponent
                Media {
                    visibilities: root.visibilities
                }
            }

            Component {
                id: performanceComponent
                Performance {}
            }

            Behavior on contentX {
                NumberAnimation {
                    duration: Appearance.dashboard.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                }
            }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.dashboard.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.dashboard.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
    }
}

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import qs.modules.common

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.dateTimeWidth

    StyledText {
        id: hours

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: (root.height - (hours.implicitHeight + sep.implicitHeight + sep.anchors.topMargin + mins.implicitHeight + mins.anchors.topMargin + day.implicitHeight + day.anchors.topMargin + month.implicitHeight + month.anchors.topMargin + year.implicitHeight + year.anchors.topMargin)) / 2

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("HH")
        color: Appearance.m3colors.m3secondary
        font.pointSize: Appearance.dashboard.fontSize.extraLarge
        font.weight: 500
    }

    StyledText {
        id: sep

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: hours.bottom
        anchors.topMargin: -font.pointSize * 0.5

        horizontalAlignment: Text.AlignHCenter
        text: "•••"
        color: Appearance.m3colors.m3primary
        font.pointSize: Appearance.dashboard.fontSize.extraLarge * 0.9
    }

    StyledText {
        id: mins

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sep.bottom
        anchors.topMargin: -sep.font.pointSize * 0.45

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("mm")
        color: Appearance.m3colors.m3secondary
        font.pointSize: Appearance.dashboard.fontSize.extraLarge
        font.weight: 500
    }

    StyledText {
        id: day

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: mins.bottom
        anchors.topMargin: Appearance.dashboard.spacing.normal

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("ddd, d")
        color: Appearance.m3colors.m3tertiary
        font.pointSize: Appearance.dashboard.fontSize.normal
        font.weight: 500
    }

    StyledText {
        id: month

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: day.bottom
        anchors.topMargin: Appearance.dashboard.spacing.normal

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("MMMM")
        color: Appearance.m3colors.m3tertiary
        font.pointSize: Appearance.dashboard.fontSize.normal
        font.weight: 500
    }

    StyledText {
        id: year

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: month.bottom
        anchors.topMargin: Appearance.dashboard.spacing.normal

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("yyyy")
        color: Appearance.m3colors.m3tertiary
        font.pointSize: Appearance.dashboard.fontSize.normal
        font.weight: 500
    }
}




import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import qs.modules.common
import qs.services

Item {
    id: root

    anchors.centerIn: parent

    implicitWidth: icon.implicitWidth + info.implicitWidth + info.anchors.leftMargin

    // ii's Weather service uses OpenWeatherMap condition codes (200s
    // thunderstorm, 300s drizzle, 500s rain, 600s snow, 700s atmosphere,
    // 800 clear, 80x clouds) rather than the Open-Meteo/WMO codes
    // Icons.getWeatherIcon() expects, so this maps them locally instead
    // of reusing that helper with the wrong code scheme.
    function owmIconFor(code) {
        if (code >= 200 && code < 300)
            return "thunderstorm";
        if (code >= 300 && code < 400)
            return "rainy_light";
        if (code >= 500 && code < 600)
            return "rainy";
        if (code >= 600 && code < 700)
            return "weather_snowy";
        if (code >= 700 && code < 800)
            return "foggy";
        if (code === 800)
            return "clear_day";
        if (code > 800)
            return "cloud";
        return "cloud_alert";
    }

    onVisibleChanged: {
        if (visible)
            Weather.getData();
    }

    MaterialIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        animate: true
        text: root.owmIconFor(Weather.data.wCode) || "cloud_alert"
        color: Appearance.m3colors.m3secondary
        font.pointSize: Appearance.dashboard.fontSize.extraLarge * 2
        font.variableAxes: ({
                opsz: Appearance.dashboard.fontSize.extraLarge * 1.2
            })
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Appearance.dashboard.spacing.large

        spacing: Appearance.dashboard.spacing.small

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.data.temp || ""
            color: Appearance.m3colors.m3primary
            font.pointSize: Appearance.dashboard.fontSize.extraLarge
            font.weight: 500
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.data.description || qsTr("No weather")

            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.parent.width - icon.implicitWidth - info.anchors.leftMargin - Appearance.dashboard.padding.large * 2)
        }
    }
}




import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import qs.modules.common
import qs.services

Column {
    id: root

    required property Brightness.BrightnessMonitor monitor

    padding: Appearance.dashboard.padding.large

    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right

    spacing: Appearance.dashboard.spacing.normal

    VerticalSlider {
        icon: {
            if (Audio.sink?.audio.muted ?? false)
                return "no_sound";
            if (value > 0.66)
                return "volume_up";
            if (value > 0.33)
                return "volume_down";
            return "volume_mute";
        }
        value: Audio.value
        onMoved: {
            if (Audio.sink) {
                Audio.sink.audio.muted = false;
                Audio.sink.audio.volume = value;
            }
        }

        implicitWidth: Config.options.caelestiaDashboard.osd.sizes.sliderWidth
        implicitHeight: Config.options.caelestiaDashboard.osd.sizes.sliderHeight
    }

    VerticalSlider {
        icon: `brightness_${(Math.round(value * 6) + 1)}`
        value: root.monitor?.multipliedBrightness ?? 0
        onMoved: root.monitor?.setBrightness(value)

        implicitWidth: Config.options.caelestiaDashboard.osd.sizes.sliderWidth
        implicitHeight: Config.options.caelestiaDashboard.osd.sizes.sliderHeight
    }
}




import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "dashboard"
            title: Translation.tr("Border")

            GroupedList {
                ConfigSpinBox {
                    icon: "border_style"
                    text: Translation.tr("Thickness")
                    value: Config.options.caelestiaDashboard.border.thickness
                    from: 0
                    to: 40
                    stepSize: 1
                    onValueChanged: { Config.options.caelestiaDashboard.border.thickness = value; }
                }
                ConfigSpinBox {
                    icon: "rounded_corner"
                    text: Translation.tr("Rounding")
                    value: Config.options.caelestiaDashboard.border.rounding
                    from: 0
                    to: 60
                    stepSize: 1
                    onValueChanged: { Config.options.caelestiaDashboard.border.rounding = value; }
                }
            }
        }

        ContentSection {
            icon: "picture_in_picture"
            title: Translation.tr("OSD")

            GroupedList {
                ConfigSpinBox {
                    icon: "timer"
                    text: Translation.tr("Hide delay (ms)")
                    value: Config.options.caelestiaDashboard.osd.hideDelay
                    from: 200
                    to: 10000
                    stepSize: 100
                    onValueChanged: { Config.options.caelestiaDashboard.osd.hideDelay = value; }
                }
                ConfigSpinBox {
                    icon: "width"
                    text: Translation.tr("Slider width")
                    value: Config.options.caelestiaDashboard.osd.sizes.sliderWidth
                    from: 10
                    to: 100
                    stepSize: 1
                    onValueChanged: { Config.options.caelestiaDashboard.osd.sizes.sliderWidth = value; }
                }
                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Slider height")
                    value: Config.options.caelestiaDashboard.osd.sizes.sliderHeight
                    from: 40
                    to: 400
                    stepSize: 5
                    onValueChanged: { Config.options.caelestiaDashboard.osd.sizes.sliderHeight = value; }
                }
            }
        }

        ContentSection {
            icon: "power_settings_new"
            title: Translation.tr("Session screen")

            GroupedList {
                ConfigSpinBox {
                    icon: "swipe"
                    text: Translation.tr("Drag threshold")
                    value: Config.options.caelestiaDashboard.session.dragThreshold
                    from: 5
                    to: 150
                    stepSize: 5
                    onValueChanged: { Config.options.caelestiaDashboard.session.dragThreshold = value; }
                }
                ConfigSpinBox {
                    icon: "radio_button_checked"
                    text: Translation.tr("Button size")
                    value: Config.options.caelestiaDashboard.session.sizes.button
                    from: 40
                    to: 200
                    stepSize: 5
                    onValueChanged: { Config.options.caelestiaDashboard.session.sizes.button = value; }
                }
            }
        }

        ContentSection {
            icon: "monitoring"
            title: Translation.tr("Dashboard")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "device_thermostat"
                    text: Translation.tr("Use Fahrenheit for performance tab")
                    checked: Config.options.caelestiaDashboard.dashboard.useFahrenheitPerformance
                    onCheckedChanged: { Config.options.caelestiaDashboard.dashboard.useFahrenheitPerformance = checked; }
                }
                ConfigSpinBox {
                    icon: "podcasts"
                    text: Translation.tr("Media update interval (ms)")
                    value: Config.options.caelestiaDashboard.dashboard.mediaUpdateInterval
                    from: 100
                    to: 5000
                    stepSize: 100
                    onValueChanged: { Config.options.caelestiaDashboard.dashboard.mediaUpdateInterval = value; }
                }
                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Resource update interval (ms)")
                    value: Config.options.caelestiaDashboard.dashboard.resourceUpdateInterval
                    from: 200
                    to: 10000
                    stepSize: 100
                    onValueChanged: { Config.options.caelestiaDashboard.dashboard.resourceUpdateInterval = value; }
                }
                ConfigSpinBox {
                    icon: "graphic_eq"
                    text: Translation.tr("Visualiser bars")
                    value: Config.options.caelestiaDashboard.dashboard.visualiserBars
                    from: 10
                    to: 200
                    stepSize: 5
                    onValueChanged: { Config.options.caelestiaDashboard.dashboard.visualiserBars = value; }
                }
            }
        }

        ContentSection {
            icon: "toggle_on"
            title: Translation.tr("Performance cards")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("Show CPU")
                    checked: Config.options.caelestiaDashboard.dashboard.performance.showCpu
                    onCheckedChanged: { Config.options.caelestiaDashboard.dashboard.performance.showCpu = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "developer_board"
                    text: Translation.tr("Show GPU")
                    checked: Config.options.caelestiaDashboard.dashboard.performance.showGpu
                    onCheckedChanged: { Config.options.caelestiaDashboard.dashboard.performance.showGpu = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "sd_card"
                    text: Translation.tr("Show Memory")
                    checked: Config.options.caelestiaDashboard.dashboard.performance.showMemory
                    onCheckedChanged: { Config.options.caelestiaDashboard.dashboard.performance.showMemory = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "hard_drive"
                    text: Translation.tr("Show Storage")
                    checked: Config.options.caelestiaDashboard.dashboard.performance.showStorage
                    onCheckedChanged: { Config.options.caelestiaDashboard.dashboard.performance.showStorage = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "lan"
                    text: Translation.tr("Show Network")
                    checked: Config.options.caelestiaDashboard.dashboard.performance.showNetwork
                    onCheckedChanged: { Config.options.caelestiaDashboard.dashboard.performance.showNetwork = checked; }
                }
                ConfigSwitch {
                    buttonIcon: "battery_full"
                    text: Translation.tr("Show Battery")
                    checked: Config.options.caelestiaDashboard.dashboard.performance.showBattery
                    onCheckedChanged: { Config.options.caelestiaDashboard.dashboard.performance.showBattery = checked; }
                }
            }
        }
    }
}

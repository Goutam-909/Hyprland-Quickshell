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
            icon: "notes"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Notch")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "toggle_on"
                    text: Translation.tr("Enable notch")
                    checked: Config.options.notch.enable
                    onCheckedChanged: { Config.options.notch.enable = checked; }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Position")
                    icon: "swap_vert"
                    currentValue: Config.options.notch.position
                    onSelected: newValue => { Config.options.notch.position = newValue; }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: "top" },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: "bottom" }
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.notch.theme
                    onSelected: newValue => { Config.options.notch.theme = newValue; }
                    options: [
                        { displayName: Translation.tr("Default"), icon: "line_curve", value: "default" },
                        { displayName: Translation.tr("Island"),  icon: "crop_3_2",   value: "island" }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "variable_insert"
                    text: Translation.tr("Show background")
                    checked: Config.options.notch.showBackground
                    onCheckedChanged: { Config.options.notch.showBackground = checked; }
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Animation duration (ms)")
                    value: Config.options.notch.animDuration
                    from: 0
                    to: 600
                    stepSize: 20
                    onValueChanged: { Config.options.notch.animDuration = value; }
                }
            }
        }
    }
}

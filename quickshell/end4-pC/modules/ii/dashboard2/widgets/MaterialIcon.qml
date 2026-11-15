import qs.modules.common

StyledText {
    property real fill

    font.family: Appearance.font.family.iconMaterial
    font.pointSize: Appearance.dashboard.fontSize.larger
    font.variableAxes: ({
            FILL: fill.toFixed(1)
        })
}




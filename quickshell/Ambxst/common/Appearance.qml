// common/Appearance.qml
// Compatibility facade for components ported from another Quickshell config.
// Those components read Appearance.colors.col*, Appearance.font.family.main,
// and Appearance.rounding.large. This file supplies exactly that surface,
// wired to THIS shell's real theme singletons (qs.modules.theme.Colors /
// Styling / qs.config.Config) instead of duplicating a second palette.
//
// Formulas for the derived "layer" hover/active tones are ported as-is from
// the source design's own Appearance.qml so the hover/press feel matches
// exactly — only the base colors underneath are swapped for this shell's.
pragma Singleton
import QtQuick
import Quickshell
import qs.modules.theme
import qs.config
import qs.modules.services as Backend
import "functions"

QtObject {
    id: root

    readonly property QtObject colors: QtObject {
        // Bases
        readonly property color colSurface:                 Colors.surface
        readonly property color colSurfaceContainer:         Colors.surfaceContainer
        readonly property color colSurfaceContainerHigh:     Colors.surfaceContainerHigh
        readonly property color colSurfaceContainerHighT:    Colors.surfaceContainerHigh
        readonly property color colSurfaceContainerHighest:  Colors.surfaceContainerHighest
        readonly property color colSurfaceVariant:           Colors.surfaceVariant

        // On-colors (source design calls these "colOnX")
        readonly property color colOnSurface:                Colors.overSurface
        readonly property color colOnSurfaceVariant:         Colors.overSurfaceVariant

        // Primary
        readonly property color colPrimary:                  Colors.primary
        readonly property color colOnPrimary:                Colors.overPrimary
        readonly property color colPrimaryContainer:         Colors.primaryContainer
        readonly property color colOnPrimaryContainer:       Colors.overPrimaryContainer
        readonly property color colPrimaryHover:             ColorUtils.mix(Colors.primary, Colors.overPrimary, 0.9)
        readonly property color colPrimaryActive:            ColorUtils.mix(Colors.primary, Colors.overPrimary, 0.8)

        // Secondary
        readonly property color colSecondaryContainer:       Colors.secondaryContainer
        readonly property color colOnSecondaryContainer:     Colors.overSecondaryContainer

        // Error
        readonly property color colError:                    Colors.error

        // Outline / shadow
        readonly property color colOutline:                  Colors.outline
        readonly property color colOutlineVariant:            Colors.outlineVariant
        readonly property color colShadow:                   Colors.shadow

        // Layer system — same mix formulas the source design uses, applied
        // to this shell's own base tones.
        readonly property color colLayer2:                   Colors.surface
        readonly property color colLayer2Hover:              ColorUtils.mix(colLayer2, Colors.overSurface, 0.95)
        readonly property color colLayer2Active:             ColorUtils.mix(colLayer2, Colors.overSurface, 0.9)

        readonly property color colLayer3:                   colSurfaceContainerHigh
        readonly property color colLayer3Hover:              ColorUtils.mix(colLayer3, Colors.overSurface, 0.95)
        readonly property color colLayer3Active:              ColorUtils.mix(colLayer3, Colors.overSurface, 0.9)
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            // Uses this shell's configured UI font instead of hardcoding the
            // other config's "SF Pro" — keeps typography consistent with the
            // rest of the bar/dashboard. Change to a literal string here if
            // you specifically want to force a different font for just the
            // control center.
            readonly property string main: Config.theme.font
        }
        readonly property QtObject size: QtObject {
            readonly property int large: 18
        }
    }

    readonly property QtObject rounding: QtObject {
        // 28px in the source design — run through this shell's own radius
        // scale (Styling.radius) so it still respects your global roundness
        // setting, but keeps the same base value.
        readonly property int large: Styling.radius(28)
    }
}




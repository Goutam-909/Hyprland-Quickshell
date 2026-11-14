import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    function generate(Colors) {
        if (!Colors) return

            // "#rrggbb"
            const fmt = (c) => c.toString()
            // rgba() with custom alpha, for hover/active states
            const rgba = (c, a) => `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${a})`

            // Base surfaces
            const bg          = fmt(Colors.background)
            const surface     = fmt(Colors.surface)
            const container   = fmt(Colors.surfaceContainer)
            const containerLo = fmt(Colors.surfaceContainerLow)
            const containerHi = fmt(Colors.surfaceContainerHigh)
            const containerHx = fmt(Colors.surfaceContainerHighest)

            // Accents
            const primary     = fmt(Colors.primary)
            const onPrimary   = fmt(Colors.overPrimary)
            const primaryCont = fmt(Colors.primaryContainer)
            const onPrimCont  = fmt(Colors.overPrimaryContainer)
            const secondary   = fmt(Colors.secondary)
            const secondaryCt = fmt(Colors.secondaryContainer)
            const tertiary    = fmt(Colors.tertiary)

            // Text and borders
            const text        = fmt(Colors.overBackground)
            const textDim     = fmt(Colors.overSurfaceVariant)
            const outline     = fmt(Colors.outline)
            const outlineVar  = fmt(Colors.outlineVariant)

            // Status
            const error       = fmt(Colors.error)
            const success     = fmt(Colors.success)
            const warning     = fmt(Colors.warning)

            // ---------- Browser UI (userChrome.css) ----------
            let css = `:root {
                /* ===== Zen core ===== */
                --zen-primary-color: ${primary} !important;
                --zen-colors-primary: ${container} !important;
                --zen-colors-secondary: ${containerHi} !important;
                --zen-colors-tertiary: ${bg} !important;
                --zen-colors-border: ${primary} !important;
                --zen-colors-hover-bg: ${rgba(Colors.primary, 0.15)} !important;
                --zen-branding-dark: ${bg} !important;
                --zen-branding-paper: ${secondary} !important;
                --zen-main-browser-background: ${bg} !important;
                --zen-main-browser-background-toolbar: ${bg} !important;
                --zen-navigator-toolbox-background: ${bg} !important;
                --zen-themed-toolbar-bg: ${bg} !important;
                --zen-themed-toolbar-bg-transparent: ${bg} !important;
                --zen-dialog-background: ${container} !important;
                --zen-urlbar-background: ${container} !important;

                /* ===== Toolbar / window ===== */
                --toolbar-bgcolor: ${bg} !important;
                --toolbar-color: ${text} !important;
                --lwt-accent-color: ${bg} !important;
                --lwt-text-color: ${text} !important;
                --chrome-content-separator-color: ${outlineVar} !important;
                --tabpanel-background-color: ${bg} !important;
                --focus-outline-color: ${primary} !important;
                --link-color: ${primary} !important;

                /* ===== Tabs ===== */
                --tab-selected-bgcolor: ${containerHi} !important;
                --tab-selected-textcolor: ${text} !important;
                --lwt-tab-text: ${textDim} !important;
                --tab-loading-fill: ${primary} !important;
                --tab-attention-icon-color: ${primary} !important;

                /* ===== Buttons ===== */
                --toolbarbutton-hover-background: ${rgba(Colors.primary, 0.15)} !important;
                --toolbarbutton-active-background: ${rgba(Colors.primary, 0.25)} !important;
                --toolbarbutton-icon-fill: ${text} !important;
                --toolbarbutton-icon-fill-attention: ${primary} !important;
                --button-primary-bgcolor: ${primary} !important;
                --button-primary-color: ${onPrimary} !important;
                --button-primary-hover-bgcolor: ${primaryCont} !important;
                --button-primary-hover-color: ${onPrimCont} !important;

                /* ===== URL bar ===== */
                --toolbar-field-background-color: ${container} !important;
                --toolbar-field-color: ${text} !important;
                --toolbar-field-border-color: ${outlineVar} !important;
                --toolbar-field-focus-background-color: ${containerHi} !important;
                --toolbar-field-focus-color: ${text} !important;
                --toolbar-field-focus-border-color: ${primary} !important;
                --urlbar-box-bgcolor: ${container} !important;
                --urlbar-box-hover-bgcolor: ${containerHi} !important;
                --urlbar-box-focus-bgcolor: ${containerHi} !important;
                --urlbar-box-text-color: ${text} !important;
                --urlbarView-highlight-background: ${rgba(Colors.primary, 0.2)} !important;
                --urlbarView-highlight-color: ${text} !important;
                --urlbarView-hover-background: ${rgba(Colors.primary, 0.1)} !important;
                --urlbarView-separator-color: ${outlineVar} !important;
                --urlbarView-results-padding: 4px !important;

                /* ===== Popups / panels / menus ===== */
                --arrowpanel-background: ${container} !important;
                --arrowpanel-color: ${text} !important;
                --arrowpanel-border-color: ${outline} !important;
                --arrowpanel-dimmed: ${rgba(Colors.primary, 0.12)} !important;
                --arrowpanel-dimmed-further: ${rgba(Colors.primary, 0.2)} !important;
                --panel-background: ${container} !important;
                --panel-color: ${text} !important;
                --panel-border-color: ${outline} !important;
                --panel-separator-color: ${outlineVar} !important;
                --panel-description-color: ${textDim} !important;
                --autocomplete-popup-background: ${container} !important;
                --autocomplete-popup-color: ${text} !important;
                --autocomplete-popup-highlight-background: ${primaryCont} !important;
                --autocomplete-popup-highlight-color: ${onPrimCont} !important;

                /* ===== Sidebar ===== */
                --sidebar-background-color: ${bg} !important;
                --sidebar-text-color: ${text} !important;
                --sidebar-border-color: ${outlineVar} !important;

                /* ===== Status colors ===== */
                --zen-error-color: ${error} !important;
                --zen-success-color: ${success} !important;
                --zen-warning-color: ${warning} !important;
            }

            /* ===== Backgrounds ===== */
            .zen-toolbar-background,
            #zen-main-app-wrapper,
            #navigator-toolbox,
            #nav-bar,
            #TabsToolbar,
            #PersonalToolbar {
            background: ${bg} !important;
            }

            .zen-browser-generic-background::after,
            .zen-browser-generic-background::before {
                background: ${bg} !important;
            }

            /* ===== URL bar ===== */
            #urlbar-background {
            background-color: ${container} !important;
            border-color: ${outlineVar} !important;
            }
            #urlbar[focused="true"] > #urlbar-background,
            #urlbar[open] > #urlbar-background {
            background-color: ${containerHi} !important;
            border-color: ${primary} !important;
            }
            #urlbar-input,
            #urlbar .urlbar-input {
            color: ${text} !important;
            }

            /* ===== Tabs ===== */
            .tabbrowser-tab[selected] > .tab-stack > .tab-background {
                background-color: ${containerHi} !important;
            }
            .tabbrowser-tab:not([selected]):hover > .tab-stack > .tab-background {
                background-color: ${rgba(Colors.primary, 0.12)} !important;
            }
            .tabbrowser-tab .tab-label {
                color: ${text} !important;
            }

            /* ===== Menus ===== */
            menupopup,
            panel {
                --panel-background: ${container} !important;
                --panel-color: ${text} !important;
            }
            menuitem:hover,
            menu:hover,
            .subviewbutton:hover {
                background-color: ${rgba(Colors.primary, 0.18)} !important;
            }
            `

            // ---------- about: pages / new tab (userContent.css) ----------
            let contentCss = `@-moz-document url-prefix("about:") {
                :root {
                    --in-content-page-background: ${bg} !important;
                    --in-content-page-color: ${text} !important;
                    --in-content-text-color: ${text} !important;
                    --in-content-deemphasized-text: ${textDim} !important;
                    --in-content-box-background: ${container} !important;
                    --in-content-box-background-hover: ${containerHi} !important;
                    --in-content-box-background-active: ${containerHx} !important;
                    --in-content-box-border-color: ${outlineVar} !important;
                    --in-content-border-color: ${outlineVar} !important;
                    --in-content-border-hover-color: ${outline} !important;
                    --in-content-border-focus: ${primary} !important;
                    --in-content-border-active: ${primary} !important;
                    --in-content-accent-color: ${primary} !important;
                    --in-content-accent-color-active: ${primaryCont} !important;
                    --in-content-link-color: ${primary} !important;
                    --in-content-link-color-hover: ${secondary} !important;
                    --in-content-primary-button-background: ${primary} !important;
                    --in-content-primary-button-background-hover: ${primaryCont} !important;
                    --in-content-primary-button-text-color: ${onPrimary} !important;
                    --in-content-button-background: ${containerHi} !important;
                    --in-content-button-background-hover: ${containerHx} !important;
                    --in-content-button-text-color: ${text} !important;
                    --in-content-focus-outline-color: ${primary} !important;
                    --in-content-table-background: ${container} !important;
                    --in-content-table-border-color: ${outlineVar} !important;
                    --in-content-item-hover: ${rgba(Colors.primary, 0.12)} !important;
                    --in-content-item-selected: ${primaryCont} !important;
                    --in-content-item-selected-text: ${onPrimCont} !important;

                    /* New tab / home */
                    --newtab-background-color: ${bg} !important;
                    --newtab-background-color-secondary: ${container} !important;
                    --newtab-text-primary-color: ${text} !important;
                    --newtab-text-secondary-color: ${textDim} !important;
                    --newtab-primary-action-background: ${primary} !important;
                    --newtab-border-color: ${outlineVar} !important;
                    --newtab-element-hover-color: ${containerHi} !important;
                    --newtab-element-active-color: ${containerHx} !important;
                    --newtab-searchbar-background: ${container} !important;
                }
            }
            `

            const home = Quickshell.env("HOME")
            const outputPath  = home + "/.cache/ambxst/pywalzen.css"
            const contentPath = home + "/.cache/ambxst/pywalzen-content.css"

            const escape = (str) => {
                if (!str) return ""
                    return str.toString()
                    .replace(/\\/g, "\\\\")
                    .replace(/"/g, '\\"')
                    .replace(/\$/g, '\\$')
                    .replace(/`/g, '\\`')
            }

            const cmd = `mkdir -p "$(dirname "${outputPath}")" && ` +
            `printf '%s\\n' "${escape(css)}" > "${outputPath}" && ` +
            `printf '%s\\n' "${escape(contentCss)}" > "${contentPath}"`

            writerProcess.command = ["sh", "-c", cmd]
            writerProcess.running = true
    }

    property Process writerProcess: Process {
        id: writerProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: console.log("PywalZenGenerator: Theme generated.")
        }
        stderr: StdioCollector {
            onStreamFinished: (err) => {
                if (err) {
                    const text = err.toString().trim()
                    if (text) console.error("PywalZenGenerator Error:", text)
                }
            }
        }
    }
}

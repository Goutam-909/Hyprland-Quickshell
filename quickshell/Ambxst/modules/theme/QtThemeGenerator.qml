import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Replicates end4-pC's "apply_qt" step. In end4-pC that step is a no-op
// in applycolor.sh (commented out) because Qt/Plasma/Kvantum theming is
// delegated entirely to the `kde-material-you-colors` daemon/CLI, which is
// fed a single accent color via color.txt. This generator does exactly
// that for Ambxst: it writes the live primary color to
// $XDG_STATE_HOME/colors/color.txt and invokes your
// kde-material-you-colors-wrapper.sh, which then drives
// kde-material-you-colors --color <hex> -l/-d -sv <scheme-variant>.

QtObject {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.config/uchiha"))
    readonly property string colorsDir: stateDir + "/colors"
    readonly property string colorTxtPath: colorsDir + "/color.txt"
    // Place kde-material-you-colors-wrapper.sh here (see setup notes).
    readonly property string wrapperPath: colorsDir + "/kde-material-you-colors-wrapper.sh"

    // Must be one of the values kde-material-you-colors-wrapper.sh understands:
    // scheme-content, scheme-expressive, scheme-fidelity, scheme-monochrome,
    // scheme-neutral, scheme-tonal-spot, scheme-vibrant, scheme-rainbow,
    // scheme-fruit-salad
    property string schemeVariant: "scheme-tonal-spot"

    function generate(Colors) {
        if (!Colors)
            return;

        const primaryHex = Colors.primary.toString();
        writer.text = primaryHex;

        const cmd = `
            mkdir -p "${colorsDir}" && \\
            printf '%s' "${primaryHex}" > "${colorTxtPath}"

            # end4-pC (switchwall.sh) does exactly this: no pkill, no
            # setsid, no disown, no proof-of-life check — just call the
            # wrapper and background it with a single '&' at the call
            # site (their "handle_kde_material_you_colors &"). Redirecting
            # to /dev/null is the only addition, purely so the detached
            # child doesn't SIGPIPE if it tries to write after this
            # script's stdout pipe is already closed.
            if [ -x "${wrapperPath}" ]; then
                "${wrapperPath}" --scheme-variant ${schemeVariant} >/dev/null 2>&1 &
            elif command -v kde-material-you-colors-wrapper.sh >/dev/null 2>&1; then
                kde-material-you-colors-wrapper.sh --scheme-variant ${schemeVariant} >/dev/null 2>&1 &
            elif command -v kde-material-you-colors >/dev/null 2>&1; then
                current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
                mode_flag="-l"
                [ "$current_mode" = "prefer-dark" ] && mode_flag="-d"
                kde-material-you-colors "$mode_flag" --color "${primaryHex}" -sv 5 >/dev/null 2>&1 &
            else
                echo "kde-material-you-colors not found; Qt/Plasma theming skipped" >&2
            fi
        `;

        writerProcess.command = ["sh", "-c", cmd];
        writerProcess.running = true;
    }

    property QtObject writer: QtObject {
        id: writer
        property string text
    }

    property Process writerProcess: Process {
        id: writerProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: console.log("QtThemeGenerator: color.txt updated, kde-material-you-colors invoked.")
        }
        stderr: StdioCollector {
            onStreamFinished: err => {
                if (err)
                    console.error("QtThemeGenerator Error:", err);
            }
        }
    }
}

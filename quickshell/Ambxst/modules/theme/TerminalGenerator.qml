import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Replaces KittyGenerator.qml.
// Replicates end4-pC's applycolor.sh "apply_term" (apply_kitty + apply_anyterm)
// but generated natively in QML instead of sed-templating a static file, and
// written to the SAME location end4-pC / your kde-material-you-colors-wrapper.sh
// already use: $XDG_STATE_HOME/colors/terminal  (defaults to ~/.config/uchiha/colors/terminal)

QtObject {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.config/uchiha"))
    readonly property string terminalDir: stateDir + "/colors/terminal"

    function generate(Colors) {
        if (!Colors)
            return;

        const fmt = c => c.toString();
        const strip = c => c.replace("#", "");

        const foreground = fmt(Colors.overSurface);
        const background = fmt(Colors.background);
        const selectionForeground = fmt(Colors.overSecondary);
        const selectionBackground = fmt(Colors.secondaryFixedDim);

        // black
        const color0 = fmt(Colors.surfaceContainerLow);
        const color8 = fmt(Colors.surfaceBright);
        // red
        const color1 = fmt(Colors.red);
        const color9 = fmt(Colors.lightRed);
        // green
        const color2 = fmt(Colors.green);
        const color10 = fmt(Colors.lightGreen);
        // yellow
        const color3 = fmt(Colors.yellow);
        const color11 = fmt(Colors.lightYellow);
        // blue (primary, as in your original KittyGenerator)
        const color4 = fmt(Colors.primary);
        const color12 = fmt(Colors.lightBlue);
        // magenta
        const color5 = fmt(Colors.magenta);
        const color13 = fmt(Colors.lightMagenta);
        // cyan
        const color6 = fmt(Colors.cyan);
        const color14 = fmt(Colors.lightCyan);
        // white
        const color7 = fmt(Colors.outline);
        const color15 = fmt(Colors.overSurface);

        // ---------------------------------------------------------------
        // kitty-theme.conf  (matches end4-pC's actual layout exactly:
        // background, color0-15, cursor, foreground, selection_*, then an
        // extended color232-255 block starship reads for prompt segments)
        // ---------------------------------------------------------------
        const line = (key, val) => `${key.padEnd(22)}${val}\n`;
        const palette = [color0, color1, color2, color3, color4, color5, color6, color7,
                          color8, color9, color10, color11, color12, color13, color14, color15];

        let conf = "";
        conf += line("background", background);
        conf += "\n";
        for (let i = 0; i < 16; i++)
            conf += line(`color${i}`, palette[i]);
        conf += "\n";
        conf += line("cursor", foreground);
        conf += "\n";
        conf += line("foreground", foreground);
        conf += "\n";
        conf += line("selection_background", selectionBackground);
        conf += line("selection_foreground", selectionForeground);
        conf += "\n";

        // Starship prompt segment overrides.
        // CONFIRMED = exact-matched against fixed MD3 dark-mode constants
        // or exact duplicate values found in your reference file.
        // BEST-EFFORT = plausible Colors.qml property, unverified — send
        // the material_colors.scss (or colors.json) generated alongside
        // your reference sequences-e4.txt/kitty-theme-e4.conf and these
        // get locked in exactly.
        conf += "# Starship / prompt segment overrides\n";
        conf += line("color255", fmt(Colors.primary));                   // CONFIRMED
        conf += line("color254", fmt(Colors.primaryContainer));          // best-effort
        conf += line("color253", fmt(Colors.overPrimaryContainer));      // best-effort
        conf += line("color252", selectionForeground);                  // CONFIRMED
        conf += line("color251", fmt(Colors.overTertiaryContainer));     // best-effort
        conf += line("color250", fmt(Colors.tertiaryContainer));         // best-effort
        conf += line("color249", fmt(Colors.error));                     // CONFIRMED
        conf += line("color248", fmt(Colors.errorContainer));            // CONFIRMED
        conf += "\n";
        conf += line("color232", fmt(Colors.overPrimary));               // best-effort
        conf += line("color233", fmt(Colors.tertiaryFixed));             // best-effort
        conf += line("color234", fmt(Colors.overSecondaryContainer));    // best-effort
        conf += line("color235", selectionBackground);                  // CONFIRMED
        conf += line("color236", fmt(Colors.success));                   // best-effort
        conf += line("color237", fmt(Colors.shadow));                    // CONFIRMED
        conf += line("color238", fmt(Colors.overError));                 // CONFIRMED
        conf += line("color239", fmt(Colors.overErrorContainer));        // CONFIRMED
        conf += line("color240", fmt(Colors.overPrimary));               // CONFIRMED dup of 232
        conf += "\n";
        conf += line("color243", fmt(Colors.primary));                   // CONFIRMED dup of 255
        conf += line("color244", fmt(Colors.error));                     // CONFIRMED dup of 249
        conf += line("color245", fmt(Colors.outline));                   // best-effort

        // ---------------------------------------------------------------
        // sequences.txt  (equivalent of end4-pC's terminal/sequences.txt)
        // Real ESC (0x1B) bytes + OSC codes, broadcast-able to any /dev/pts/*
        // so it repaints kitty, foot, alacritty(w/ live-config-reload off),
        // xterm, wezterm, etc. the moment it's cat'd into the tty.
        //
        // Matches end4-pC's layout exactly: everything concatenated on a
        // single line (no newlines between codes), palette (0-15) first,
        // then the fg/bg/cursor/highlight aliases, then the extended
        // 232/256 aliases, then the alpha-tagged window-border (708), then
        // a trailing plain (non-alpha) background set for terminals that
        // don't understand the "[alpha]" prefix.
        // ---------------------------------------------------------------
        const ESC = "\x1b";
        const ST = ESC + "\\"; // String Terminator
        const osc = (code, val) => `${ESC}]${code};${val}${ST}`;

        // term_alpha: 100 = fully opaque, matches end4-pC's `term_alpha` var.
        // NOTE: reference output ALWAYS wraps 11/708 in [N], even at 100 —
        // it is not conditional on transparency.
        const termAlpha = 100;
        const alphaTag = `[${termAlpha}]`;

        let seq = "";
        palette.forEach((c, i) => {
            seq += osc(`4;${i}`, `#${strip(c)}`);
            if (i === 0)
                seq += osc("1;0", `#${strip(c)}`); // duplicate emitted by end4-pC right after color0
        });
        seq += osc(10, `#${strip(foreground)}`);                        // foreground
        seq += osc(11, `${alphaTag}#${strip(background)}`);             // background (alpha-tagged)
        seq += osc(12, `#${strip(foreground)}`);                        // cursor
        seq += osc(13, `#${strip(foreground)}`);                        // pointer/mouse foreground
        seq += osc(17, `#${strip(foreground)}`);                        // highlight background (inverted)
        seq += osc(19, `#${strip(background)}`);                        // highlight foreground (inverted)
        seq += osc("4;232", `#${strip(foreground)}`);                   // extended alias
        seq += osc("4;256", `#${strip(foreground)}`);                   // extended alias
        seq += osc(708, `${alphaTag}#${strip(background)}`);            // VTE/window border, alpha-tagged
        seq += osc(11, `#${strip(background)}`);                        // plain fallback background

        writer.text = conf;

        const kittyPath = `${terminalDir}/kitty-theme.conf`;
        const seqPath = `${terminalDir}/sequences.txt`;

        // base64 round-trip so raw ESC bytes survive shell quoting untouched
        const confB64 = Qt.btoa(conf);
        const seqB64 = Qt.btoa(seq);

        const cmd = `
            mkdir -p "${terminalDir}" && \\
            echo "${confB64}" | base64 -d > "${kittyPath}" && \\
            echo "${seqB64}" | base64 -d > "${seqPath}"

            # Reload kitty in place (apply_kitty)
            pkill -SIGUSR1 kitty 2>/dev/null

            # Broadcast to every open terminal (apply_anyterm)
            for f in /dev/pts/*; do
                if [ -w "$f" ]; then
                    cat "${seqPath}" > "$f" 2>/dev/null &
                fi
            done
            wait
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
            onStreamFinished: console.log("TerminalGenerator: kitty-theme.conf + sequences.txt written to " + terminalDir)
        }
        stderr: StdioCollector {
            onStreamFinished: err => {
                if (err)
                    console.error("TerminalGenerator Error:", err);
            }
        }
    }
}

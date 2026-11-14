import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    function generate(Colors) {
        if (!Colors)
            return;
        const fmt = c => c.toString();

        const fishVars = [
            ["fish_color_normal",           fmt(Colors.overSurface)],
            ["fish_color_command",          fmt(Colors.primary)],
            ["fish_color_keyword",          fmt(Colors.tertiary)],
            ["fish_color_quote",            fmt(Colors.green)],
            ["fish_color_redirection",      fmt(Colors.cyan)],
            ["fish_color_end",              fmt(Colors.magenta)],
            ["fish_color_error",            fmt(Colors.red)],
            ["fish_color_param",            fmt(Colors.overSurfaceVariant)],
            ["fish_color_comment",          fmt(Colors.outline)],
            ["fish_color_selection",        fmt(Colors.secondaryContainer)],
            ["fish_color_search_match",     fmt(Colors.primaryContainer)],
            ["fish_color_operator",         fmt(Colors.yellow)],
            ["fish_color_escape",           fmt(Colors.lightMagenta)],
            ["fish_color_autosuggestion",   fmt(Colors.outlineVariant)],
            ["fish_color_cancel",           fmt(Colors.error)],
            ["fish_color_cwd",              fmt(Colors.blue)],
            ["fish_color_cwd_root",         fmt(Colors.red)],
            ["fish_color_user",             fmt(Colors.green)],
            ["fish_color_host",             fmt(Colors.cyan)],
            ["fish_color_host_remote",      fmt(Colors.yellow)],
            ["fish_color_status",           fmt(Colors.red)],
            ["fish_color_valid_path",       "--underline"],
            ["fish_color_match",            fmt(Colors.lightCyan)],
            ["fish_color_history_current",  "--bold"],
            ["fish_pager_color_progress",   fmt(Colors.overSurfaceVariant)],
            ["fish_pager_color_background", fmt(Colors.surfaceContainerLow)],
            ["fish_pager_color_prefix",     fmt(Colors.primary)],
            ["fish_pager_color_completion", fmt(Colors.overSurface)],
            ["fish_pager_color_description",fmt(Colors.outline)],
            ["fish_pager_color_selected_background", fmt(Colors.secondaryContainer)],
            ["fish_pager_color_selected_prefix",     fmt(Colors.overSecondaryContainer)],
            ["fish_pager_color_selected_completion", fmt(Colors.overSecondaryContainer)],
            ["fish_pager_color_selected_description",fmt(Colors.overSecondaryContainer)],
        ];

        // Build a single fish command string:
        // 1. set -eg  — erase any global that shadows the universal
        // 2. set -U   — write the universal (persists in fish_variables, live in all sessions)
        let fishCmd = "";
        for (const [name, value] of fishVars) {
            const quoted = value.startsWith("--") ? value : `'${value}'`;
            fishCmd += `set -eg ${name} 2>/dev/null; set -U ${name} ${quoted}; `;
        }

        // Overwrite the conf.d stub so no leftover set -g lines re-shadow on startup
        const home = Quickshell.env("HOME");
        const fishConfDir = home + "/.config/fish/conf.d";
        const fishColorFile = fishConfDir + "/ambxst_colors.fish";

        const cmd = `
            mkdir -p '${fishConfDir}'
            printf '%s\\n' '# managed by ambxst FishGenerator — do not add set commands here' > '${fishColorFile}'
            fish -c ${JSON.stringify(fishCmd)}
        `;

        writerProcess.command = ["sh", "-c", cmd];
        writerProcess.running = true;
    }

    property Process writerProcess: Process {
        id: writerProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: console.log("FishGenerator: Colors applied as universals.")
        }
        stderr: StdioCollector {
            onStreamFinished: err => {
                if (err)
                    console.error("FishGenerator Error:", err);
            }
        }
    }
}

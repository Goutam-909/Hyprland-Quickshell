pragma Singleton

import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property bool active: false   // <-- new
    property list<int> values

    onActiveChanged: if (!active) values = []   // clear bars so they don't freeze mid-frame

    Process {
        running: root.active      // <-- was: true
        command: ["sh", "-c", `printf '[general]\nframerate=60\nbars=${Config.options.caelestiaDashboard.dashboard.visualiserBars}\n[output]\nchannels=mono\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=200' | cava -p /dev/stdin`]
        stdout: SplitParser {
            onRead: data => root.values = data.slice(0, -1).split(";").map(v => parseInt(v, 10))
        }
    }
}

import qs.modules.ii.dashboard2.utils
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property string name

    WlrLayershell.namespace: name
    color: "transparent"
}




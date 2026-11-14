// common/MaterialSymbol.qml
// Drop-in replacement: NO "Material Symbols" font needed any more.
// Every existing `MaterialSymbol { icon: "wifi" }` call keeps working, but the
// glyph now comes from modules/theme/Icons.qml (Phosphor-Bold) instead.
//
// You can also pass a Phosphor property name directly: icon: "gear"
// (anything not in the map and not an Icons property renders nothing, instead
// of dumping a literal word like "visibility" on screen).
import qs.modules.theme
import QtQuick

Text {
    id: symbolText

    property string icon: ""
    property int iconSize: 18

    font.family: Icons.font
    font.pixelSize: iconSize
    font.weight: Font.Normal
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    // material name  ->  Icons.<property>
    readonly property var iconMap: ({
        // Wi-Fi
        "wifi": "wifiHigh",
        "wifi_find": "wifiHigh",
        "wifi_off": "wifiOff",
        "android_wifi_4_bar": "wifiHigh",
        "android_wifi_4_bar_plus": "wifiNone",
        "android_wifi_4_bar_off": "wifiOff",
        "android_wifi_4_bar_lock": "wifiHigh",
        "android_wifi_3_bar": "wifiMedium",
        "android_wifi_3_bar_lock": "wifiMedium",
        "wifi_2_bar": "wifiMedium",
        "wifi_1_bar": "wifiLow",
        "network_wifi_1_bar": "wifiLow",
        "network_wifi_1_bar_locked": "wifiLow",
        "cell_tower": "signalNone",

        // Bluetooth
        "bluetooth": "bluetooth",
        "bluetooth_connected": "bluetoothConnected",
        "bluetooth_disabled": "bluetoothOff",
        "bluetooth_searching": "bluetooth",

        // Media
        "play_arrow": "play",
        "pause": "pause",
        "skip_next": "next",
        "skip_previous": "previous",
        "fast_forward": "forward",
        "fast_rewind": "rewind",
        "music_note": "player",
        "music_off": "player",
        "album": "player",
        "shuffle": "shuffle",
        "repeat": "repeat",
        "repeat_one": "repeatOnce",
        "graphic_eq": "waveform",

        // Audio
        "volume_up": "speakerHigh",
        "volume_down": "speakerLow",
        "volume_mute": "speakerNone",
        "volume_off": "speakerSlash",
        "mic": "mic",
        "mic_off": "micSlash",

        // Theme / display
        "light_mode": "sun",
        "wb_sunny": "sun",
        "dark_mode": "moon",
        "bedtime": "moon",
        "bedtime_off": "sunDim",
        "do_not_disturb_on": "bellSlash",

        // Actions
        "settings": "gear",
        "check": "accept",
        "done": "accept",
        "add": "plus",
        "close": "cancel",
        "chevron_right": "caretRight",
        "expand_more": "caretDown",
        "open_in_new": "arrowSquareOut",
        "autorenew": "sync",
        "visibility": "circle",
        "visibility_off": "circleHalf",
        "person": "user",
        "password": "lock",

        // Power
        "lock": "lock",
        "logout": "logout",
        "restart_alt": "reboot",
        "power_settings_new": "shutdown",

        // Screen
        "screenshot": "regionScreenshot",
        "screenshot_monitor": "fullScreenshot",
        "screen_share": "compositor",
        "desktop_windows": "compositor",
        "videocam": "recordScreen",
        "airplay": "speaker",

        // Time
        "schedule": "clock",
        "timer": "timer",

        // Bluetooth device types (Services.Bluetooth.getDeviceIcon)
        "headphones": "headphones",
        "smartphone": "phone",
        "keyboard": "keyboard",
        "mouse": "mouse",
        "computer": "terminalWindow",
        "watch": "watch",
        "speaker": "speaker",
        "sports_esports": "gamepad",

        "default": "circle"
    })

    text: {
        const key = iconMap[icon] !== undefined ? iconMap[icon] : icon
        const g = Icons[key]
        return (g !== undefined && g !== null) ? g : ""
    }

    renderType: Text.NativeRendering
    antialiasing: true
}

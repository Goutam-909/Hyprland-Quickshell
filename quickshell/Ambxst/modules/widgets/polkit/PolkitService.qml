pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit

Singleton {
    id: root

    property alias agent: polkitAgent
    property alias active: polkitAgent.isActive
    property alias flow: polkitAgent.flow
    property bool interactionAvailable: false

    // Pulses whenever a submitted answer was rejected, so the UI can shake + show a hint
    signal authFailed

    // Plays your system-wide XDG sound theme via libcanberra, so whatever
    // theme you have installed (freedesktop, ocean, etc.) is respected
    // automatically instead of shipping a fixed sound file.
    // Set soundEnabled to false to mute both.
    // Event IDs are from the freedesktop.org Sound Naming Spec:
    // https://specifications.freedesktop.org/sound-naming-spec/latest/
    property bool soundEnabled: true
    property string openSoundId: "dialog-warning"
    property string errorSoundId: "dialog-error"

    function playSound(soundId) {
        if (!root.soundEnabled || !soundId) return;
        soundProcess.command = ["canberra-gtk-play", "-i", soundId];
        soundProcess.running = true;
    }

    // Fire-and-forget; failures (e.g. libcanberra not installed) are silent,
    // they just mean no sound plays.
    Process {
        id: soundProcess
    }

    onActiveChanged: {
        if (root.active) root.playSound(root.openSoundId);
    }

    property string cleanMessage: {
        if (!root.flow) return "";
        return root.flow.message.endsWith(".")
            ? root.flow.message.slice(0, -1)
            : root.flow.message;
    }

    property string cleanPrompt: {
        const inputPrompt = root.flow?.inputPrompt?.trim() ?? "";
        const cleanedInputPrompt = inputPrompt.endsWith(":") ? inputPrompt.slice(0, -1) : inputPrompt;
        const usePasswordChars = !root.flow?.responseVisible ?? true;
        return cleanedInputPrompt || (usePasswordChars ? "Password" : "Input");
    }

    function cancel() {
        root.flow?.cancelAuthenticationRequest();
    }

    function submit(response) {
        root.flow?.submit(response);
        root.interactionAvailable = false;
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.interactionAvailable = true;
            root.authFailed();
            root.playSound(root.errorSoundId);
        }
    }

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            root.interactionAvailable = true;
        }
    }
}

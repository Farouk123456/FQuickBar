import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property var workspaces: []

    Process {
        id: get
        command: ["bash", "/home/farouk/Documents/QuickShell/getWorkspaces.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.workspaces = JSON.parse(this.text)
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: get.running = true
    }
}
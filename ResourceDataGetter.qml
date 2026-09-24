import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property var data: []

    Process {
        id: get
        command: ["bash", "/home/farouk/Documents/QuickShell/getResData.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.data = JSON.parse(this.text)
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: get.running = true
    }
}
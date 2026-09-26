import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property var data: []

    Process {
        id: get
        command: ["bash", "getDriveData.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.data = JSON.parse(this.text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: get.running = true
    }
}
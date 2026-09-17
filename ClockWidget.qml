pragma ComponentBehavior: Bound
import Quickshell.Io
import QtQuick

Text {
    required property color textColor
    required property string fontFamily
    required property int fontSize

    id: clock
    anchors.centerIn: parent
    font { family: fontFamily; pixelSize: fontSize }
    color: textColor
    
    Process {
        id: dateProc
        command: ["date", "+%A, %d %B %H:%M:%S"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: clock.text = this.text
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}
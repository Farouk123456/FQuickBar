import Quickshell
import Quickshell.Io
import QtQuick 

Variants {
    model: Quickshell.screens;
    delegate: Component {
        PanelWindow {
            id: root
            property color colBg: "#2a000000"
            property int reqHeight: 35
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 12
            required property var modelData

            screen: modelData
            color: "transparent"
            
            Rectangle {
                color: root.colBg
                radius: 15
                anchors.fill: parent
                border {
                    width: 2
                    color: "#c0c0c0"
                }
            }

            Rectangle {
                color: '#5ed7a1'
                implicitWidth: 15
                implicitHeight: 25
                x: 12.5
                y: 5
                radius: 4

                Text {
                    anchors.centerIn: parent
                    font { family: root.fontFamily; pixelSize: root.fontSize }
                    color: "#000"
                    text: "1"
                }
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: root.reqHeight

            margins {
                top: 2
                bottom: 2
                left: 10
                right: 10
            }

            Text {
                id: clock
                anchors.centerIn: parent
                font { family: root.fontFamily; pixelSize: root.fontSize }
                color: "#fff"
                
                Process {
                    id: dateProc
                    command: ["date", "+%A, %d %B %H:%M:%S"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: clock.text = this.text // `this` can be omitted
                    }
                }

                Timer {
                    interval: 500
                    running: true
                    repeat: true
                    onTriggered: dateProc.running = true
                }
            }
        }
    }
}
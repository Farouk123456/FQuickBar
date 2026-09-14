//@ pragma UseQApplication
//@ pragma IconTheme candy-icons
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Hyprland
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
            property int activeWS: 1

            screen: modelData
            color: "transparent"
            
            Rectangle {
                color: root.colBg
                radius: root.reqHeight / 2
                anchors.fill: parent
                border {
                    width: 2
                    color: "#c0c0c0"
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


            // Workspace Widget
            Repeater {
                id: rep
                model: ScriptModel {
                    id: ff
                    values: JSON.parse("[{\"key\":\"2\",\"name\":\"2\",\"monitor\":1},{\"key\":\"3\",\"name\":\"3\",\"monitor\":1}]");
                }

                delegate:  Rectangle {
                    id: ws
                    required property var modelData
                    required property int index

                    color: (msArea.containsMouse) ? (ws.modelData.key == root.activeWS) ?  '#3eb781' : "#a0a0a0" : (ws.modelData.key == root.activeWS) ? '#5ed7a1' : "#c0c0c0"
                    implicitWidth: 15
                    implicitHeight: 25
                    
                    x: 12.5 + 18 * index
                    y: 5
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        font { family: root.fontFamily; pixelSize: root.fontSize }
                        color: "#000"
                        text: ws.modelData.name
                    }

                    MouseArea {
                        id: msArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onPressed: {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws.modelData.key + " })")
                        }

                        onWheel: {
                            if (wheel.angleDelta.y > 0) {
                               Hyprland.dispatch("hl.dsp.focus({ workspace = \"e+1\" })")
                            } else if (wheel.angleDelta.y < 0) {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = \"e-1\" })")
                            }
                        }
                    }
                }
            }
            
            // Polls for Workspacewidget
            Process {
                id: get
                command: ["bash", "/home/farouk/Documents/QuickShell/getWorkspaces.sh"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: ff.values = JSON.parse(this.text)
                }
            }

            Timer {
                interval: 100
                running: true
                repeat: true
                onTriggered: get.running = true
            }

            Process {
                id: getAWS
                command: ["bash", "/home/farouk/Documents/QuickShell/getActiveWS.sh"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: root.activeWS = this.text
                }
            }

            Timer {
                interval: 100
                running: true
                repeat: true
                onTriggered: getAWS.running = true
            }



            // Date Clock
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
        
            Row {
                Repeater {
                    model: SystemTray.items

                    delegate: Image {
                        id: img
                        required property var modelData
                        required property int index

                        source: modelData.icon

                        height: 25
                        fillMode: Image.PreserveAspectFit
                        
                        QsMenuAnchor {
                            id: menuAnchor
                            menu: img.modelData.menu
                            anchor {
                                item: img                          // anchor to the icon, not the cursor
                                edges: Edges.Bottom | Edges.Right    // anchor point = icon's bottom-left corner
                                gravity: Edges.Bottom | Edges.Left // menu grows down+right from that point
                                adjustment: PopupAdjustment.Slide   // slide (not flip) if it'd go offscreen
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button == Qt.RightButton) 
                                {
                                    menuAnchor.anchor.rect.x = mouse.x
                                    menuAnchor.anchor.rect.y = mouse.y
                                    menuAnchor.open()
                                }
                                else
                                {
                                    img.modelData.activate()
                                }
                            }
                        }
                    }
                }
                
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 12.5
            }
        }
    }
}
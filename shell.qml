//@ pragma UseQApplication
//@ pragma IconTheme candy-icons
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick 
import QtQuick.Controls 
import Quickshell.Wayland


Variants {
    model: Quickshell.screens;
    delegate: Component {
        Scope {
            id: scope
            required property var modelData

            property bool slideoutShown: false
            property real cursorX: -9999
            property real cursorY: -9999

            readonly property real barLeft: root.screen ? root.screen.x : 0
            readonly property real barTop: root.screen ? root.screen.y : 0
            readonly property real barWidth: root.screen ? root.screen.width : 0
            readonly property real barHeight: root.reqHeight + 4

            readonly property real slideoutWidth: 0.66 * barWidth
            readonly property real slideoutLeft: barLeft + (barWidth - slideoutWidth) / 2
            readonly property real slideoutTop: barTop + barHeight
            readonly property real slideoutHeight: slideout.panelHeight + 2

            function pointInRect(px, py, rx, ry, rw, rh) {
                return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh
            }

            function recomputeHover() {
                const inBar = pointInRect(cursorX, cursorY, barLeft, barTop, barWidth, barHeight)
                const inSlideout = pointInRect(cursorX, cursorY, slideoutLeft, slideoutTop, slideoutWidth, slideoutHeight)
                const inText = (barLeft+barWidth*0.5 - clock.width * 0.5 <= cursorX && cursorX <= barLeft+barWidth*0.5 + clock.width * 0.5)
                slideoutShown = ((inBar || inSlideout) && slideoutShown) || (inText && inBar)
            }

            // Poll the global cursor position. This is compositor-driven
            // ground truth, so it sidesteps the enter/leave race between
            // two separate layer-shell surfaces entirely.
            Process {
                id: cursorPoll
                command: ["hyprctl", "cursorpos"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        // hyprctl cursorpos prints "x, y"
                        const parts = this.text.trim().split(",")
                        if (parts.length === 2) {
                            scope.cursorX = parseFloat(parts[0])
                            scope.cursorY = parseFloat(parts[1])
                            scope.recomputeHover()
                        }
                    }
                }
            }

            Timer {
                interval: 10
                running: true
                repeat: true
                onTriggered: cursorPoll.running = true
            }

            // Slideout window
            PanelWindow {
                id: slideout
                property int panelHeight: 260

                screen: scope.modelData
                color: "transparent"

                exclusiveZone: 0

                anchors {
                    top: true
                }

                implicitHeight: panelHeight
                implicitWidth: scope.slideoutWidth

                margins {
                    top: scope.slideoutShown ? 2 : -panelHeight - scope.barHeight - 5
                }
                

                Behavior on margins.top {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#2a000000"
                    border { width: 2; color: "#c0c0c0" }

                    Label {
                        anchors.centerIn: parent
                        text: "Content goes here!"
                        color: "#fff"
                    }

                    OpacityAnimator on opacity{
                        from: 0;
                        to: 1;
                        duration: 200
                        easing.type: Easing.InCubic
                        running: scope.slideoutShown 
                    }

                    OpacityAnimator on opacity{
                        from: 1;
                        to: 0;
                        duration: 200
                        easing.type: Easing.InCubic
                        running: !scope.slideoutShown 
                    }
                }
            }

            PanelWindow {
                id: root
                property color colBg: "#2a000000"
                property int reqHeight: 35
                property string fontFamily: "JetBrainsMono Nerd Font"
                property int fontSize: 12
                property int activeWS: 1

                screen: scope.modelData
                color: "transparent"

                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: scope.barHeight

                Rectangle {
                    color: root.colBg
                    radius: root.reqHeight / 2
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    border {
                        width: 2
                        color: "#c0c0c0"
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
                                        item: img
                                        edges: Edges.Bottom | Edges.Right
                                        gravity: Edges.Bottom | Edges.Left
                                        adjustment: PopupAdjustment.Slide
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
            }
        }
    }
}
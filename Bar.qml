pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Controls

// TODO: make slideout widgets use acctual data fix their positioning make beter color interpolation add mediaplayer thingy or smth and put the widgets into their own files

Scope {
    WorkspacesDataGetter { id: wkData }

    Variants {
        model: Quickshell.screens;

        Scope {
            id: scope
            required property var modelData

            readonly property real barLeft: modelData ? modelData.x : 0
            readonly property real barTop: modelData ? modelData.y : 0
            readonly property real barWidth: modelData ? modelData.width : 0
            readonly property real barHeight: reqHeight + 4
            readonly property real slideoutWidth: 0.66 * barWidth
            readonly property real slideoutLeft: barLeft + (barWidth - slideoutWidth) / 2
            readonly property real slideoutTop: barTop + barHeight
            readonly property real slideoutHeight: slideout.panelHeight + 2
            
            readonly property color colBg: "#2a000000"
            readonly property int reqHeight: 35
            readonly property string fontFamily: "JetBrainsMono Nerd Font"
            readonly property int fontSize: 12
                

            MouseWatcher {
                id: mouseW
                barLeft: scope.barLeft
                barTop: scope.barTop
                barWidth: scope.barWidth
                barHeight: scope.barHeight
                panelLeft: scope.slideoutLeft
                panelTop: scope.slideoutTop
                panelWidth: scope.slideoutWidth
                panelHeight: scope.slideoutHeight
                clockWidth: clock.width
                volWidget: vw
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
                    top: mouseW.slideoutShown ? 2 : -panelHeight - scope.barHeight - 5
                }
                

                Behavior on margins.top {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#2a000000"
                    border { width: 2; color: "#c0c0c0" }

                    OpacityAnimator on opacity{
                        from: 0;
                        to: 1;
                        duration: 200
                        easing.type: Easing.InCubic
                        running: mouseW.slideoutShown 
                    }

                    OpacityAnimator on opacity{
                        from: 1;
                        to: 0;
                        duration: 200
                        easing.type: Easing.InCubic
                        running: !mouseW.slideoutShown 
                    }

                    CircleBarWidget {
                        id: cpu
                        width: 150
                        height: 150
                        value: 0.1
                        lineWidth: 15
                        primaryColor: Qt.hsva(Math.pow(1 - this.value, 2) * 204 / 360, 0.83, 1)
                        secondaryColor: "#15e0e0e0"
                        textColor: "#fff"
                        fontFamily: scope.fontFamily
                        fontSize: scope.fontSize * 1.75
                        text: "CPU " + Math.round(cpu.value * 100) + "%"
                        x: 370
                        y: (slideout.height - this.height) / 4

                        Text {
                            text: " 65°C"
                            x: (cpu.width  - this.width) / 2 
                            y: 3 * (slideout.height - this.height) / 4
                            color: "#fff"
                            font.family: scope.fontFamily
                            font.pixelSize: scope.fontSize * 1.75
                        }
                    }

                    CircleBarWidget {
                        id: ram
                        width: 150
                        height: 150
                        value: 0.4
                        lineWidth: 15
                        primaryColor: Qt.hsva(Math.pow(1 - this.value, 2) * 204 / 360, 0.83, 1)
                        secondaryColor: "#15e0e0e0"
                        textColor: "#fff"
                        fontFamily: scope.fontFamily
                        fontSize: scope.fontSize * 1.75
                        text: "RAM " + Math.round(cpu.value * 100) + "%"
                        x: cpu.x + 180
                        y: (slideout.height - this.height) / 4

                        Text {
                            text: "16.4 / 32 GB"
                            x: (cpu.width  - this.width) / 2 
                            y: 3 * (slideout.height - this.height) / 4
                            color: "#fff"
                            font.family: scope.fontFamily
                            font.pixelSize: scope.fontSize * 1.75
                        }
                    }

                    CircleBarWidget {
                        id: gpu
                        width: 150
                        height: 150
                        value: 0.01
                        lineWidth: 15
                        primaryColor: Qt.hsva(Math.pow(1 - this.value, 2) * 204 / 360, 0.83, 1)
                        secondaryColor: "#15e0e0e0"
                        textColor: "#fff"
                        fontFamily: scope.fontFamily
                        fontSize: scope.fontSize * 1.75
                        text: "GPU " + Math.round(cpu.value * 100) + "%"
                        x: ram.x + 180
                        y: (slideout.height - this.height) / 4

                        Text {
                            text: " 43°C"
                            x: (cpu.width  - this.width) / 2 
                            y: 3 * (slideout.height - this.height) / 4
                            color: "#fff"
                            font.family: scope.fontFamily
                            font.pixelSize: scope.fontSize * 1.75
                        }
                    }

                    Repeater {
                        id: drive
                        model: [
  {
    "Filesystem": "/dev/nvme0n1p3",
    "Type": "ext4",
    "Size": "911G",
    "Used": "367G",
    "Avail": "501G",
    "Use%": "43%",
    "Mounted": "/"
  },
  {
    "Filesystem": "/dev/sda1",
    "Type": "ext4",
    "Size": "229G",
    "Used": "144G",
    "Avail": "73G",
    "Use%": "67%",
    "Mounted": "/mnt/Backup"
  },
  {
    "Filesystem": "/dev/sdc1",
    "Type": "ext4",
    "Size": "469G",
    "Used": "246G",
    "Avail": "200G",
    "Use%": "56%",
    "Mounted": "/mnt/Back"
  }]
                        delegate: ProgressBar {
                            required property var modelData
                            required property int index

                            id: control
                            value: parseInt(modelData["Use%"]) / 100
                            x: scope.slideoutWidth - 300 - gpu.y
                            y: gpu.y + ((slideout.panelHeight - gpu.y) / drive.count) * index
                            
                            
                            height: scope.reqHeight * 0.2
                            width: 300
                            
                            background: Rectangle {
                                color: "#15e0e0e0"
                                radius: parent.height / 2
                            }

                            contentItem: Item { Rectangle {
                                color: '#2099d0'
                                radius: parent.height / 2
                                width: control.visualPosition * parent.width
                                height: parent.height
                            }}

                            Text {
                                text: parent.modelData.Filesystem
                                color: "#fff"
                                y: 15
                            }

                            Text {
                                text: parent.modelData.Used + " / " + parent.modelData.Size
                                color: "#fff"
                                y: 15
                                x: 300 - this.width - 5
                            }
                        }
                    }
                }
            }

            PanelWindow {
                screen: scope.modelData
                color: "transparent"

                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: scope.barHeight

                Rectangle {
                    color: scope.colBg
                    radius: scope.reqHeight / 2
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10

                    border {
                        width: 2
                        color: "#c0c0c0"
                    }

                    WorkspaceWidget {
                        id: wk
                        fontSize: scope.fontSize
                        fontFamily: scope.fontFamily
                        workspaces: wkData.workspaces
                    }

                    VolumeWidget {
                        id: vw
                        wk: wk
                        reqHeight: scope.reqHeight
                        fontSize: scope.fontSize
                        fontFamily: scope.fontFamily
                        show: mouseW.volumeBarShown
                    }

                    ClockWidget {
                        id: clock
                        textColor: "#fff"
                        fontFamily: scope.fontFamily
                        fontSize: scope.fontSize
                    }

                    SysTrayWidget { }
                }
            }
        }
    }
}
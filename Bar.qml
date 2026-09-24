pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Controls

// TODO: fix their positioning make beter color interpolation add mediaplayer thingy or smth

Scope {
    WorkspacesDataGetter { id: wkData }
    DriveDataGetter { id: driveData }
    ResourceDataGetter { id: resData }

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

                    ResourceWidget {
                        id: res
                        fontSize: scope.fontSize
                        fontFamily: scope.fontFamily
                        height: slideout.height
                        y: (slideout.height - 150) / 4
                        resData: resData.data
                    }

                    StorageWidget
                    {
                        driveData: driveData.data
                        progBarHeight: scope.reqHeight * 0.2
                        implicitHeight: slideout.panelHeight - this.y
                        y: res.y
                        x: slideout.width - res.y
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
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5

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
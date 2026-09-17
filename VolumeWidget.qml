pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick 
import QtQuick.Controls


Item {
    id: root

    required property int reqHeight
    required property string fontFamily
    required property int fontSize
    required property WorkspaceWidget wk
    required property bool show

    property real vol_img_x: vol_img.x
    property real vol_img_w: vol_img.width
    property real vol_txt_w: vol_txt.width

    function setBarW(w)
    {
        volbar.width = w
    }

    property int leftmargin: 10
    property int spacing: 5
    property int barW: 200

    Image {
        id: vol_img
        x: (root.wk.count == 0) ? 0 : root.wk.itemAt(root.wk.count-1).x + root.wk.itemAt(root.wk.count-1).width + root.leftmargin 
        y: (root.reqHeight - this.height) / 2
        height: root.fontSize * 1.25
        fillMode: Image.PreserveAspectFit
        source: "./Speaker_Icon.svg"

        MouseArea {
            anchors.fill: parent
            onPressed: {
                Quickshell.execDetached("pavucontrol")    
            }
        }
    }

    Text {
        id: vol_txt
        x: vol_img.x + vol_img.width + root.spacing
        y: (root.reqHeight - this.height) / 2
        font { family: root.fontFamily; pixelSize: root.fontSize * 1 }
        color: "#fff"
        text: (Pipewire.defaultAudioSink.audio.muted) ? 0 : vol.value
        

        MouseArea {
            anchors.fill: parent
            onPressed: Quickshell.execDetached("pavucontrol")
        }
    }

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    Slider
    {
        id: vol
        x: vol_txt.x + vol_txt.width + root.spacing * 2
        y: (root.reqHeight - volbar.height) / 2 
        
        from: 0
        to: 100
        stepSize: 1
        value: (Pipewire.defaultAudioSink.audio.muted) ? 0 : Math.round(Pipewire.defaultAudioSink.audio.volume * 100)


        Connections {
            target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
            function onVolumeChanged() {
                if (!vol.pressed)
                    vol.value = (Pipewire.defaultAudioSink.audio.muted) ? 0 : Math.round(Pipewire.defaultAudioSink.audio.volume * 100)
            }
        }

        background: Rectangle {
            id: volbar
            height: root.reqHeight * 0.2
            implicitWidth: root.barW
            radius: height / 2
            color: '#5d2000'
            
            Rectangle {
                width: vol.visualPosition * parent.width
                height: parent.height
                color: '#e7281e'
                radius: parent.radius
            }

            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.InCubic }
            }

            Component.onCompleted: {
                volbar.width = 0
            }
        }

        Timer {
            id: throttle
            property real pendingValue: vol.value
            property real lastSent: -1
            interval: 100 
            running: true
            repeat: true
            onTriggered: {
                if (pendingValue !== lastSent && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.ready) {
                    Pipewire.defaultAudioSink.audio.volume = pendingValue / 100
                    lastSent = pendingValue
                }
            }
        }

        handle.visible: false
        onMoved: throttle.pendingValue = vol.value
        wheelEnabled: true
    }
}
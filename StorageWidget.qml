pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Repeater {
    id: drive

    required property real progBarHeight
    required property var driveData

    model: driveData

    delegate: ProgressBar {
        required property var modelData
        required property int index

        id: control
        value: parseInt(modelData["Use%"]) / 100
        
        y: drive.y + (drive.height / drive.count) * index 
        x: drive.x - this.width

        height: drive.progBarHeight
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
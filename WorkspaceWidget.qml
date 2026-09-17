pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import QtQuick

Repeater {
    id: root
    property int activeWS: Hyprland.focusedWorkspace.name
    
    required property string fontFamily
    required property int fontSize
    required property var workspaces
    
    property int wkWidth: 15
    property int wkHeight: 25
    property real leftmargin: 12.5
    property int spacing: 3
    property int topMargin: 5
    property color activeWScol: "#3eb781"
    property color activeWSHovercol: "#5ed7a1"
    property color wsCol: "#c0c0c0"
    property color wsHovercol: "#a0a0a0"

    model: ScriptModel {
        id: workspaceData
        values: root.workspaces
    }

    delegate:  Rectangle {
        id: ws
        required property var modelData
        required property int index

        color: (msArea.containsMouse) ? (ws.modelData.key == root.activeWS) ? root.activeWScol : root.wsHovercol : (ws.modelData.key == root.activeWS) ? root.activeWSHovercol : root.wsCol
        implicitWidth: root.wkWidth
        implicitHeight: root.wkHeight
        
        x: root.leftmargin + (root.wkWidth + root.spacing) * index
        y: root.topMargin
        radius: root.wkWidth / 3

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

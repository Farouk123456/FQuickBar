pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

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
//@ pragma UseQApplication
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Scope {
    Bar {}

    
    /*FloatingWindow {
        title: "Running Apps"
        maximumSize: "600x400"
        minimumSize: this.maximumSize

        ListView {
            anchors.fill: parent
            model: Hyprland.toplevels  // ObjectModel<HyprlandToplevel>

            delegate: Row {
                width: parent.width
                spacing: 8

                // The raw IPC JSON has "class" (WM_CLASS) and "initialClass"
                property string cls: modelData.wayland.appId

                // Try to match to a desktop entry for icon + name
                property var entry: DesktopEntries.byId(cls)

                IconImage {
                    source: entry ? Quickshell.iconPath(entry.icon) : ""
                    implicitSize: 24
                }
                Text {
                    text: entry ? entry.name : "b"
                    elide: Text.ElideRight
                }
            }
        }
    }*/
    
}
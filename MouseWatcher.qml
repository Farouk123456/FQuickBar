pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    required property real barLeft
    required property real barTop
    required property real barWidth
    required property real barHeight
    
    required property real panelLeft
    required property real panelTop
    required property real panelWidth
    required property real panelHeight
    required property real clockWidth
    required property VolumeWidget volWidget

    property bool slideoutShown: false
    property bool volumeBarShown: false
    property real cursorX: -9999
    property real cursorY: -9999

    function pointInRect(px, py, rx, ry, rw, rh) {
        return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh
    }

    function recomputeHover() {
        const inBar = pointInRect(cursorX, cursorY, barLeft, barTop, barWidth, barHeight)
        const inSlideout = pointInRect(cursorX, cursorY, panelLeft, panelTop, panelWidth, panelHeight)
        const inText = (barLeft+barWidth*0.5 - clockWidth * 0.5 <= cursorX && cursorX <= barLeft+barWidth*0.5 + clockWidth * 0.5 && cursorY <= 2)
        slideoutShown = ((inBar || inSlideout) && slideoutShown) || (inText)
    }

    function recomputeHoverVol() {
        const inVol = pointInRect(cursorX, cursorY, barLeft + volWidget.vol_img_x + 10, barTop, volWidget.vol_img_w + volWidget.vol_txt_w + 5, barHeight)
        const inVolandBar = pointInRect(cursorX, cursorY, barLeft + volWidget.vol_img_x + 10, barTop, 200 + volWidget.vol_img_w + volWidget.vol_txt_w + 15, barHeight)
        volumeBarShown = inVol || (volumeBarShown && inVolandBar)
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
                    root.cursorX = parseFloat(parts[0])
                    root.cursorY = parseFloat(parts[1])
                    root.recomputeHover()
                    root.recomputeHoverVol()

                    if (root.volumeBarShown)
                    {
                        root.volWidget.setBarW(200)
                    } else
                    {
                        root.volWidget.setBarW(0)
                    }
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
}
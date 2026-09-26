import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import QtQuick.Controls


Column {
    id: mp
    spacing: 30

    property var modelData: Mpris.players.values[0]

    Row {
        spacing: 10

        Image {
            Rectangle {
                color: "#6f000000"
                anchors.fill: parent
                z: -1
            }

            Rectangle {
                id: hvrRect
                color: "#8f000000"
                anchors.fill: parent
                visible: false

                Text {
                    id: playback
                    color: "#fff"
                    text: (mp.modelData.playbackState == MprisPlaybackState.Playing) ? "⏸" : "▶" 
                    anchors.centerIn: parent
                    font.pixelSize: (mp.modelData.playbackState == MprisPlaybackState.Playing) ? 25 : 25
                    font.family: "JetBrains Mono ExtraBold";
                
                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            mp.modelData.togglePlaying()
                            if (mp.modelData.playbackState == MprisPlaybackState.Playing) {
                                playback.text = "▶" 
                                playback.font.pixelSize = 30
                            } else {
                                playback.text = "⏸" 
                                playback.font.pixelSize = 25    
                            }
                        }
                    }
                }

                Text {
                    id: goback
                    color: "#fff"
                    text: "⏮"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 25
                    font.family: "JetBrains Mono ExtraBold";

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            mp.modelData.previous()
                        }
                    }
                }

                Text {
                    id: skip
                    color: "#fff"
                    text: "⏭"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 25
                    font.family: "JetBrains Mono ExtraBold";
                
                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            mp.modelData.next()
                        }
                    }
                }
            }

            source: mp.modelData?.trackArtUrl || ""
            sourceSize: Qt.size(120,120)
            fillMode: Image.FillMode.Pad
            height: 120
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    hvrRect.visible = true
                }
                
                onExited: {
                    hvrRect.visible = false 
                }
            }
        }
        
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Rectangle {
                id: container
                width: 200; height: 25
                clip: true // Ensures text is hidden when outside bounds
                color: "transparent"

                Text {
                    id: scrollingText
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#fff"; font.family: "JetBrains Mono ExtraBold"; text: mp.modelData?.trackTitle || "No Track"; width: 200;
                    
                    // Dynamic duration based on width and speed (e.g., 100 pixels/sec)
                    NumberAnimation on x {
                        from: container.width
                        to: -scrollingText.paintedWidth
                        duration: (container.width + scrollingText.paintedWidth) * 1000 / 100
                        loops: Animation.Infinite
                        running: scrollingText.paintedWidth > 200

                        onRunningChanged: {
                            if (!running) {
                                scrollingText.x = 0
                            }
                        }
                    }
                }
            }   
            //Text { color: "#fff"; font.family: "JetBrains Mono ExtraBold"; text: mp.modelData?.trackTitle || "No Track"; width: 200; elide: Text.ElideRight }
            Text { color: "#fff"; font.family: "JetBrains Mono SemiBold"; text: mp.modelData?.trackArtist || "Unknown Artist"; width: 200; elide: Text.ElideRight }
            Text { color: "#fff"; font.family: "JetBrains Mono Light"; text: mp.modelData?.trackAlbum || "Unknown Artist"; width: 200; elide: Text.ElideRight }
        }

        // Add buttons for play/pause, next, etc.

    }

    ProgressBar {
        id: control

        function formatSecondsToMSS(totalSeconds) {
            const minutes = Math.floor(totalSeconds / 60);
            const seconds = totalSeconds % 60;
            return `${String(minutes).padStart(1, '0')}:${String(seconds).padStart(2, '0')}`;
        }

        value: mp.modelData.position / mp.modelData.length

        height: 10
        width: 330
        
        background: Rectangle {
            color: "#25e0e0e0"
            radius: parent.height / 2
        }

        contentItem: Item { Rectangle {
            color: '#2099d0'
            radius: parent.height / 2
            width: control.visualPosition * parent.width
            height: parent.height
        }}

        Text {
            text: mp.modelData.positionSupported ? control.formatSecondsToMSS(Math.floor(mp.modelData.position)) : "--:--"
            color: "#fff"
            y: 15
            font.family: "JetBrains Mono Light";

            FrameAnimation {
                // only emit the signal when the position is actually changing.
                running: mp.modelData.playbackState == MprisPlaybackState.Playing
                // emit the positionChanged signal every frame.
                onTriggered: mp.modelData.positionChanged()
            }
        }

        Text {
            text: control.formatSecondsToMSS(Math.floor(mp.modelData.length))
            color: "#fff"
            y: 15
            x: control.width - this.width
            font.family: "JetBrains Mono Light";
        }
    }
}

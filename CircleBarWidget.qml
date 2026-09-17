pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

Item {
    id: cc

    required property real value
    required property int lineWidth
    required property color primaryColor
    required property color secondaryColor
    required property color textColor
    required property string fontFamily
    required property int fontSize
    required property string text

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            var x = width / 2;
            var y = height / 2;
            var radius = width / 2 - cc.lineWidth / 2;
            var startAngle = (Math.PI / 180) * 270;
            var progressAngle = startAngle + (Math.PI * 2 * cc.value);

            ctx.reset();
            ctx.lineWidth = cc.lineWidth;
            ctx.lineCap = 'round';

            // Background circle
            ctx.beginPath();
            ctx.arc(x, y, radius, startAngle, startAngle + (Math.PI * 2));
            ctx.strokeStyle = cc.secondaryColor;
            ctx.stroke();

            // Progress arc
            ctx.beginPath();
            ctx.arc(x, y, radius, startAngle, progressAngle);
            ctx.strokeStyle = cc.primaryColor;
            ctx.stroke();
        }

        Text {
            anchors.centerIn: parent
            text: cc.text
            color: cc.textColor
            font.family: cc.fontFamily
            font.pixelSize: cc.fontSize
        }
    }

    onValueChanged: canvas.requestPaint();
    
    // Animate value changes
    Behavior on value {
        NumberAnimation {
            duration: 500
            easing.type: Easing.InOutCubic
        }
    }
}
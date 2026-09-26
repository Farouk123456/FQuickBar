import QtQuick
                    
Item {
    id: scope
    required property string fontFamily
    required property int fontSize
    required property var resData

    CircleBarWidget {
        id: cpu
        width: 150
        height: 150
        value: scope.resData.cpu.usage / 100
        lineWidth: 15
        primaryColor: Qt.hsva(Math.pow(1 - this.value, 2) * 204 / 360, 0.83, 1)
        secondaryColor: "#25e0e0e0"
        textColor: "#fff"
        fontFamily: scope.fontFamily
        fontSize: scope.fontSize * 1.75
        text: "CPU " + Math.round(cpu.value * 100) + "%"
        

        Text {
            text: " " + Math.round(scope.resData.cpu.temp) + "°C"
            x: (cpu.width  - this.width) / 2 
            y: 3 * (scope.height - this.height) / 4
            color: "#fff"
            font.family: scope.fontFamily
            font.pixelSize: scope.fontSize * 1.75
        }
    }

    CircleBarWidget {
        id: ram
        width: 150
        height: 150
        value: scope.resData.ram.usage / 100
        lineWidth: 15
        primaryColor: Qt.hsva(Math.pow(1 - this.value, 2) * 204 / 360, 0.83, 1)
        secondaryColor: "#25e0e0e0"
        textColor: "#fff"
        fontFamily: scope.fontFamily
        fontSize: scope.fontSize * 1.75
        text: "RAM " + Math.round(ram.value * 100) + "%"
        x: cpu.x + 180

        Text {
            text: (scope.resData.ram.used_mb / 1000).toFixed(2) + " / " +  Math.round(scope.resData.ram.total_mb / 1000) + " GB"
            x: (cpu.width  - this.width) / 2 
            y: 3 * (scope.height - this.height) / 4
            color: "#fff"
            font.family: scope.fontFamily
            font.pixelSize: scope.fontSize * 1.75
        }
    }

    CircleBarWidget {
        id: gpu
        width: 150
        height: 150
        value: scope.resData.gpu[0].usage / 100
        lineWidth: 15
        primaryColor: Qt.hsva(Math.pow(1 - this.value, 2) * 204 / 360, 0.83, 1)
        secondaryColor: "#25e0e0e0"
        textColor: "#fff"
        fontFamily: scope.fontFamily
        fontSize: scope.fontSize * 1.75
        text: "GPU " + Math.round(gpu.value * 100) + "%"
        x: ram.x + 180

        Text {
            text: " " + Math.round(scope.resData.gpu[0].temp) + "°C"
            x: (cpu.width  - this.width) / 2 
            y: 3 * (scope.height - this.height) / 4
            color: "#fff"
            font.family: scope.fontFamily
            font.pixelSize: scope.fontSize * 1.75
        }
    }
}
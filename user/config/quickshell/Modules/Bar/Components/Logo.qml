import QtQuick
import QtQuick.Layouts
import qs.Services

Item {
    id: root
    Layout.alignment: Qt.AlignHCenter
    width: logo.implicitWidth
    height: logo.implicitHeight

    Text {
        id: logo
        anchors.centerIn: parent

        font {
            family: bar.fontFamily
            pixelSize: bar.fontSize * 2
        }

        text: ""
        color: bar.colMuted
        transformOrigin: Item.Center
    }

    ParallelAnimation {
        id: activeAnim
        running: Niri.activeScreen === bar.screen.name
        loops: Animation.Infinite

        SequentialAnimation {
            ColorAnimation { target: logo; property: "color"; to: bar.colMuted; duration: 900 }
            ColorAnimation { target: logo; property: "color"; to: bar.colYellow; duration: 900 }
	    PauseAnimation { duration: 500 }
        }

        NumberAnimation {
            target: logo
            property: "rotation"
            from: 0
            to: 360
            duration: 3600
        }

        onRunningChanged: {
            if (!running) {
                logo.color = bar.colMuted
                logo.rotation = 0
            }
        }
    }
}

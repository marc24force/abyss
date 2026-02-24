import QtQuick
import QtQuick.Layouts

Text {
	id: clock
	color: bar.colYellow
	font { family: bar.fontFamily; pixelSize: bar.fontSize * 1.5; bold: true }
	Layout.alignment: Qt.AlignCenter

	function updateTime() {
		const d = new Date()
		text = Qt.formatTime(d, "HH") + "\n" + Qt.formatTime(d, "mm")
	}


	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: updateTime()
	}

	Component.onCompleted: updateTime()

	lineHeight: 0.8  // adjust to reduce spacing


}


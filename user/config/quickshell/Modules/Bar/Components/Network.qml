import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Text {
	id: network
	Layout.alignment: Qt.AlignCenter
	leftPadding: 2

	font { family: bar.fontFamily; pixelSize: bar.fontSize * 1.5}

	property color colorDanger:  "#ed8796"
	property color colorNormal:  "#a9b1d6"

	property int updateInterval: 5000

	// Network state
	property bool ethernetUp: false
	property int wifiRssi: 0

	// Check Ethernet

	// Check WiFi RSSI for any station
	Process {
		id: checkWifi
		command: ["bash","-c","iwctl station $(iwctl station list | head -n 5 | tail -n 1 | awk '{print $2}') show | grep -E 'RSSI | disconnected' | awk '{print $2}'"]
		running: true
		stdout: SplitParser {
			onRead: data => {
				if (!data) return
				wifiRssi = parseInt(data.trim())
			}
		}
	}

	Timer {
		interval: updateInterval
		running: true
		repeat: true
		onTriggered: {
			checkWifi.running = true
		}
	}

	readonly property string icon: {
		if (ethernetUp)     return ""
		if (wifiRssi === 0) return "󰤮"
		if (wifiRssi > -50) return "󰤨"
		if (wifiRssi > -60) return "󰤥"
		if (wifiRssi > -70) return "󰤢"
		if (wifiRssi > -80) return "󰤟"
		return "󰤯"
	}

	color: { 
		if (wifiRssi === 0) return colorDanger
		return colorNormal
	}
	
	text: icon
	visible: true
}


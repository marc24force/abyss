import QtQuick
import Quickshell
import Quickshell.Io

Text {
	id: battery
	anchors.horizontalCenter: parent.horizontalCenter
	font { family: bar.fontFamily; pixelSize: bar.fontSize}

	property int updateInterval: 30000

	property color colorDanger:  "#ed8796"
	property color colorWarning: "#f5a97f"
	property color colorGood:    "#8bd5a0"
	property color colorNormal:  "#a9b1d6"

	property int thresholdDanger: 15
	property int thresholdWarning: 30
	property int thresholdGood: 80

	property int dangerInterval: 3000
	property int warningInterval: 7000
	property int normalInterval: 25000
	property int textInterval: 3000

	property bool hasBattery: false

	Process {
		id: exists
		command: ["bash","-c","test -d /sys/class/power_supply/BAT0 && echo 1 || echo 0"]
		running: true
		stdout: SplitParser {
			onRead: data => {
				if (!data) return
				hasBattery = data.trim() === "1"
			}
		}
	}

	property int capacity: 0

	Process {
		id: getCapacity
		command: ["bash","-c","cat /sys/class/power_supply/BAT0/capacity 2>/dev/null"]
		running: hasBattery
		stdout: SplitParser {
			onRead: data => {
				if (!data) return
				capacity = parseInt(data.trim())
			}
		}
	}

	property bool charging: false

	Process {
		id: getStatus
		command: ["bash","-c","cat /sys/class/power_supply/BAT0/status 2>/dev/null"]
		running: hasBattery
		stdout: SplitParser {
			onRead: data => {
				if (!data) return
				charging = data.trim() === "Charging"
			}
		}
	}

	Timer {
		interval: updateInterval
		running: hasBattery
		repeat: true
		onTriggered: {
			getStatus.running = true
			getCapacity.running = true

		}
	}

	property bool showIcon: true

	SequentialAnimation {
		id: flashIcon
		running: hasBattery
		loops: Animation.Infinite

		// Show text for textInterval
		NumberAnimation { target: battery; property: "opacity"; to: 0; duration: 300 }
		ScriptAction { script: battery.showIcon = false }
		NumberAnimation { target: battery; property: "opacity"; to: 1; duration: 300 }
		PauseAnimation { duration: textInterval }

		// Go back to icon
		NumberAnimation { target: battery; property: "opacity"; to: 0; duration: 300 }
		ScriptAction { script: battery.showIcon = true }
		NumberAnimation { target: battery; property: "opacity"; to: 1; duration: 300 }
		PauseAnimation { duration: {
			if (capacity <= thresholdDanger) return dangerInterval
			if (capacity <= thresholdWarning) return warningInterval
			return normalInterval
		}}
	
	}


	readonly property string icon: {
		if(!hasBattery) return 
		if (charging) return "󰂄"
		if (capacity >= 90) return "󰁹"
		if (capacity >= 70) return "󰂂"
		if (capacity >= 50) return "󰁿"
		if (capacity >= 30) return "󰁼"
		if (capacity >= thresholdDanger) return "󰁺"
		return "󰂃"
	}

	color: {
		if (charging) return colorGood
		if (capacity <= thresholdDanger) return colorDanger
		if (capacity <= thresholdWarning) return colorWarning
		return colorNormal
	}

	textFormat: Text.RichText
	text: showIcon ?  icon : capacity + "%"
	scale: showIcon ? 1.4 : 1.0

	visible: hasBattery
}


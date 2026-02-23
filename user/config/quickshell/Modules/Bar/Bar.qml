import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.Services
import "Components"

PanelWindow {
	id: bar
	WlrLayershell.layer: WlrLayer.Overlay
	visible: !Niri.isFullScreen

	// Theme
	property color colBg: "#1a1b26"
	property color colFg: "#a9b1d6"
	property color colMuted: "#444b6a"
	property color colCyan: "#0db9d7"
	property color colBlue: "#7aa2f7"
	property color colYellow: "#e0af68"
	property string fontFamily: "JetBrainsMono Nerd Font"
	property int fontSize: 16


	// System data
	property int cpuUsage: 0
	property int memUsage: 0
	property var lastCpuIdle: 0
	property var lastCpuTotal: 0

	anchors.top: true
	anchors.left: true
	anchors.bottom: true
	width: 50

	color: bar.colBg

	ColumnLayout {
		anchors.fill: parent
		anchors.topMargin: 12
		anchors.bottomMargin: 12
		anchors.leftMargin: 4



		//Workspaces {}
		Spacer {}
//		Splitter {}
		//Tray {}
		Spacer {}
		Splitter {}
		//Monitor{} //CPU, GPU, RAM, Disk
		//Volume{} //source, volume, input, volume
		//Display{} // brillantor
		Network{} //TODO eth, vpn
		Battery{}
		Splitter {}
		Clock {}
	}
}

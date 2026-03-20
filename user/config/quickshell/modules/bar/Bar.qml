import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.bar.widgets

Variants {
	model: Quickshell.screens
	delegate: Component {
		PanelWindow {
			id: bar
			WlrLayershell.layer: WlrLayer.Top

			required property var modelData
			screen: modelData

			visible: !Niri.isFullScreen || (Niri.activeScreen != screen.name)
			// Theme
			property string fontFamily: "JetBrainsMono Nerd Font"
			property int fontSize: 16


			anchors.top: true
			anchors.left: true
			anchors.bottom: true
			implicitWidth: 50

			color: Theme.cs.background

			ColumnLayout {
				anchors.fill: parent
				anchors.topMargin: 12
				anchors.bottomMargin: 12
				anchors.leftMargin: 4

				Logo {}
				Splitter {}
				//Workspaces {}
				Spacer {}
				//Splitter {}
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
	}
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.widgets
import qs.services

Variants {
	model: Quickshell.screens
	delegate: Component {
		PanelWindow {
			id: frame
			WlrLayershell.layer: WlrLayer.Overlay
			mask: Region {}

			required property var modelData
			screen: modelData

			visible: !Niri.isFullScreen || (Niri.activeScreen != screen.name)


			Frame{
				radius: 18
				color: Theme.background
				shadow_color: Theme.shadow
				shadow_strength: 3
			}

			anchors {
				top: true
				left: true
				right: true
				bottom: true
			}

			color: "transparent"


		}
	}
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Resources.Components
import qs.Services

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

			anchors {
				top: true
				left: true
				right: true
				bottom: true
			}

			color: "transparent"

			Rectangle {
				anchors.fill: parent
				color: "transparent"
				border.color: "#1a1b26"
				border.width: 4

				Rectangle {
					anchors.fill: parent
					anchors.margins: 4
					color: "transparent"
					border.color: "white"
					border.width: 2
					radius: 22
				}
			}

			Rectangle {
				id: root
				anchors.fill: parent
				anchors.margins: 4
				color: "#1a1b26"
				layer.enabled: true
				layer.effect: OpacityMask {
					maskSource: mask
				}
			}

			Rectangle {
				id: mask
				anchors.fill: parent
				layer.enabled: true
				visible: false
				radius: 22
			}

		}
	}
}

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
			id: back
			WlrLayershell.layer: WlrLayer.Background

			required property var modelData
			screen: modelData

			Image {
				id: image
				anchors.fill: parent
				fillMode: Image.PreserveAspectCrop

				source: Theme.background.image
				visible: Theme.background.image != null
			}

			color: Theme.background.color

			exclusionMode: ExclusionMode.Ignore

			anchors {
				top: true
				left: true
				right: true
				bottom: true
			}
		}

	}
}

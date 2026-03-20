import QtQuick
import QtQuick.Effects

import qs.services
import qs.widgets

Item {
	id: root
	anchors.fill: parent

	property color shadow_color: "black"
	property real shadow_strength: 2
	property int radius: 0
	property color color: "white"
	property real size: 4

	Rectangle {
		id: frame
		anchors.fill: parent

		border.color: root.color
		border.width: root.size
		color: "transparent"

		Rectangle {
			id: shadow_effect
			anchors.fill: parent
			anchors.margins: root.size
			antialiasing: true

			color: "transparent"
			border.color: root.shadow_color
			border.width: root.shadow_strength
			border.pixelAligned: false
			radius: root.radius

			layer.enabled: true
			layer.effect: MultiEffect {
				blurEnabled: true
				blurMax: 12
				blur: 1
				autoPaddingEnabled: false
			}
		}


		Rectangle {
			id: hole
			anchors.fill: parent
			anchors.margins: root.size
			color: root.color

			Rectangle {
				id: mask
				anchors.fill: parent
				antialiasing: true

				layer.enabled: true
				color: root.color
				radius: root.radius
			}

			layer.enabled: true
			layer.effect: OpacityMask {
				maskSource: mask
			}
		}
	}


}

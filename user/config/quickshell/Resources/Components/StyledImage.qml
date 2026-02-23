import QtQuick
import QtQuick.Effects

Rectangle {
	id: root
	property alias source: img.source

	Image {
		id: img
		anchors.fill: parent
		anchors.margins: root.border.width

		fillMode: Image.PreserveAspectCrop
		sourceSize.width: width
		sourceSize.height: height

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
		radius: root.radius
	}

}

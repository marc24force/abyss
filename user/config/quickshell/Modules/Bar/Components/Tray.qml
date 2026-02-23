import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

ColumnLayout {

	function getTrayIcon(id: string, icon: string): string {

		if (icon.includes("?path=")) {
			const [name, path] = icon.split("?path=");
			icon = Qt.resolvedUrl(`${path}/${name.slice(name.lastIndexOf("/") + 1)}`);
		}
		return icon;
	}

	Repeater {
		id: items
		model: SystemTray.item
		//model: ["/home/abyss/.config/theme/void/wallpaper.jpg", "/home/abyss/.config/theme/ring/wallpaper.jpg"]

		Image {
			source: getTrayIcon(modelData.id, modelData.icon)
			width: 30
			height: 30
			fillMode: Image.PreserveAspectFit
		}
	}
}


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
	id: root

	// Paths
	property string configDir: {
		var xdg = Quickshell.env("XDG_CONFIG_HOME")
		if (!xdg || xdg == "") xdg= Quickshell.env("HOME")+ "/.config"
		return xdg
	}

	readonly property string themeDir: configDir + "/abyss"
	readonly property string themeFile: themeDir + "/theme.json"

	// Theme file
	FileView {
		id: theme_file
		path: themeFile

		watchChanges: true
		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()
		
		onLoadFailed: console.warn("Failed to load theme.json, using defaults")
		onLoaded: console.info("Successfuly loaded theme file")

		JsonAdapter {
			id: json
			property JsonObject theme : JsonObject {
				property string scheme: "dark"
				property color accent: "violet"
				property JsonObject background: JsonObject {
					property string image: "%%/defaults/abyss/wallpaper.jpg"
					property color color: "black"
				}
			}
		}
	}

	// Properties
	property var cs: json.theme.scheme === "light" ? cs_light : cs_dark
	property color accent: json.theme.accent
	property var background: ({
		image: expandPath(json.theme.background.image),
		color: json.theme.background.color
	})

	// Color Schemes
	property var cs_light: ({
		background: "ivory",
		foreground: "#3f3f3f",
		inactive: "#6f6f6f",
		shadow: tint(accent, -0.8),
		success: "#8bd5a0",
		warning: "#f5a97f",
		critical: "#ed8796"
	})

	property var cs_dark: ({
		background: "#1a1b26",
		foreground: "ivory",
		inactive: "#444b6a",
		shadow: tint(accent, 0.4),
		success: "#8bd5a0",
		warning: "#f5a97f",
		critical: "#ed8796"
	})

	// IPC
	IpcHandler {
		target: "theme"

		function getColorScheme(): string { return json.theme.scheme }
		function setColorScheme(scheme: string) { json.theme.scheme = scheme }

		function getAccent(): color { return json.theme.accent }
		function setAccent(color: color) { json.theme.accent = color }

		function getBackgroundColor(): color { return json.theme.background.color }
		function setBackgroundColor(color: color) { json.theme.background.color = color }
		function getBackgroundImage(): string { return json.theme.background.image }
		function setBackgroundImage(path: string) { json.theme.background.image = path }

		function setTheme(path: string) { Quickshell.execDetached(["install", "-Dm644", expandPath(path + "/theme.json"), themeFile]) }
	}

	// Utils
	function expandPath(str, basePath) { 
		return str.split("%%").join(Quickshell.shellDir + "/assets/themes")
	}

	function tint(color, amount) {
		if (amount > 0) {
			return Qt.rgba(
				color.r + (1.0 - color.r) * amount,
				color.g + (1.0 - color.g) * amount,
				color.b + (1.0 - color.b) * amount,
				1.0
			)
		} else {
			return Qt.rgba(
				color.r * (1.0 + amount),
				color.g * (1.0 + amount),
				color.b * (1.0 + amount),
				1.0
			)
		}
	}

}

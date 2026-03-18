pragma Singleton

import QtQuick
import Quickshell

Item {
	id: style

	property var colorscheme_light: ({
		background: "ivory",
		foreground: "#3f3f3f",
		inactive: "#6f6f6f",
		shadow: "#000000",
		success: "#8bd5a0",
		warning: "#f5a97f",
		critical: "#ed8796"
	})

	property var colorscheme_dark: ({
		background: "#1a1b26",
		foreground: "ivory",
		inactive: "#444b6a",
		shadow: "#BBBBBB",
		success: "#8bd5a0",
		warning: "#f5a97f",
		critical: "#ed8796"
	})

	property var color_scheme: colorscheme_light

	readonly property color background: color_scheme.background
	readonly property color foreground: color_scheme.foreground
	readonly property color inactive: color_scheme.inactive
	readonly property color shadow: color_scheme.shadow
	readonly property color warning: color_scheme.warning
	readonly property color critical: color_scheme.critical
	readonly property color success: color_scheme.success
	property color accent: "darkred"

	function swapColorScheme() {
		if (color_scheme === colorscheme_light) color_scheme = colorscheme_dark
		else color_scheme = colorscheme_light
	}

	function setColorScheme(scheme) {
		if (scheme === "light") color_scheme = colorscheme_light
		else color_scheme = colorscheme_dark
	}

	function setAccentColor(accent_color) {
		accent = accent_color
	}

}

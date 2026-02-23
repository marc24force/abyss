pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
	id: niri

	property bool isFullScreen: false

	property var screenSize: {}

	Process {
		id: getScreenSize
		running: true
		command: ["niri", "msg", "--json", "focused-output"]
		stdout: SplitParser {
			onRead: data => {
				var json = JSON.parse(data)
				if(json) {
					niri.screenSize = [json.logical.width, json.logical.height]
				}

			}
		}
	}

	Process {
		id: checkFullScreen
		running: false
		command: ["niri", "msg", "--json", "focused-window"]
		stdout: SplitParser {
			onRead: data => {
				var json = JSON.parse(data)
				if(json) {
					var tile = json.layout.tile_size
					var offset = json.layout.window_offset_in_tile
					if(tile[0] === niri.screenSize[0] && tile[1] === niri.screenSize[1]) niri.isFullScreen = true
					else niri.isFullScreen = false
				}
				else niri.isFullScreen = false

			}
		}
	}
				
	Process {
		id: niriProc
		running: true
		command: ["niri", "msg", "--json", "event-stream"]
		stdout: SplitParser {
			onRead: data => {
				var json = JSON.parse(data)
				getScreenSize.running = true
				checkFullScreen.running = true
			}
		}
	}
}


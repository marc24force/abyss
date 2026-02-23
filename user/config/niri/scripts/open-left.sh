#!/usr/bin/env bash

get_window_id() {
	echo $(niri msg --json focused-window | jq '.id')
}

window_id=$(get_window_id)

niri msg action spawn -- $*
while [ "$window_id" == "$(get_window_id)" ]; do :; done

niri msg action move-column-left

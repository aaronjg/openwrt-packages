#!/bin/sh
exec 2>/dev/null

get_uptime() {
	local uptime=$(cat /proc/uptime)
	echo "${uptime%%.*}"
}

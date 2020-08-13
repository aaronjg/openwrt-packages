#!/bin/sh

get_uptime() {
	local uptime=$(cat /proc/uptime)
	echo "${uptime%%.*}"
}

IP4="ip -4"
IP6="ip -6"
SCRIPTNAME="$(basename "$0")"
LOG()
{
	local facility=$1; shift
	# in development, we want to show 'debug' level logs
	# when this release is out of beta, the comment in the line below
	# should be removed
	[ "$facility" = "debug" ] && return
	logger -t "$SCRIPTNAME[$$]" -p $facility "$*"
}

mwan3_get_true_iface()
{
	local family V
	_true_iface=$2
	config_get family "$2" family ipv4
	if [ "$family" = "ipv4" ]; then
		V=4
	elif [ "$family" = "ipv6" ]; then
		V=6
	fi
	ubus call "network.interface.${2}_${V}" status &>/dev/null && _true_iface="${2}_${V}"
	export "$1=$_true_iface"
}

mwan3_get_src_ip()
{
	local family _src_ip true_iface device addr_cmd default_ip IP sed_str
	true_iface=$2
	unset "$1"
	config_get family "$true_iface" family ipv4
	if [ "$family" = "ipv4" ]; then
		addr_cmd='network_get_ipaddr'
		default_ip="0.0.0.0"
		sed_str='s/ *inet \([^ \/]*\).*/\1/;T; pq'
		IP="$IP4"
	elif [ "$family" = "ipv6" ]; then
		addr_cmd='network_get_ipaddr6'
		default_ip="::"
		sed_str='s/ *inet6 \([^ \/]*\).* scope.*/\1/;T; pq'
		IP="$IP6"
	fi

	$addr_cmd _src_ip "$true_iface"
	if [ -z "$_src_ip" ]; then
		network_get_device device $true_iface
		_src_ip=$($IP address ls dev $device 2>/dev/null | sed -ne "$sed_str")
		if [ -n "$_src_ip" ]; then
			LOG warn "no src $family address found from netifd for interface '$true_iface' dev '$device' guessing $_src_ip"
		else
			_src_ip="$default_ip"
			LOG warn "no src $family address found for interface '$true_iface' dev '$device'"
		fi
	fi
	export "$1=$_src_ip"
}

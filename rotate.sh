#!/usr/bin/env bash
# RaspPass
# Copyright (C) 2015  ThisIsAreku

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

currdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
rundir=$currdir/run
logdir=$currdir/log

if [ ! -d $rundir ]; then
    mkdir $rundir
fi
if [ ! -d $logdir ]; then
    mkdir $logdir
fi

if [ -f rotation_enabled ]; then
    if [ $(cat rotation_enabled | tr -d '[[:space:]]') != '1' ]; then
        echo Rotation is disabled
        exit 0
    fi
fi

rotate_ts=$(date +"%d/%m/%Y %T");

mac_accept=$currdir/mac_accept
homepass_mac=$currdir/homepass_mac

hostapd_conf=$rundir/hostapd.conf
hostapd_pid=$rundir/hostapd.pid
hostapd_log=$logdir/hostapd.log

if [ -f $hostapd_log ]; then
    logsize=$(du -k "$hostapd_log" | cut -f 1)
    if [ $logsize -ge 500 ]; then
        echo Rotating logfile
        bcklog=$logdir/hostapd_$(date +"%Y-%m-%d_%H-%M-%s").log
        sudo mv $hostapd_log $bcklog
        sudo gzip $bcklog
    fi
fi

ssid=attwifi
prev_bssid=$(cat $rundir/prev_bssid 2> /dev/null)
bssid=$prev_bssid
while [ "$prev_bssid" = "$bssid" ]; do
    bssid=$(cat $homepass_mac | sed /^#/d | sort -R | head -n1 | tr '[:upper:]' '[:lower:]')
done
echo -e "Previous mac: \t $prev_bssid"
echo -e "Using mac: \t $bssid"
echo $bssid > $rundir/prev_bssid

cat $currdir/hostapd.conf.model | sed s/%ssid%/$ssid/ |	sed s/%bssid%/$bssid/ |	sed s#%accept_mac_file%#$mac_accept# > $hostapd_conf
if [ -e $hostapd_pid ]; then
    echo hostapd is running, stopping
    sudo kill -TERM $(cat $hostapd_pid)
fi

sudo ifconfig wlan0 192.168.23.254
sudo hostapd -B -f $hostapd_log -t -P $hostapd_pid $hostapd_conf
sudo ifconfig wlan0 192.168.23.254

echo "MASQUERADE rule"
if sudo iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE; then
	echo -e "\tSkipped"
else
	echo -e "\tAdded"
	sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
fi

echo "ACCEPT wlan0 -> eth0"
if sudo iptables -C FORWARD -i wlan0 -o eth0 -j ACCEPT; then
	echo -e "\tSkipped"
else
	echo -e "\tAdded"
	sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
fi

echo "ACCEPT eth0 -> wlan0"
if sudo iptables -C FORWARD -i eth0 -o wlan0 -j ACCEPT; then
	echo -e "\tSkipped"
else
	echo -e "\tAdded"
	sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
fi

sudo service dnsmasq start


echo $rotate_ts > $rundir/last_rotation

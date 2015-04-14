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

mac_accept=$currdir/mac_accept
homepass_mac=$currdir/homepass_mac

hostapd_conf=$rundir/hostapd.conf
hostapd_pid=$rundir/hostapd.pid
hostapd_log=$logdir/hostapd.log

ssid=attwifi
prev_bssid=$(cat $rundir/prev_bssid 2> /dev/null)
bssid=$prev_bssid
while [ "$prev_bssid" = "$bssid" ]; do
    bssid=$(cat $homepass_mac | sed /^#/d | sort -R | head -n1 | tr '[:upper:]' '[:lower:]')
done
echo Previous mac was: $prev_bssid
echo Using mac: $bssid
echo $bssid > $rundir/prev_bssid

cat $currdir/hostapd.conf.model | sed s/%ssid%/$ssid/ |	sed s/%bssid%/$bssid/ |	sed s#%accept_mac_file%#$mac_accept# > $hostapd_conf
if [ -e $hostapd_pid ]; then
    echo hostapd is running, stopping
    sudo kill -SIGKILL $(cat $hostapd_pid)
fi

sudo hostapd -B -P $hostapd_pid $hostapd_conf

date +"%d/%m/%Y %T" > $rundir/last_rotation

# RaspPass
## HomePass for Raspberry Pi

### Requirements
1. sudo apt-get install hostapd bridge-utils
2. Tested with RT5370
3. Bridge interface configured in /etc/network/interfaces
4. Execute `rotate.sh` each 10min to rotate mac addresses

### /etc/network/interfaces
Your file should contain definition for wlan0 and br0
```
allow-hotplug wlan0
iface wlan0 inet manual

auto br0
iface br0 inet dhcp
```

### Mac addresses list
Mac addresses are located in `homepass_mac`. List is from [this google spreadsheet](https://docs.google.com/spreadsheet/ccc?key=0AvvH5W4E2lIwdEFCUkxrM085ZGp0UkZlenp6SkJablE#gid=0)


# WireGuard Auto-Wake Solution

## Overview
This project implements an auto-wake solution for routers that support specific commands. When an external network initiates a WireGuard connection request (default port 51820), the router detects the traffic and sends a WOL (Wake-on-LAN) packet to wake the target device (e.g., an Unraid server).

## Requirements
- **Router**: Must support SSH and the following commands:
  - `netstat-nat`: Used to detect WireGuard traffic.
  - `ether-wake`: Used to send WOL packets.
  - `logger`: Used to log messages (optional; if unavailable, the script needs modification).
  - `cru`: Used to set up scheduled tasks.
- **Target Device**: A device that supports WOL (e.g., an Unraid server).
- **WireGuard Port**: Default is 51820 (can be modified as needed).

## File Structure
- `wol.sh`: Script to send WOL packets.
- `check-wireguard.sh`: Script to detect WireGuard traffic and trigger WOL.
- `README.md`: Documentation file.

## Setup Instructions

### 1. Enable SSH and Connect to the Router
1. Access the router's web interface and enable SSH (typically under **Administration > System**).
2. Connect to the router using an SSH client:
    ```sh
    ssh username@routerIP

### 2. Configure WireGuard Port Forwarding
In the router's web interface, set up NAT forwarding to forward external port 51820 (UDP) to the target device (e.g., 192.168.1.123:51820).

### 3. Verify Required Commands
Ensure the router supports the following commands:
```sh
which netstat-nat
which ether-wake
which logger
which cru
```
If any command is missing, consider replacing the firmware (e.g., with OpenWrt) or using another device.

### 4. Copy Scripts to the Router
1. Copy wol.sh and check-wireguard.sh to the /jffs/scripts/ directory:
  ```sh
  echo -e '#!/bin/sh\nMAC="[your mac address]"\n/usr/bin/ether-wake -b -i br0 $MAC' > /jffs/scripts/wol.sh
  echo -e '#!/bin/sh\n# Check for WireGuard traffic in netstat-nat\nif netstat-nat | grep -q "51820"; then\n    /jffs/scripts/wol.sh\n    logger -t "WireGuard-WOL" "Traffic detected, sending WOL packet"\nfi' > /jffs/scripts/check-wireguard.sh
  ```
- Replace [your mac address] with the actual MAC address (e.g., 00:11:22:33:44:55).
- If the network interface is not br0, adjust the -i br0 in wol.sh (e.g., to -i eth0).
2. Set script permissions:
  ```sh
  chmod +x /jffs/scripts/wol.sh
  chmod +x /jffs/scripts/check-wireguard.sh
  ```

### 5. Set Up a Scheduled Task
Use cru to schedule a task that checks for WireGuard traffic every minute:
```sh
cru a CheckWireGuard "* * * * * /jffs/scripts/check-wireguard.sh"
```
Verify the scheduled task:
```sh
cru l
```

### 6. Test Auto-Wake
1. Put the target device into sleep mode.
2. Connect to WireGuard from an external network.
3. Wait for one minute and check if the target device wakes up.
4. Check the logs:
   ```sh
   cat /jffs/syslog.log | grep "WireGuard-WOL"
   ``` 

## Limitations and Improvements
- **Latency**: The scheduled task checks every minute, which may introduce up to 60 seconds of delay.
- **Firmware Limitations**: If the router does not support `netstat-nat` or other required commands, consider:
  - Using another device (e.g., a Raspberry Pi) to monitor traffic.
  - Flashing OpenWrt for full traffic monitoring tools (e.g., `tcpdump`).
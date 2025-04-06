# WireGuard 自動喚醒方案

## 概述
此專案實現了一個自動喚醒方案，適用於支援特定指令的路由器。當外部網絡發起 WireGuard 連線請求（預設端口 51820）時，路由器會檢測流量並發送 WOL（Wake-on-LAN）封包喚醒目標設備（例如 Unraid 伺服器）。

## 環境需求
- **路由器**：需支援 SSH 並具備以下指令：
  - `netstat-nat`：用於檢測 WireGuard 流量。
  - `ether-wake`：用於發送 WOL 封包。
  - `logger`：用於記錄日誌（可選，若無則需修改腳本）。
  - `cru`：用於設置定時任務。
- **目標設備**：支援 WOL 的設備（例如 Unraid 伺服器）。
- **WireGuard 端口**：預設為 51820（可根據實際情況修改）。

## 檔案結構
- `wol.sh`：發送 WOL 封包的腳本。
- `check-wireguard.sh`：檢測 WireGuard 流量並觸發 WOL 的腳本。
- `README.md`：說明文件。

## 建置方式

### 1. 啟用 SSH 並連接到路由器
1. 進入路由器 Web 介面，啟用 SSH 功能（通常在 **Administration > System** 中）。
2. 使用 SSH 客戶端連接到路由器：
    ```ssh
    ssh username@routerIP
    ```

### 2. 設置 WireGuard 端口轉發
在路由器 Web 介面中，設置 NAT 轉發，將外部 51820 端口（UDP）轉發到目標設備（例如 `192.168.1.123:51820`）。

### 3. 確認必要指令可用
檢查路由器是否支援以下指令：
```sh
which netstat-nat
which ether-wake
which logger
which cru
```
如果缺少任一指令，需考慮更換固件（例如刷 OpenWrt）或使用其他設備。

### 4. 複製腳本到路由器
1. 將 `wol.sh` 和 `check-wireguard.sh` 複製到 `/jffs/scripts/` 目錄：
    ```sh
    echo -e '#!/bin/sh\nMAC="[your mac address]"\n/usr/bin/ether-wake -b -i br0 $MAC' > /jffs/scripts/wol.sh
    echo -e '#!/bin/sh\n# 檢查 netstat-nat 中是否有 WireGuard 流量\nif netstat-nat | grep -q "51820"; then\n    /jffs/scripts/wol.sh\n    logger -t "WireGuard-WOL" "檢測到流量，發送 WOL 封包"\nfi' > /jffs/scripts/check-wireguard.sh
    ```
    - 將 `[your mac address]` 替換為實際 MAC 地址（例如 `00:11:22:33:44:55`）。
    - 如果網絡接口不是 `br0`，需調整 `wol.sh` 中的 `-i br0`（例如 `-i eth0`）。
2. 設置腳本權限：
    ```sh
    chmod +x /jffs/scripts/wol.sh
    chmod +x /jffs/scripts/check-wireguard.sh
    ```

### 5. 設置定時任務
1. 使用 `cru` 設置定時任務，每分鐘檢查 WireGuard 流量：
    ```sh
    cru a CheckWireGuard "* * * * * /jffs/scripts/check-wireguard.sh"
    ```
2. 檢查定時任務：
    ```sh
    cru l
    ```


### 6. 測試自動喚醒
1. 讓目標設備進入休眠
2. 從外部網絡連接到 WireGuard。
3. 等待一分鐘，檢查目標設備是否被喚醒。
4. 檢查日誌：
    ```sh
    cat /jffs/syslog.log | grep "WireGuard-WOL"
    ```
- **調整檢查頻率**：如果需要更快響應，可修改定時任務（例如每 30 秒檢查一次）：
    ```sh
    cru a CheckWireGuard "*/30 * * * * * /jffs/scripts/check-wireguard.sh"
    ```


## 限制與改進
- **延遲**：定時任務每分鐘檢查一次，可能有最多 60 秒的延遲。
- **固件限制**：如果路由器不支援 `netstat-nat` 或其他必要指令，可考慮：
- 使用其他設備（例如 Raspberry Pi）監控流量。
- 刷 OpenWrt，提供完整的流量監控工具（例如 `tcpdump`）。
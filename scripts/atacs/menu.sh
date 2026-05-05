#!/bin/bash

echo "Selecciona atac:"
echo "1) Port Scanning"
echo "2) SQL Injection"
echo "3) Brute Force"

read opcio

case $opcio in
    1) ./scanning.sh ;;
    2) ./sqli.sh ;;
    3) ./bruteforce.sh ;;
    *) echo "Opció no vàlida" ;;
esac
#!/bin/bash

LEVEL="$1"

if [[ "$LEVEL" != "apagat" && "$LEVEL" != "basic" && "$LEVEL" != "avançat" ]]; then
  echo "Ús: ./scripts/set-defense-level.sh [apagat|basic|avançat]"
  exit 1
fi

cp "./configs/nginx/$LEVEL/default.conf" "./configs/nginx/active.conf"

echo "DEFENSE_LEVEL=$LEVEL" > .env

docker compose restart reverse-proxy

echo "Nivell de defensa canviat a: $LEVEL"
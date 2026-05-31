#!/bin/bash

LEVEL="$1"

BASE_DIR="/project"

if [[ "$LEVEL" != "apagat" && "$LEVEL" != "basic" && "$LEVEL" != "advanced" ]]; then
  echo "Ús: ./scripts/nivell-defensa.sh [apagat|basic|advanced]"
  exit 1
fi

rm -f "$BASE_DIR/configs/nginx/active.conf"

cp \
"$BASE_DIR/configs/nginx/$LEVEL/default.conf" \
"$BASE_DIR/configs/nginx/active.conf"

echo "DEFENSE_LEVEL=$LEVEL" > "$BASE_DIR/.env"

echo "Nivell de defensa canviat a: $LEVEL"
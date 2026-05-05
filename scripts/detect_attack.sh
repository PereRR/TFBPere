#!/bin/sh

LOG_FILE="/var/log/project/nginx/access.log"
OUTPUT_FILE="/var/log/project/detection.log"
STATE_DIR="/tmp/detector-state"
LAST_LINE_FILE="$STATE_DIR/last_line"

mkdir -p "$STATE_DIR"

can_alert() {
    attack_type="$1"
    ip="$2"
    cooldown="$3"

    state_file="$STATE_DIR/${attack_type}_${ip}"
    now=$(date +%s)

    if [ ! -f "$state_file" ]; then
        echo "$now" > "$state_file"
        return 0
    fi

    last=$(cat "$state_file")
    diff=$((now - last))

    if [ "$diff" -ge "$cooldown" ]; then
        echo "$now" > "$state_file"
        return 0
    fi

    return 1
}

[ -f "$LAST_LINE_FILE" ] || echo "0" > "$LAST_LINE_FILE"

while true; do
    total_lines=$(wc -l < "$LOG_FILE")
    last_line=$(cat "$LAST_LINE_FILE")

    if [ "$total_lines" -lt "$last_line" ]; then
        last_line=0
    fi

    new_lines=$((total_lines - last_line))

    if [ "$new_lines" -gt 0 ]; then
        TMP_FILE="$STATE_DIR/new_lines.log"
        tail -n "$new_lines" "$LOG_FILE" > "$TMP_FILE"

        # SQL Injection
        grep -Ei "union|select|--|%27|%22| or " "$TMP_FILE" | while read line; do
            ip=$(echo "$line" | awk '{print $1}')
            if can_alert "sqli" "$ip" 10; then
                echo "$(date) [ALERTA] Possible SQL Injection des de $ip" >> "$OUTPUT_FILE"
            fi
        done

        # Brute force login
        grep "POST /login" "$TMP_FILE" | awk '{print $1}' | sort | uniq -c | while read count ip; do
            if [ "$count" -gt 10 ]; then
                if can_alert "bruteforce" "$ip" 20; then
                    echo "$(date) [ALERTA] Possible Brute Force Login des de $ip ($count intents)" >> "$OUTPUT_FILE"
                fi
            fi
        done

        # Port scanning / moltes peticions en poc temps
        awk '{print $1}' "$TMP_FILE" | sort | uniq -c | while read count ip; do
            if [ "$count" -gt 30 ]; then
                if can_alert "portscan" "$ip" 20; then
                    echo "$(date) [ALERTA] Possible Port Scanning des de $ip ($count peticions)" >> "$OUTPUT_FILE"
                fi
            fi
        done

        echo "$total_lines" > "$LAST_LINE_FILE"
    fi

    sleep 5
done
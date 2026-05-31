#!/bin/sh

ACCESS_LOG="/logs/nginx/access.log"
OUTPUT_LOG="/logs/detection.log"
JSON_OUTPUT="/logs/detection.json"

TMP_FILE="/tmp/access.tmp"

ENV_FILE="/project/.env"

STATE_DIR="/tmp/detector-state"
LAST_LINE_FILE="$STATE_DIR/last_line"

mkdir -p "$STATE_DIR"

[ -f "$LAST_LINE_FILE" ] || echo "0" > "$LAST_LINE_FILE"

touch "$OUTPUT_LOG"
touch "$JSON_OUTPUT"

echo "[Detector] Iniciant detector d'atacs..."

write_alert() {
    echo "$(date) [ALERTA] $1" >> "$OUTPUT_LOG"
}

write_json_alert() {
    attack_type="$1"
    ip="$2"
    description="$3"
    action="$4"
    risk="$5"
    defense_status="$6"
    attack_result="$7"

    echo "{\"timestamp\":\"$(date -Iseconds)\",\"security_level\":\"$SECURITY_LEVEL\",\"attack_type\":\"$attack_type\",\"source_ip\":\"$ip\",\"description\":\"$description\",\"script_action\":\"$action\",\"risk\":\"$risk\",\"defense_status\":\"$defense_status\",\"attack_result\":\"$attack_result\",\"detected\":true}" >> "$JSON_OUTPUT"
}

while true; do

    SECURITY_LEVEL=$(grep DEFENSE_LEVEL "$ENV_FILE" | cut -d '=' -f2)

    total_lines=$(wc -l < "$ACCESS_LOG")
    last_line=$(cat "$LAST_LINE_FILE")

    if [ "$total_lines" -lt "$last_line" ]; then
        last_line=0
    fi

    new_lines=$((total_lines - last_line))

    if [ "$new_lines" -gt 0 ]; then
        tail -n "$new_lines" "$ACCESS_LOG" > "$TMP_FILE"
        echo "$total_lines" > "$LAST_LINE_FILE"
    else
        sleep 5
        continue
    fi

    # ==========================================================
    # CONFIGURACIÓ SEGONS NIVELL
    # ==========================================================

    if [ "$SECURITY_LEVEL" = "apagat" ]; then

        SQL_PATTERN="union|select|--|%27|%22| or "
        BRUTE_THRESHOLD=50
        PORTSCAN_THRESHOLD=200

    elif [ "$SECURITY_LEVEL" = "advanced" ]; then

        SQL_PATTERN="union|select|--|%27|%22| or |sleep|benchmark|information_schema"
        BRUTE_THRESHOLD=5
        PORTSCAN_THRESHOLD=15

    else

        SQL_PATTERN="union|select|--|%27|%22| or "
        BRUTE_THRESHOLD=10
        PORTSCAN_THRESHOLD=30

    fi

    # ==========================================================
    # SQL INJECTION
    # ==========================================================

    sql_attacks=$(grep -Ei "$SQL_PATTERN" "$TMP_FILE")

    if [ ! -z "$sql_attacks" ]; then

        ip=$(echo "$sql_attacks" | head -n 1 | awk '{print $1}')

        if [ "$SECURITY_LEVEL" = "advanced" ]; then

            DESCRIPTION="S'ha detectat un payload SQL amb patrons OR/SELECT compatibles amb tècniques de bypass d'autenticació i extracció de dades."
            ACTION="El script ha intentat modificar la consulta SQL original injectant condicions sempre certes per accedir a informació restringida."
            RISK="Possible compromís complet de la base de dades i exposició de dades sensibles."
            DEFENSE_STATUS="Patró SQL identificat pel sistema de defensa avançat. La petició sospitosa ha estat analitzada amb regles més estrictes."
            ATTACK_RESULT="L'atac ha estat detectat i potencialment bloquejat abans que pugui comprometre la base de dades."

        elif [ "$SECURITY_LEVEL" = "apagat" ]; then

            DESCRIPTION="S'ha detectat activitat sospitosa relacionada amb consultes web."
            ACTION="El sistema ha identificat una petició potencialment maliciosa, però amb informació limitada perquè el nivell de defensa està apagat."
            RISK="El sistema podria no detectar correctament atacs SQL Injection més sofisticats."
            DEFENSE_STATUS="Sistema vulnerable. No s'han aplicat contramesures específiques contra SQL Injection."
            ATTACK_RESULT="L'atac podria haver arribat a l'aplicació sense restriccions significatives."

        else

            DESCRIPTION="L'atac intenta manipular consultes SQL enviant caràcters especials al servidor web."
            ACTION="El script ha enviat payloads SQL maliciosos per intentar alterar les consultes originals i obtenir accés no autoritzat a informació de la base de dades."
            RISK="Possible filtració o manipulació de dades sensibles."
            DEFENSE_STATUS="S'han aplicat mecanismes bàsics de detecció sobre patrons típics de SQL Injection."
            ATTACK_RESULT="L'atac ha estat detectat, però podria haver arribat parcialment a l'aplicació."

        fi

        write_alert "Possible SQL Injection des de $ip"

        write_json_alert \
            "SQL Injection" \
            "$ip" \
            "$DESCRIPTION" \
            "$ACTION" \
            "$RISK" \
            "$DEFENSE_STATUS" \
            "$ATTACK_RESULT"

    fi

    # ==========================================================
    # BRUTE FORCE
    # ==========================================================

    brute_ips=$(grep "POST /login" "$TMP_FILE" | awk '{print $1}' | sort | uniq)

    for ip in $brute_ips; do

        count=$(grep "POST /login" "$TMP_FILE" | grep "$ip" | wc -l)

        if [ "$count" -gt "$BRUTE_THRESHOLD" ]; then

            if [ "$SECURITY_LEVEL" = "advanced" ]; then

                DESCRIPTION="S'han detectat múltiples intents d'autenticació consecutius ($count) compatibles amb tècniques automatitzades de força bruta."
                ACTION="El script ha intentat descobrir credencials vàlides mitjançant múltiples peticions POST automatitzades contra el formulari de login."
                RISK="Possible compromís de comptes d'usuari i escalada d'accés."
                DEFENSE_STATUS="El sistema avançat ha identificat un volum anòmal d'intents d'accés i aplica una detecció més sensible sobre el formulari de login."
                ATTACK_RESULT="L'atac ha estat detectat i mitigat abans que pugui mantenir intents massius de credencials."

            elif [ "$SECURITY_LEVEL" = "apagat" ]; then

                DESCRIPTION="S'ha detectat activitat sospitosa relacionada amb intents d'accés."
                ACTION="El sistema ha observat múltiples peticions d'autenticació, però disposa de capacitats limitades de detecció perquè el nivell de defensa està apagat."
                RISK="El sistema podria no identificar correctament intents avançats de compromís de comptes."
                DEFENSE_STATUS="No existeixen limitacions específiques d'autenticació ni protecció activa contra intents repetits."
                ATTACK_RESULT="Els intents podrien continuar fins a trobar credencials vàlides."

            else

                DESCRIPTION="L'atac intenta accedir al sistema provant múltiples credencials consecutivament."
                ACTION="El script ha realitzat múltiples intents consecutius ($count) d'inici de sessió contra el formulari /login amb l'objectiu d'endevinar credencials vàlides."
                RISK="Possible compromís de comptes d'usuari."
                DEFENSE_STATUS="S'han aplicat controls bàsics de trànsit per identificar intents repetits d'autenticació."
                ATTACK_RESULT="L'atac ha estat detectat i part dels intents han estat limitats."

            fi

            write_alert "Possible Brute Force Login des de $ip ($count intents)"

            write_json_alert \
                "Brute Force" \
                "$ip" \
                "$DESCRIPTION" \
                "$ACTION" \
                "$RISK" \
                "$DEFENSE_STATUS" \
                "$ATTACK_RESULT"

        fi
    done

    # ==========================================================
    # PORT SCANNING
    # ==========================================================

    scan_ips=$(grep -v "POST /login" "$TMP_FILE" | awk '{print $1}' | sort | uniq)

    for ip in $scan_ips; do

        count=$(grep "$ip" "$TMP_FILE" | grep -v "POST /login" | wc -l)

        if [ "$count" -gt "$PORTSCAN_THRESHOLD" ]; then

            if [ "$SECURITY_LEVEL" = "advanced" ]; then

                DESCRIPTION="S'ha detectat un patró de reconeixement de xarxa compatible amb tècniques automatitzades de descoberta de serveis."
                ACTION="El script ha generat múltiples connexions ràpides ($count) contra diferents serveis per identificar ports oberts i possibles punts vulnerables."
                RISK="Possible fase preparatòria abans d'un atac dirigit contra serveis exposats."
                DEFENSE_STATUS="El sistema avançat ha identificat el patró de reconeixement i aplica una detecció més estricta sobre el volum de connexions."
                ATTACK_RESULT="L'activitat sospitosa ha estat monitoritzada i mitigada abans que pugui obtenir informació útil de la infraestructura."

            elif [ "$SECURITY_LEVEL" = "apagat" ]; then

                DESCRIPTION="S'ha detectat activitat sospitosa relacionada amb connexions de xarxa."
                ACTION="El sistema ha identificat un volum elevat de connexions ($count), però amb capacitats limitades d'anàlisi perquè el nivell de defensa està apagat."
                RISK="El sistema podria no detectar correctament fases de reconeixement avançades."
                DEFENSE_STATUS="No hi ha restriccions efectives sobre les connexions entrants ni protecció activa contra reconeixement."
                ATTACK_RESULT="L'atacant podria identificar serveis exposats i preparar un atac posterior."

            else

                DESCRIPTION="L'atac intenta identificar serveis i recursos actius al servidor."
                ACTION="El script ha enviat múltiples connexions ràpides ($count) contra diferents serveis del servidor per identificar quins ports i aplicacions estan actius abans d'un possible atac posterior."
                RISK="Fase de reconeixement prèvia a possibles atacs més avançats."
                DEFENSE_STATUS="S'han aplicat limitacions bàsiques de connexió per reduir l'activitat de reconeixement."
                ATTACK_RESULT="L'activitat de reconeixement ha estat detectada i parcialment reduïda."

            fi

            write_alert "Possible Port Scanning des de $ip ($count peticions)"

            write_json_alert \
                "Port Scanning" \
                "$ip" \
                "$DESCRIPTION" \
                "$ACTION" \
                "$RISK" \
                "$DEFENSE_STATUS" \
                "$ATTACK_RESULT"

        fi
    done

    sleep 5

done
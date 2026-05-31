from flask import Flask, render_template_string, redirect
import subprocess

app = Flask(__name__)

ATTACKS = {
    "scanning": {
        "name": "Port Scanning",
        "script": "/atacs/scanning.sh",
        "description": "Simula moltes connexions cap al servidor per representar una fase de reconeixement."
    },
    "sqli": {
        "name": "SQL Injection",
        "script": "/atacs/sqli.sh",
        "description": "Envia una petició amb patrons típics d'injecció SQL per comprovar si el sistema ho detecta."
    },
    "bruteforce": {
        "name": "Brute Force Login",
        "script": "/atacs/bruteforce.sh",
        "description": "Simula múltiples intents d'accés contra el formulari de login."
    }
}

# ==========================================================
# LLEGIR NIVELL ACTUAL
# ==========================================================

def get_defense_level():

    with open("/project/.env", "r") as f:

        for line in f:

            if line.startswith("DEFENSE_LEVEL="):
                return line.strip().split("=")[1]

    return "basic"

HTML = """
<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="UTF-8">
    <title>CyberLab - Menú d'atacs</title>

    <style>

        body {
            font-family: Arial, sans-serif;
            background: #0f172a;
            color: white;
            margin: 0;
            padding: 40px;
        }

        h1 {
            text-align: center;
            color: #60a5fa;
            margin-bottom: 10px;
        }

        .subtitle {
            text-align: center;
            color: #cbd5e1;
            margin-bottom: 40px;
        }

        .container {
            max-width: 1000px;
            margin: auto;
        }

        .card {
            background: #1e293b;
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 24px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.4);
            transition: transform 0.2s ease;
        }

        .card:hover {
            transform: scale(1.01);
        }

        .card form {
            margin-bottom: 10px;
        }

        .card button {
            width: 100%;
        }

        h2 {
            margin-top: 0;
            color: #93c5fd;
        }

        p {
            color: #cbd5e1;
        }

        .current-level {
            margin-bottom: 20px;
            font-size: 16px;
            color: #cbd5e1;
        }

        button {
            background: #2563eb;
            border: none;
            color: white;
            padding: 14px 20px;
            border-radius: 10px;
            cursor: pointer;
            font-size: 16px;
            transition: background 0.2s ease;
        }

        button:hover {
            background: #1d4ed8;
        }

        button:disabled {
            background: #475569;
            cursor: wait;
        }

        .loading {
            display: none;
            margin-top: 15px;
            color: #fbbf24;
            font-weight: bold;
        }

        .spinner {
            border: 4px solid #334155;
            border-top: 4px solid #fbbf24;
            border-radius: 50%;
            width: 18px;
            height: 18px;
            display: inline-block;
            animation: spin 1s linear infinite;
            margin-right: 10px;
            vertical-align: middle;
        }

        @keyframes spin {
            100% {
                transform: rotate(360deg);
            }
        }

        .output {
            background: #111827;
            border-left: 5px solid #22c55e;
            padding: 20px;
            border-radius: 10px;
            margin-top: 30px;
            white-space: pre-wrap;
            color: #e5e7eb;
        }

        .grafana {
            margin-top: 40px;
            background: #052e16;
            border-radius: 12px;
            padding: 20px;
        }

        a {
            color: #93c5fd;
        }

    </style>

    <script>

        function startAttack(buttonId, loadingId) {

            const button = document.getElementById(buttonId);
            const loading = document.getElementById(loadingId);

            button.disabled = true;
            button.innerText = "Executant...";
            loading.style.display = "block";
        }

    </script>

</head>

<body>

<div class="container">

    <h1>🛡️ CyberLab</h1>

    <div class="subtitle">
        Plataforma docent per a simulació i detecció de ciberatacs
    </div>

    <!-- ====================================================== -->
    <!-- NIVELL DEFENSA -->
    <!-- ====================================================== -->

    <div class="card">

        <h2>🛡️ Nivell de defensa</h2>

        <p class="current-level">
            🛡️ Nivell actual:
            <strong>{{ defense_level.upper() }}</strong>
        </p>

        <form action="/defense/apagat" method="post">
            <button class="danger">🔴 Apagat</button>
        </form>

        <form action="/defense/basic" method="post">
            <button class="warning">🟡 Basic</button>
        </form>

        <form action="/defense/advanced" method="post">
            <button class="success">🟢 Avançat</button>
        </form>

    </div>

    <!-- ====================================================== -->
    <!-- ATACS -->
    <!-- ====================================================== -->

    {% for key, attack in attacks.items() %}

    <div class="card">

        <h2>{{ attack.name }}</h2>

        <p>{{ attack.description }}</p>

        <form method="post"
              action="/run/{{ key }}"
              onsubmit="startAttack('btn-{{ key }}', 'load-{{ key }}')">

            <button id="btn-{{ key }}" type="submit">
                Executar {{ attack.name }}
            </button>

            <div class="loading" id="load-{{ key }}">
                <span class="spinner"></span>
                Executant atac...
            </div>

        </form>

    </div>

    {% endfor %}

    <!-- ====================================================== -->
    <!-- GRAFANA -->
    <!-- ====================================================== -->

    <div class="grafana">

        <h3>📊 Monitorització</h3>

        <p>
            Observa en temps real els atacs detectats al dashboard de Grafana.
        </p>

        <a href="http://localhost:3000" target="_blank">
            Obrir Grafana
        </a>

    </div>

    <!-- ====================================================== -->
    <!-- OUTPUT -->
    <!-- ====================================================== -->

    {% if output %}

    <div class="output">

        <strong>✔ Resultat:</strong>

        <br><br>

        {{ output }}

    </div>

    {% endif %}

</div>

</body>
</html>
"""

# ==========================================================
# HOME
# ==========================================================

@app.route("/", methods=["GET"])
def index():

    return render_template_string(
        HTML,
        attacks=ATTACKS,
        output=None,
        defense_level=get_defense_level()
    )

# ==========================================================
# EXECUTAR ATACS
# ==========================================================

@app.route("/run/<attack_key>", methods=["POST"])
def run_attack(attack_key):

    if attack_key not in ATTACKS:
        return render_template_string(
            HTML,
            attacks=ATTACKS,
            output="Atac no vàlid",
            defense_level=get_defense_level()
        )

    script = ATTACKS[attack_key]["script"]

    try:

        result = subprocess.run(
            ["bash", script],
            capture_output=True,
            text=True,
            timeout=30
        )

        output = f"Atac executat: {ATTACKS[attack_key]['name']}\\n\\n"
        output += result.stdout

        if result.stderr:
            output += "\\nErrors:\\n" + result.stderr

    except subprocess.TimeoutExpired:

        output = "L'atac ha superat el temps màxim d'execució."

    return render_template_string(
        HTML,
        attacks=ATTACKS,
        output=output,
        defense_level=get_defense_level()
    )

# ==========================================================
# CANVIAR DEFENSA
# ==========================================================

@app.route("/defense/<level>", methods=["POST"])
def defense(level):

    valid_levels = ["apagat", "basic", "advanced"]

    if level not in valid_levels:
        return "Nivell invàlid"

    result = subprocess.run(
        ["/bin/bash", "/project/scripts/nivell-defensa.sh", level],
        capture_output=True,
        text=True
    )

    return redirect("/")

# ==========================================================
# MAIN
# ==========================================================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
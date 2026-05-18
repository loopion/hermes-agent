#!/bin/bash
set -e

HERMES_HOME="${HERMES_HOME:-/home/hermes/.hermes}"

# ── Directories ─────────────────────────────────────────────────────────────
mkdir -p "$HERMES_HOME"

# ── .env — toujours regénéré depuis les variables Coolify ───────────────────
# Cela garantit que la vraie clé est toujours injectée au démarrage.
cat > "$HERMES_HOME/.env" << EOF
OPENAI_API_KEY=${OPENAI_API_KEY:?Variable OPENAI_API_KEY manquante dans Coolify}
EOF

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    echo "TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}" >> "$HERMES_HOME/.env"
fi

# ── config.yaml — écrit seulement au premier démarrage ──────────────────────
# Les modifications faites par l'agent (skills, memory tuning) sont préservées
# dans le volume entre les redémarrages.
if [ ! -f "$HERMES_HOME/config.yaml" ]; then
    echo "[hermes] Premier démarrage — écriture de config.yaml"
    cat > "$HERMES_HOME/config.yaml" << EOF
model:
  default: "${MODEL_DEFAULT:-free-dev}"
  provider: "custom"
  base_url: "${CUSTOM_BASE_URL:?Variable CUSTOM_BASE_URL manquante dans Coolify}"

terminal:
  backend: local
  timeout: 180

timezone: "Europe/Paris"

memory:
  memory_enabled: true
  user_profile_enabled: true

display:
  language: fr
  tool_progress: all
  streaming: false

compression:
  enabled: true
  threshold: 0.50

approvals:
  mode: smart
EOF
    echo "[hermes] config.yaml créé."
else
    echo "[hermes] config.yaml existant conservé (volume persistant)."
fi

# ── Telegram gateway — config au premier démarrage si token fourni ───────────
GATEWAY_CONFIG="$HERMES_HOME/sessions/gateway.json"
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ ! -f "$GATEWAY_CONFIG" ]; then
    echo "[hermes] Configuration automatique du gateway Telegram..."
    mkdir -p "$HERMES_HOME/sessions"
    hermes config set telegram.bot_token "${TELEGRAM_BOT_TOKEN}" 2>/dev/null || true
fi

# ── Commande ─────────────────────────────────────────────────────────────────
case "${1}" in
    gateway)
        echo "[hermes] Démarrage du gateway..."
        exec hermes gateway run
        ;;
    setup)
        echo "[hermes] Mode setup interactif..."
        exec hermes setup
        ;;
    chat)
        echo "[hermes] Mode chat CLI..."
        exec hermes chat
        ;;
    *)
        exec "$@"
        ;;
esac
